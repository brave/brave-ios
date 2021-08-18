// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import SwiftUI
import BraveUI

class BraveCertificate: ObservableObject {
    @Published var value: BraveCertificateModel
    
    init(model: BraveCertificateModel) {
        self.value = model
    }
    
    init?(name: String) {
        if let data = BraveCertificate.loadCertificateData(name: name),
           let model = BraveCertificateModel(data: data as Data) {
            self.value = model
            return
        }
        return nil
    }
    
    init?(certificate: SecCertificate) {
        if let model = BraveCertificateModel(certificate: certificate) {
            self.value = model
            return
        }
        return nil
    }
    
    init?(data: Data) {
        if let model = BraveCertificateModel(data: data) {
            self.value = model
            return
        }
        return nil
    }
    
    private static func loadCertificateData(name: String) -> CFData? {
        guard let path = Bundle.main.path(forResource: name, ofType: "cer") else {
            return nil
        }
        
        guard let certificateData = try? Data(contentsOf: URL(fileURLWithPath: path)) as CFData else {
            return nil
        }
        return certificateData
    }
    
    private static func loadCertificate(name: String) -> SecCertificate? {
        guard let certificateData = loadCertificateData(name: name) else {
            return nil
        }
        return SecCertificateCreateWithData(nil, certificateData)
    }
}

struct CertificateTitleView: View {
    let isRootCertificate: Bool
    let commonName: String
    
    var body: some View {
        HStack(alignment: .center, spacing: 15.0) {
            Image(uiImage: isRootCertificate ? #imageLiteral(resourceName: "Root") : #imageLiteral(resourceName: "Other"))
            VStack(alignment: .leading, spacing: 10.0) {
                Text(commonName)
                    .font(.system(size: 16.0, weight: .bold))
            }
        }.background(Color(UIColor.secondaryBraveGroupedBackground))
    }
}

struct CertificateKeyValueView: View, Hashable {
    let title: String
    let value: String?
    
    init(title: String, value: String? = nil) {
        self.title = title
        self.value = value
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 12.0) {
            Text(title)
                .font(.system(size: 12.0))
            Spacer()
            if let value = value, !value.isEmpty {
                Text(value)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.system(size: 12.0, weight: .medium))
            }
        }
    }
}

struct CertificateSectionView<ContentView>: View where ContentView: View {
    let title: String
    let values: [ContentView]
    
    var body: some View {
        Section(header: Text(title)
                    .font(.system(size: 12.0))) {
            
            ForEach(values.indices, id: \.self) {
                values[$0].listRowBackground(Color(UIColor.secondaryBraveGroupedBackground))
            }
        }
    }
}

struct CertificateView: View {
    @EnvironmentObject var model: BraveCertificate
    
    var body: some View {
        VStack {
            CertificateTitleView(isRootCertificate:
                                    model.value.isRootCertificate,
                                 commonName: model.value.subjectName.commonName).padding()
            
            if #available(iOS 14, *) {
                List {
                    content
                }
                .listStyle(InsetGroupedListStyle())
                .frame(maxHeight: .infinity)
                .environmentObject(model)
            } else {
                List {
                    content
                }
                .listStyle(GroupedListStyle())
                .frame(maxHeight: .infinity)
                .environmentObject(model)
            }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        // Subject name
        CertificateSectionView(title: "Subject Name", values: subjectNameViews())
        
        // Issuer name
        CertificateSectionView(title: "Issuer Name",
                               values: issuerNameViews())
        
        // Common info
        CertificateSectionView(title: "Common Info",
                               values: [
          // Serial number
          CertificateKeyValueView(title: "Serial Number",
                                    value: formattedSerialNumber()),
                                
          // Version
          CertificateKeyValueView(title: "Version",
                                    value: "\(model.value.version)"),
                                
          // Signature Algorithm
          CertificateKeyValueView(title: "Signature Algorithm",
                                    value: "\(model.value.signature.algorithm) (\(model.value.signature.objectIdentifier))"),
          //signatureParametersView().padding(.leading, 18.0)
        ])
        
        // Validity info
        CertificateSectionView(title: "Validity Dates",
                               values: [
          // Not Valid Before
          CertificateKeyValueView(title: "Not Valid Before",
                                    value: BraveCertificateUtilities.formatDate(model.value.notValidBefore)),
        
          // Not Valid After
          CertificateKeyValueView(title: "Not Valid After",
                                    value: BraveCertificateUtilities.formatDate(model.value.notValidAfter))
        ])
        
        // Public Key Info
        CertificateSectionView(title: "Public Key info",
                               values: publicKeyInfoViews())
        
        // Signature
        CertificateSectionView(title: "Signature",
                               values: [
          CertificateKeyValueView(title: "Signature",
                                    value: formattedSignature())
        ])
        
        // Fingerprints
        CertificateSectionView(title: "Fingerprints",
                               values: fingerprintViews())
        
        /*Section {
            ForEach(extensionViews().indices, id: \.self) {
                extensionViews()[$0]
            }
        }*/
    }
}

extension CertificateView {
    private func subjectNameViews() -> [CertificateKeyValueView] {
        let subjectName = model.value.subjectName
        
        // Ordered mapping
        let mapping = [
            KeyValue(key: "Country or Region", value: subjectName.countryOrRegion),
            KeyValue(key: "State/Province", value: subjectName.stateOrProvince),
            KeyValue(key: "Locality", value: subjectName.locality),
            KeyValue(key: "Organization", value: subjectName.organization),
            KeyValue(key: "Organizational Unit", value: subjectName.organizationalUnit),
            KeyValue(key: "Common Name", value: subjectName.commonName),
            KeyValue(key: "Street Address", value: subjectName.streetAddress),
            KeyValue(key: "Domain Component", value: subjectName.domainComponent),
            KeyValue(key: "User ID", value: subjectName.userId)
        ]
        
        return mapping.compactMap({
            $0.value.isEmpty ? nil : CertificateKeyValueView(title: $0.key,
                                                               value: $0.value)
        })
    }
    
    private func issuerNameViews() -> [CertificateKeyValueView] {
        let issuerName = model.value.issuerName
        
        // Ordered mapping
        let mapping = [
            KeyValue(key: "Country or Region", value: issuerName.countryOrRegion),
            KeyValue(key: "State/Province", value: issuerName.stateOrProvince),
            KeyValue(key: "Locality", value: issuerName.locality),
            KeyValue(key: "Organization", value: issuerName.organization),
            KeyValue(key: "Organizational Unit", value: issuerName.organizationalUnit),
            KeyValue(key: "Common Name", value: issuerName.commonName),
            KeyValue(key: "Street Address", value: issuerName.streetAddress),
            KeyValue(key: "Domain Component", value: issuerName.domainComponent),
            KeyValue(key: "User ID", value: issuerName.userId)
        ]
        
        return mapping.compactMap({
            $0.value.isEmpty ? nil : CertificateKeyValueView(title: $0.key,
                                                               value: $0.value)
        })
    }
    
    private func formattedSerialNumber() -> String {
        let serialNumber = model.value.serialNumber
        if Int64(serialNumber) != nil || UInt64(serialNumber) != nil {
            return "\(serialNumber)"
        }
        return BraveCertificateUtilities.formatHex(model.value.serialNumber)
    }
    
    private func signatureParametersView() -> CertificateKeyValueView {
        let signature = model.value.signature
        let parameters = signature.parameters.isEmpty ? "None" : BraveCertificateUtilities.formatHex(signature.parameters)
        return CertificateKeyValueView(title: "Parameters",
                                         value: parameters)
    }
    
    private func publicKeyInfoViews() -> [CertificateKeyValueView] {
        let publicKeyInfo = model.value.publicKeyInfo
        
        var algorithm = publicKeyInfo.algorithm
        if !publicKeyInfo.curveName.isEmpty {
            algorithm += " - \(publicKeyInfo.curveName)"
        }
        
        if !algorithm.isEmpty {
            algorithm += " (\(publicKeyInfo.objectIdentifier))"
        }
        
        let parameters = publicKeyInfo.parameters.isEmpty ? "None" : "\(publicKeyInfo.parameters.count / 2) bytes : \(BraveCertificateUtilities.formatHex(publicKeyInfo.parameters))"
        
        // TODO: Number Formatter
        let publicKey = "\(publicKeyInfo.keyBytesSize) bytes : \(BraveCertificateUtilities.formatHex(publicKeyInfo.keyHexEncoded))"
        
        // TODO: Number Formatter
        let keySizeInBits = "\(publicKeyInfo.keySizeInBits) bits"
        
        var keyUsages = [String]()
        if publicKeyInfo.keyUsage.contains(.DATA_ENCIPHERMENT) ||
            (publicKeyInfo.keyUsage.contains(.KEY_AGREEMENT) && publicKeyInfo.keyUsage.contains(.KEY_ENCIPHERMENT)) {
            keyUsages.append("Encrypt")
        }
        
        if publicKeyInfo.keyUsage.contains(.DIGITAL_SIGNATURE) {
            keyUsages.append("Verify")
        }
        
        if publicKeyInfo.keyUsage.contains(.KEY_ENCIPHERMENT) {
            keyUsages.append("Wrap")
        }
        
        if publicKeyInfo.keyUsage.contains(.KEY_AGREEMENT) {
            keyUsages.append("Derive")
        }
        
        if publicKeyInfo.type == .RSA && (publicKeyInfo.keyUsage.isEmpty || publicKeyInfo.keyUsage.rawValue == BraveKeyUsage.INVALID.rawValue) {
            keyUsages.append("Encrypt")
            keyUsages.append("Verify")
            keyUsages.append("Derive")
        } else if publicKeyInfo.keyUsage.isEmpty || publicKeyInfo.keyUsage.rawValue == BraveKeyUsage.INVALID.rawValue {
            keyUsages.append("Any")
        }
        
        let exponent = publicKeyInfo.exponent != 0 ? "\(publicKeyInfo.exponent)" : ""
        
        // Ordered mapping
        let mapping = [
            KeyValue(key: "Algorithm", value: algorithm),
            KeyValue(key: "Parameters", value: parameters),
            KeyValue(key: "Public Key", value: publicKey),
            KeyValue(key: "Exponent", value: exponent),
            KeyValue(key: "Key Size", value: keySizeInBits),
            KeyValue(key: "Key Usage", value: keyUsages.joined(separator: " "))
        ]
        
        return mapping.compactMap({
            $0.value.isEmpty ? nil : CertificateKeyValueView(title: $0.key,
                                                               value: $0.value)
        })
    }
    
    private func formattedSignature() -> String {
        let signature = model.value.signature
        return "\(signature.bytesSize) bytes : \(BraveCertificateUtilities.formatHex(signature.signatureHexEncoded))"
    }
    
    private func extensionViews() -> [AnyView] {
        let extensions = model.value.extensions
        
        var result = [AnyView]()
        for certExtension in extensions {
            if let view = extensionView(certExtension: certExtension) {
                result.append(view)
            }
        }
        return result
    }
    
    private func extensionView(certExtension: BraveCertificateExtensionModel) -> AnyView? {
        guard let extensionModel = certExtension.simplifiedModel as? BraveCertificateSimplifiedExtensionModel else {
            return nil
        }
        
        return AnyView(Group {
            if certExtension.nid <= 0 {
                Text("Unknown Extension (\(certExtension.onid))")
                    .font(.system(size: 12.0))
                    .foregroundColor(Color(#colorLiteral(red: 0.4988772273, green: 0.4988895059, blue: 0.4988829494, alpha: 1)))
            } else {
                Text(certExtension.title)
                    .font(.system(size: 12.0))
                    .foregroundColor(Color(#colorLiteral(red: 0.4988772273, green: 0.4988895059, blue: 0.4988829494, alpha: 1)))
            }
            VStack(alignment: .leading, spacing: 0.0) {
                RecursiveNestedKeyValueView(model: extensionModel.extensionInfo)
                    .padding(EdgeInsets(top: 10.0,
                                          leading: 0.0,
                                          bottom: 10.0,
                                          trailing: 10.0))
            }.padding(.leading, 10).background(Color(#colorLiteral(red: 0.9725490196, green: 0.9764705882, blue: 0.9843137255, alpha: 1))).cornerRadius(5.0)
        })
    }
    
    private func fingerprintViews() -> [CertificateKeyValueView] {
        let sha256Fingerprint = model.value.sha256Fingerprint
        let sha1Fingerprint = model.value.sha1Fingerprint
        
        return [
            CertificateKeyValueView(title: "SHA-256", value: BraveCertificateUtilities.formatHex(sha256Fingerprint.fingerprintHexEncoded)),
            CertificateKeyValueView(title: "SHA-1", value: BraveCertificateUtilities.formatHex(sha1Fingerprint.fingerprintHexEncoded))
        ]
    }
    
    private struct KeyValue {
        let key: String
        let value: String
    }
}

struct CertificateView_Previews: PreviewProvider {
    static var previews: some View {
        let model = BraveCertificate(name: "leaf")!

        CertificateView()
            .environmentObject(model)
    }
}

class CertificateViewController: UIViewController, PopoverContentComponent {
    
    init(certificate: BraveCertificate) {
        super.init(nibName: nil, bundle: nil)
        
        let rootView = CertificateView().environmentObject(certificate)
        let controller = UIHostingController(rootView: rootView)
        
        addChild(controller)
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        controller.didMove(toParent: self)
        
        controller.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        self.preferredContentSize = CGSize(width: UIScreen.main.bounds.width, height: 1000)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
