// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import AVFoundation
import Shared

struct WalletScannerView: UIViewControllerRepresentable {
  
  enum ScanError: Error {
    case badInput, badOutput, permissionDenied, others
  }
  
  var completion: (Result<String, ScanError>) -> Void
  
  init(completion: @escaping (Result<String, ScanError>) -> Void) {
    self.completion = completion
  }
  
  func makeCoordinator() -> WalletScannerCoordinator {
    return WalletScannerCoordinator(parent: self)
  }
  
  func makeUIViewController(context: Context) -> some UIViewController {
    let viewController = WalletScannerViewController()
    viewController.delegate = context.coordinator
    return viewController
  }
  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
  }
}

#if targetEnvironment(simulator)
class WalletScannerViewController: UIViewController {
  var delegate: WalletScannerCoordinator?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let label = UILabel().then {
      $0.text = "Click here to simulate scan"
      $0.textColor = .white
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    
    view.backgroundColor = .black
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
    ])
    
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClick))
    view.addGestureRecognizer(tapGesture)
  }
  
  @objc
  private func onClick() {
    delegate?.found(code: "0xasdkgasd")
  }
}
#else
class WalletScannerViewController: UIViewController {
  
  private lazy var captureSession: AVCaptureSession = {
    let session = AVCaptureSession()
    session.sessionPreset = AVCaptureSession.Preset.high
    return session
  }()
  let captureDevice = AVCaptureDevice.default(for: .video)
  
  var previewLayer: AVCaptureVideoPreviewLayer?
  var delegate: WalletScannerCoordinator?
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    view.backgroundColor = .black
    
    let getAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    if getAuthorizationStatus != .denied {
      setupCamera()
    } else {
      delegate?.didFail(reason: .permissionDenied)
    }
    
    let imageView = UIImageView().then {
      $0.image = UIImage(named: "camera-overlay")
      $0.contentMode = .center
      $0.translatesAutoresizingMaskIntoConstraints = false
    }
    view.addSubview(imageView)
    NSLayoutConstraint.activate([
      imageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      imageView.widthAnchor.constraint(equalToConstant: 200),
      imageView.heightAnchor.constraint(equalToConstant: 200),
    ])
  }
  
  override func viewDidLayoutSubviews() {
    previewLayer?.frame = view.layer.bounds
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    if !captureSession.isRunning {
      captureSession.startRunning()
    }
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    
    captureSession.stopRunning()
  }
  
  private func setupCamera() {
    guard let captureDevice = captureDevice else {
      delegate?.didFail(reason: .others)
      return
    }

    guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
      delegate?.didFail(reason: .others)
      return
    }
    captureSession.addInput(videoInput)
    
    let metadataOutput = AVCaptureMetadataOutput()
    if captureSession.canAddOutput(metadataOutput) {
      captureSession.addOutput(metadataOutput)
      metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
      metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
    } else {
      delegate?.didFail(reason: .badOutput)
      return
    }
    
    let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
    videoPreviewLayer.frame = view.bounds
    view.layer.addSublayer(videoPreviewLayer)
    previewLayer = videoPreviewLayer
    captureSession.startRunning()
  }
}
#endif

class WalletScannerCoordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
  private var parent: WalletScannerView
  
  init(parent: WalletScannerView) {
    self.parent = parent
  }
  
  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    if let metadataObject = metadataObjects.first {
      guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
      guard let stringValue = readableObject.stringValue else { return }

      found(code: stringValue)
    }
  }
  
  func found(code: String) {
    parent.completion(.success(code))
  }
  
  func didFail(reason: WalletScannerView.ScanError) {
    parent.completion(.failure(reason))
  }
}

struct QrCodeScannerView_Previews: PreviewProvider {
    static var previews: some View {
      WalletScannerView() { result in
        // preview
      }
    }
}
