// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import AVFoundation
import Shared
import SnapKit

struct WalletScannerView: View {
  @Binding var toAddress: String
  @State private var isErrorPresented: Bool = false
  @State private var permissionDenied: Bool = false
  @Environment(\.presentationMode) @Binding private var presentationMode
  
  var body: some View {
    #if targetEnvironment(simulator)
    NavigationView {
      ZStack {
        Color.black.ignoresSafeArea()
        Button(action: {
          toAddress = "0xaa32"
          presentationMode.dismiss()
        }) {
          Text("Click here to simulate scan")
            .foregroundColor(.white)
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItemGroup(placement: .cancellationAction) {
          Button(action: {
            presentationMode.dismiss()
          }) {
            Text(Strings.CancelString)
              .foregroundColor(Color(.braveOrange))
          }
        }
      }
      .ignoresSafeArea()
    }
    #else
    NavigationView {
      _WalletScannerView(toAddress: $toAddress,
                         isErrorPresented: $isErrorPresented,
                         isPermissionDenied: $permissionDenied,
                         dismiss: { presentationMode.dismiss() }
      )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItemGroup(placement: .cancellationAction) {
            Button(action: {
              presentationMode.dismiss()
            }) {
              Text(Strings.CancelString)
                .foregroundColor(Color(.braveOrange))
            }
          }
        }
        .ignoresSafeArea()
        .background(
          Color.clear
            .alert(isPresented: $isErrorPresented) {
              Alert(
                title: Text(""),
                message: Text(Strings.scanQRCodeInvalidDataErrorMessage),
                dismissButton: .default(Text( Strings.scanQRCodeErrorOKButton), action: {
                  presentationMode.dismiss()
                })
              )
            }
        )
        .background(
          Color.clear
            .alert(isPresented: $permissionDenied) {
              Alert(
                title: Text(""),
                message: Text(Strings.scanQRCodePermissionErrorMessage),
                dismissButton: .default(Text(Strings.openPhoneSettingsActionTitle), action: {
                  UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
                })
              )
            }
        )
    }
    #endif
  }
}

struct _WalletScannerView: UIViewControllerRepresentable {
  typealias UIViewControllerType = WalletScannerViewController
  @Binding var toAddress: String
  @Binding var isErrorPresented: Bool
  @Binding var isPermissionDenied: Bool
  var dismiss: (() -> Void)
  
  func makeUIViewController(context: Context) -> UIViewControllerType {
    WalletScannerViewController(toAddress: _toAddress,
                                isErrorPresented: _isErrorPresented,
                                isPermissionDenied: _isPermissionDenied,
                                dismiss: self.dismiss
    )
  }
  
  func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
  }
}

class WalletScannerViewController: UIViewController {
  @Binding private var toAddress: String
  @Binding private var isErrorPresented: Bool
  @Binding private var isPermissionDenied: Bool
  
  private let captureDevice = AVCaptureDevice.default(for: .video)
  private let captureSession = AVCaptureSession().then {
    $0.sessionPreset = .high
  }
  
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var isFinishScanning = false
  
  var dismiss: (() -> Void)
  
  init(
    toAddress: Binding<String>,
    isErrorPresented: Binding<Bool>,
    isPermissionDenied: Binding<Bool>,
    dismiss: @escaping (() -> Void)
  ) {
    self._toAddress = toAddress
    self._isErrorPresented = isErrorPresented
    self._isPermissionDenied = isPermissionDenied
    self.dismiss = dismiss
    super.init(nibName: nil, bundle: nil)
  }
  
  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .black

    let getAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
    if getAuthorizationStatus != .denied {
      setupCamera()
    } else {
      isPermissionDenied = true
    }

    let imageView = UIImageView().then {
      $0.image = UIImage(named: "camera-overlay")
      $0.contentMode = .center
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.isAccessibilityElement = false
    }
    view.addSubview(imageView)
    imageView.snp.makeConstraints {
      $0.center.equalToSuperview()
      $0.width.equalTo(200)
      $0.height.equalTo(200)
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    
    previewLayer?.frame = view.layer.bounds
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    resetCamera()
    
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
      dismiss()
      return
    }

    guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
      isErrorPresented = true
      return
    }
    captureSession.addInput(videoInput)

    let metadataOutput = AVCaptureMetadataOutput()
    if captureSession.canAddOutput(metadataOutput) {
      captureSession.addOutput(metadataOutput)
      metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
      metadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
    } else {
      isErrorPresented = true
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

extension WalletScannerViewController: AVCaptureMetadataOutputObjectsDelegate {
  func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
    if let metadataObject = metadataObjects.first {
      guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else {
        isFinishScanning = true
        isErrorPresented = true
        return
      }
      guard let stringValue = readableObject.stringValue else {
        isFinishScanning = true
        isErrorPresented = true
        return
      }
      guard isFinishScanning == false else { return }

      guard stringValue.isAddress else {
        isFinishScanning = true
        isErrorPresented = true
        return
      }
      
      toAddress = stringValue
      isFinishScanning = true
      dismiss()
    } else {
      isFinishScanning = true
      isErrorPresented = true
    }
  }
  
  func resetCamera() {
    isFinishScanning = false
  }
}
