// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import BraveRewards
import SwiftUI

extension BraveKeyUsage: Hashable {}
extension BraveNetscapeCertificateType: Hashable {}
extension BraveCRLReasonFlags: Hashable {}
extension BraveCRLReasonCode: Hashable {}

struct BraveCertificateUtilities {
    static func formatHex(_ hexString: String, separator: String = " ") -> String {
        let n = 2
        let characters = Array(hexString)
        
        var result: String = ""
        stride(from: 0, to: characters.count, by: n).forEach {
            result += String(characters[$0..<min($0 + n, characters.count)])
            if $0 + n < characters.count {
                result += separator
            }
        }
        return result
    }
    
    static func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter().then {
            $0.dateStyle = .full
            $0.timeStyle = .full
        }
        return dateFormatter.string(from: date)
    }
    
    static func generalNameToExtensionValueType(_ generalName: BraveCertificateExtensionGeneralNameModel) -> BraveCertificateExtensionKeyValueType {
        switch generalName.type {
        case .INVALID:
            return .keyValue("Invalid", .string(generalName.other))
        case .OTHER_NAME:
            return .keyValue("Other Name", .string(generalName.other))
        case .EMAIL:
            return .keyValue("Email", .string(generalName.other))
        case .DNS:
            return .keyValue("DNS", .string(generalName.other))
        case .X400:
            return .keyValue("X400", .string(generalName.other))
        case .DIRNAME:
            return .keyValue("Directory Name", .nested(generalName.dirName.map {
                .keyValue($0.key, .string($0.value))
            }))
        case .EDIPARTY:
            return .keyValue("Electronic Data Interchange", .nested([
                .keyValue("Name Assigner", .string(generalName.nameAssigner)),
                .keyValue("Party Name", .string(generalName.partyName))
            ]))
        case .URI:
            return .keyValue("URI", .string(generalName.other))
        case .IPADD:
            return .keyValue("IP Address", .string(generalName.other))
        case .RID:
            return .keyValue("Registered ID", .string(generalName.other))
            
        @unknown default:
            fatalError()
            break
        }
    }
}


struct Value {
    let key: String
    let value: String?
    let children: [Value]
}

indirect enum BraveCertificateExtensionKeyValueType: Hashable {
    case string(String)
    case boolean(Bool)
    case hexString(String)
    case keyValue(String, BraveCertificateExtensionKeyValueType)
    case nested([BraveCertificateExtensionKeyValueType])
}

@objc
protocol BraveCertificateAnySimplifiedExtensionModel {}

class BraveCertificateSimplifiedExtensionModel: BraveCertificateAnySimplifiedExtensionModel {
    let type: BraveExtensionType
    let isCritical: Bool
    let onid: String
    let nid: Int
    let name: String
    let title: String
    
    let extensionInfo: BraveCertificateExtensionKeyValueType
    
    init(genericModel: BraveCertificateGenericExtensionModel) {
        type = genericModel.type
        isCritical = genericModel.isCritical
        onid = genericModel.onid
        nid = genericModel.nid
        name = genericModel.name
        title = genericModel.title
        
        switch genericModel.extensionType {
        case .STRING:
            extensionInfo = .string(genericModel.stringValue ?? "")
        case .HEX_STRING:
            if let hexValue = genericModel.stringValue {
                extensionInfo = .hexString(BraveCertificateUtilities.formatHex(hexValue))
            } else {
                extensionInfo = .hexString("")
            }
        case .KEY_VALUE:
            if let array = genericModel.arrayValue, !array.isEmpty {
                let pairs: [BraveCertificateExtensionKeyValueType] = array.compactMap {
                    if !$0.key.isEmpty && !$0.value.isEmpty {
                        return .keyValue($0.key, .string($0.value))
                    }
                    
                    if $0.key.isEmpty {
                        return .string($0.value)
                    }
                    
                    if $0.value.isEmpty {
                        return .string($0.key)
                    }
                    return nil
                }
                
                extensionInfo = pairs.isEmpty ? .string("") : .nested(pairs)
            } else {
                extensionInfo = .string("")
            }
        @unknown default:
            fatalError()
        }
    }
    
    init(genericModel: BraveCertificateExtensionModel, extensionInfo: BraveCertificateExtensionKeyValueType) {
        type = genericModel.type
        isCritical = genericModel.isCritical
        onid = genericModel.onid
        nid = genericModel.nid
        name = genericModel.name
        title = genericModel.title
        self.extensionInfo = extensionInfo
    }
}

@objc
protocol BraveCertificateSimplifiedExtensionProtocol {
    var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel { get }
}

struct RecursiveNestedKeyValueView: View {
    let model: BraveCertificateExtensionKeyValueType
    
    var body: some View {
        construct(model: model)
    }
    
    private func construct(model: BraveCertificateExtensionKeyValueType) -> AnyView {
        switch model {
        case .string(let value):
            return AnyView(CertificateKeyValueView(title: value))
        case .boolean(let value):
            return AnyView(CertificateKeyValueView(title: value ? "Yes" : "No"))
        case .hexString(let value):
            return AnyView(CertificateKeyValueView(title: value))
        case .keyValue(let key, let value):
            if case .keyValue = value {
                return AnyView(Section {
                    CertificateKeyValueView(title: key)
                    construct(model: value).padding(.leading, 20.0)
                })
            } else if case .nested = value {
                return AnyView(Section {
                    CertificateKeyValueView(title: key)
                    construct(model: value).padding(.leading, 20.0)
                })
            } else {
                switch value {
                case .string(let value):
                    return AnyView(CertificateKeyValueView(title: key, value: value))
                case .boolean(let value):
                    return AnyView(CertificateKeyValueView(title: key, value: value ? "Yes" : "No"))
                case .hexString(let value):
                    return AnyView(CertificateKeyValueView(title: key, value: value))
                default:
                    return AnyView(EmptyView())
                }
            }
        case .nested(let values):
            return AnyView(
                Section {
                    ForEach(values, id: \.self) {
                        construct(model: $0)
                    }
                }
            )
        }
    }
}

extension BraveCertificateExtensionModel: BraveCertificateSimplifiedExtensionProtocol {
    var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        assertionFailure("Sub-Class MUST implement this variable")
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .string(""))
    }
}

extension BraveCertificateBasicConstraintsExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        let extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical)),
            .keyValue("IsCA", .boolean(isCA))
        ]
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateKeyUsageExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        let mapping: [BraveKeyUsage: String] = [
            //.INVALID: "Invalid",
            .DIGITAL_SIGNATURE: "Digital Signature",
            .NON_REPUDIATION: "Non-Repudiation",
            .KEY_ENCIPHERMENT: "Key Encipherment",
            .DATA_ENCIPHERMENT: "Data Encipherment",
            .KEY_AGREEMENT: "Key Agreement",
            .KEY_CERT_SIGN: "Key Certificate Signing",
            .CRL_SIGN: "CRL Signing",
            .ENCIPHER_ONLY: "Enciphering Only",
            .DECIPHER_ONLY: "Deciphering Only"
        ]
        
        let keyUsages = mapping.compactMap({
            keyUsage.contains($0.key) ? $0.value : nil
        }).joined(separator: ", ")
        
        let extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical)),
            .keyValue("Key Usage", .string(keyUsages))
        ]
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateExtendedKeyUsageExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        let extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]/* + keyPurposes.enumerated().map({
            .keyValue("Purpose #\($0.offset + 1)",
                      .string("\($0.element.name) (\($0.element.nidString)"))
        })*/
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateSubjectKeyIdentifierExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        let extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical)),
            .keyValue("Key ID", .hexString(BraveCertificateUtilities.formatHex(hexEncodedkeyInfo)))
        ]
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateAuthorityKeyIdentifierExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical)),
            .keyValue("Key ID", .hexString(BraveCertificateUtilities.formatHex(keyId)))
        ]
        
        if !serial.isEmpty {
            extensionValues.append(.keyValue("Serial Number",
                                             .hexString(BraveCertificateUtilities.formatHex(serial))))
        }
        
        if !issuer.isEmpty {
            let issuerInfo = issuer.map({
                BraveCertificateUtilities.generalNameToExtensionValueType($0)
            })
            
            if !issuerInfo.isEmpty {
                extensionValues.append(.keyValue("Issuer", .nested(issuerInfo)))
            }
        }
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificatePrivateKeyUsagePeriodExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if let notBefore = notBefore {
            extensionValues.append(.keyValue("Not Before",
                                             .string(BraveCertificateUtilities.formatDate(notBefore))))
        }
        
        if let notAfter = notAfter {
            extensionValues.append(.keyValue("Not After",
                                             .string(BraveCertificateUtilities.formatDate(notAfter))))
        }
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateSubjectAlternativeNameExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        let names = names.map({
            BraveCertificateUtilities.generalNameToExtensionValueType($0)
        })
        
        extensionValues.append(contentsOf: names)
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateIssuerAlternativeNameExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        let names = names.map({
            BraveCertificateUtilities.generalNameToExtensionValueType($0)
        })
        
        extensionValues.append(contentsOf: names)
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateAuthorityInformationAccessExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical)),
        ]
        
        let accessDescriptions: [BraveCertificateExtensionKeyValueType] = accessDescriptions.compactMap({
            if $0.locations.isEmpty {
                return .string("\($0.oidName) \($0.oid)")
            }
            
            return .keyValue("\($0.oidName) \($0.oid)", .nested($0.locations.map {
                BraveCertificateUtilities.generalNameToExtensionValueType($0)
            }))
        })
        
        extensionValues.append(contentsOf: accessDescriptions)
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateSubjectInformationAccessExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical)),
        ]
        
        let accessDescriptions: [BraveCertificateExtensionKeyValueType] = accessDescriptions.compactMap({
            if $0.locations.isEmpty {
                return .string("\($0.oidName) \($0.oid)")
            }
            
            return .keyValue("\($0.oidName) \($0.oid)", .nested($0.locations.map {
                BraveCertificateUtilities.generalNameToExtensionValueType($0)
            }))
        })
        
        extensionValues.append(contentsOf: accessDescriptions)
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateNameConstraintsExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical)),
        ]
        
        if !permittedSubtrees.isEmpty {
            let permittedSubtrees: [BraveCertificateExtensionKeyValueType] = permittedSubtrees.enumerated().map({
                var treeInfo: [BraveCertificateExtensionKeyValueType] = [
                    .keyValue("Minimum", .string($0.element.minimum)),
                    .keyValue("Maximum", .string($0.element.maximum)),
                ]
                
                if !$0.element.names.isEmpty {
                    treeInfo.append(contentsOf: $0.element.names.map {
                        BraveCertificateUtilities.generalNameToExtensionValueType($0)
                    })
                }
                
                return .keyValue("Tree #\($0.offset + 1)", .nested(treeInfo))
            })
            
            extensionValues.append(.keyValue("Permitted", .nested(permittedSubtrees)))
        }
        
        if !excludedSubtrees.isEmpty {
            let excludedSubtrees: [BraveCertificateExtensionKeyValueType] = excludedSubtrees.enumerated().map({
                var treeInfo: [BraveCertificateExtensionKeyValueType] = [
                    .keyValue("Minimum", .string($0.element.minimum)),
                    .keyValue("Maximum", .string($0.element.maximum)),
                ]
                
                if !$0.element.names.isEmpty {
                    treeInfo.append(contentsOf: $0.element.names.map {
                        BraveCertificateUtilities.generalNameToExtensionValueType($0)
                    })
                }
                
                return .keyValue("Tree #\($0.offset + 1)", .nested(treeInfo))
            })
            
            extensionValues.append(.keyValue("Excluded", .nested(excludedSubtrees)))
        }
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificatePoliciesExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical)),
        ]
        
        let policies: [BraveCertificateExtensionKeyValueType] = policies.enumerated().map({
            if $0.element.qualifiers.isEmpty {
                return .string("Policy #\($0.offset + 1) (\($0.element.oid))")
            }
            
            return .keyValue("Policy #\($0.offset + 1) (\($0.element.oid))", .nested($0.element.qualifiers.map {
                var qualifierInfo = [BraveCertificateExtensionKeyValueType]()
                if !$0.cps.isEmpty {
                    qualifierInfo.append(.keyValue("CPS", .string($0.cps)))
                }
                
                if let notice = $0.notice {
                    var noticeInfo = [BraveCertificateExtensionKeyValueType]()
                    if !notice.organization.isEmpty {
                        noticeInfo.append(.keyValue("Organization", .string(notice.organization)))
                    }
                    
                    if !notice.noticeNumbers.isEmpty {
                        noticeInfo.append(.keyValue("Notice Numbers", .string(notice.noticeNumbers.joined(separator: ", "))))
                    }
                    
                    if !notice.explicitText.isEmpty {
                        noticeInfo.append(.keyValue("Explicit Text", .string(notice.explicitText)))
                    }
                    
                    if !noticeInfo.isEmpty {
                        qualifierInfo.append(.keyValue("Notice", .nested(noticeInfo)))
                    }
                }
                
                return qualifierInfo.isEmpty ? .string("Qualifier ID #\($0.pqualId)") : .keyValue("Qualifier ID #\($0.pqualId)", .nested(qualifierInfo))
            }))
        })
        
        extensionValues.append(contentsOf: policies)
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificatePolicyMappingsExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical)),
        ]
        
        let policies: [BraveCertificateExtensionKeyValueType] = policies.enumerated().map({
            var policyInfo = [BraveCertificateExtensionKeyValueType]()
            if !$0.element.subjectDomainPolicy.isEmpty {
                policyInfo.append(.keyValue("Subject Domain", .string($0.element.subjectDomainPolicy)))
            }
            
            if !$0.element.issuerDomainPolicy.isEmpty {
                policyInfo.append(.keyValue("Issuer Domain", .string($0.element.issuerDomainPolicy)))
            }
            
            return policyInfo.isEmpty ? .string("Policy #\($0.offset + 1)") : .keyValue("Policy #\($0.offset + 1)", .nested(policyInfo))
        })
        
        extensionValues.append(contentsOf: policies)
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificatePolicyConstraintsExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if !requireExplicitPolicy.isEmpty {
            extensionValues.append(.keyValue("Require Explicit Policy", .string(requireExplicitPolicy)))
        }
        
        if !inhibitPolicyMapping.isEmpty {
            extensionValues.append(.keyValue("Inhibit Policy Mapping", .string(inhibitPolicyMapping)))
        }
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateInhibitAnyPolicyExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if !policyAny.isEmpty {
            extensionValues.append(.keyValue("Policy Any", .string(policyAny)))
        }
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateTLSFeatureExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if !features.isEmpty {
            extensionValues.append(.keyValue("Features", .string(
                features.map({ "v\($0.int64Value)" }).joined(separator: ", ")
            )))
        }
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}
    
// Netscape Certificate Extensions - Largely Obsolete
extension BraveCertificateNetscapeCertTypeExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        let mapping: [BraveNetscapeCertificateType: String] = [
            //.INVALID: "Invalid",
            .SSL_CLIENT: "SSL Client",
            .SSL_SERVER: "SSL Server",
            .SMIME: "SMIME",
            .OBJSIGN: "Object Sign",
            .SSL_CA: "SSL CA",
            .SMIME_CA: "SMIME CA",
            .OBJSIGN_CA: "Object Sign CA",
            .ANY_CA: "Any CA"
        ]
        
        let certTypes = mapping.compactMap({
            certType.contains($0.key) ? $0.value : nil
        }).joined(separator: ", ")
        
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if !certTypes.isEmpty {
            extensionValues.append(.keyValue("Purposes", .string(certTypes)))
        }
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateNetscapeURLExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if !url.isEmpty {
            extensionValues.append(.keyValue("URL", .string(url)))
        }
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateNetscapeStringExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if !string.isEmpty {
            extensionValues.append(.keyValue("String", .string(string)))
        }
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

// Miscellaneous Certificate Extensions
extension BraveCertificateSXNetExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical)),
            .keyValue("Version", .string("\(version + 1)"))
        ]
        
        if !ids.isEmpty {
            let ids = ids.enumerated().flatMap { enumerated -> [BraveCertificateExtensionKeyValueType] in
                var values = [BraveCertificateExtensionKeyValueType]()
                if !enumerated.element.idZone.isEmpty {
                    values.append(.keyValue("Zone #\(enumerated.offset + 1)", .string(enumerated.element.idZone)))
                }
                
                if !enumerated.element.idUser.isEmpty {
                    values.append(.keyValue("User #\(enumerated.offset + 1)", .string(enumerated.element.idUser)))
                }
                return values
            }
            
            if !ids.isEmpty {
                extensionValues.append(.keyValue("IDs", .nested(ids)))
            }
        }
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}
extension BraveCertificateProxyCertInfoExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if pathLengthConstraint > 0 {
            extensionValues.append(.keyValue("Path Length Constraint", .string("\(pathLengthConstraint)")))
        }
        
        if let proxyPolicy = proxyPolicy {
            var policies = [BraveCertificateExtensionKeyValueType]()
            if !proxyPolicy.language.isEmpty {
                policies.append(.keyValue("Language", .string(proxyPolicy.language)))
            }
            
            if !proxyPolicy.policyText.isEmpty {
                policies.append(.keyValue("Policy Text", .string(proxyPolicy.policyText)))
            }
            
            if !policies.isEmpty {  // Could always just show "None" or something but in any case, empty should be invalid.
                extensionValues.append(.keyValue("Proxy Policy", .nested(policies)))
            }
        }
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

// PKIX CRL Extensions
extension BraveCertificateCRLNumberExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if !crlNumber.isEmpty {
            extensionValues.append(.keyValue("CRL Number", .string(crlNumber)))
        }
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateCRLDistributionPointsExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if !distPoints.isEmpty {
            let flagMapping: [BraveCRLReasonFlags: String] = [
                //.INVALID: "Invalid",
                .UNUSED: "Unused",
                .KEY_COMPROMISED: "Key Compromised",
                .CA_COMPROMISED: "CA Compromised",
                .AFFILIATION_CHANGED: "Affiliate Changed",
                .SUPERSEDED: "Superseded",
                .CESSATION_OF_OPERATION: "Cessation of Operation",
                .CERTIFICATE_HOLD: "Certificate Hold",
                .PRIVILEGE_WITHDRAWN: "Privilege Withdrawn",
                .AA_COMPROMISED: "AA Compromised"
            ]
            
            let distPoints: [[BraveCertificateExtensionKeyValueType]] = distPoints.compactMap({ element in
                var points = [BraveCertificateExtensionKeyValueType]()
                if !element.genDistPointName.isEmpty {
                    points.append(.keyValue("Names", .nested(element.genDistPointName.map {
                        BraveCertificateUtilities.generalNameToExtensionValueType($0)
                    })))
                }
                
                if !element.relativeDistPointNames.isEmpty {
                    let names: [BraveCertificateExtensionKeyValueType] = element.relativeDistPointNames.compactMap {
                        if !$0.key.isEmpty && !$0.value.isEmpty {
                            return .keyValue($0.key, .string($0.value))
                        }
                        
                        if !$0.key.isEmpty {
                            return .string($0.value)
                        }
                        
                        if !$0.value.isEmpty {
                            return .string($0.key)
                        }
                        return nil
                    }
                    
                    if !names.isEmpty {
                        points.append(.keyValue("Relative Names", .nested(names)))
                    }
                }
                
                if !element.reasonFlags.isEmpty {
                    let flags = flagMapping.compactMap({
                        element.reasonFlags.contains($0.key) ? $0.value : nil
                    }).joined(separator: ", ")
                    
                    if !flags.isEmpty {
                        points.append(.keyValue("Reason Flags", .string(flags)))
                    }
                }
                
                if !element.crlIssuer.isEmpty {
                    points.append(.keyValue("CRL Issuer", .nested(element.crlIssuer.map {
                        BraveCertificateUtilities.generalNameToExtensionValueType($0)
                    })))
                }
                
                if element.dpReason > 0 {
                    points.append(.keyValue("DP Reason", .string("\(element.dpReason)")))
                }
                
                return points.isEmpty ? nil : points
            })
            
            if distPoints.count == 1, let point = distPoints.first {
                extensionValues.append(contentsOf: point)
            } else {
                for point in distPoints.enumerated() {
                    extensionValues.append(.keyValue("Point #\(point.offset + 1)", .nested(point.element)))
                }
            }
        }
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateDeltaCRLExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if !crlNumber.isEmpty {
            extensionValues.append(.keyValue("CRL Number", .string(crlNumber)))
        }
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateInvalidityDateExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        let extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical)),
            .keyValue("Invalidity Date",
                      .string(BraveCertificateUtilities.formatDate(invalidityDate)))
        ]
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateIssuingDistributionPointExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        let flagMapping: [BraveCRLReasonFlags: String] = [
            //.INVALID: "Invalid",
            .UNUSED: "Unused",
            .KEY_COMPROMISED: "Key Compromised",
            .CA_COMPROMISED: "CA Compromised",
            .AFFILIATION_CHANGED: "Affiliate Changed",
            .SUPERSEDED: "Superseded",
            .CESSATION_OF_OPERATION: "Cessation of Operation",
            .CERTIFICATE_HOLD: "Certificate Hold",
            .PRIVILEGE_WITHDRAWN: "Privilege Withdrawn",
            .AA_COMPROMISED: "AA Compromised"
        ]
        
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if !genDistPointName.isEmpty {
            extensionValues.append(.keyValue("Names", .nested(genDistPointName.map {
                BraveCertificateUtilities.generalNameToExtensionValueType($0)
            })))
        }
        
        if !relativeDistPointNames.isEmpty {
            let names: [BraveCertificateExtensionKeyValueType] = relativeDistPointNames.compactMap {
                if !$0.key.isEmpty && !$0.value.isEmpty {
                    return .keyValue($0.key, .string($0.value))
                }
                
                if !$0.key.isEmpty {
                    return .string($0.value)
                }
                
                if !$0.value.isEmpty {
                    return .string($0.key)
                }
                return nil
            }
            
            if !names.isEmpty {
                extensionValues.append(.keyValue("Relative Names", .nested(names)))
            }
        }
        
        extensionValues.append(contentsOf: [
            .keyValue("Only User Certificates", .boolean(onlyUserCertificates)),
            .keyValue("Only CA Certificates", .boolean(onlyCACertificates)),
        ])
        
        if !onlySomeReasons.isEmpty {
            let reasons = flagMapping.compactMap({
                onlySomeReasons.contains($0.key) ? $0.value : nil
            }).joined(separator: ", ")
            
            if !reasons.isEmpty {
                extensionValues.append(.keyValue("Only Some Reasons", .string(reasons)))
            }
        }
        
        extensionValues.append(contentsOf: [
            .keyValue("Indirect CRL", .boolean(indirectCRL)),
            .keyValue("Only Attributes", .boolean(onlyAttr)),
            .keyValue("Only Attributes Validated", .boolean(onlyAttrValidated))
        ])
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

// CRL entry extensions from PKIX standards such as RFC5280
extension BraveCertificateCRLReasonExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        let mapping: [BraveCRLReasonCode: String] = [
            .NONE: "None",
            .UNSPECIFIED: "Unspecified",
            .KEY_COMPROMISED: "Key Compromised",
            .CA_COMPROMISED: "CA Compromised",
            .AFFILIATION_CHANGED: "Affiliation Changed",
            .SUPERSEDED: "Superseded",
            .CESSATION_OF_OPERATION: "Cessation of Operation",
            .CERTIFICATE_HOLD: "Certificate Hold",
            .REMOVE_FROM_CRL: "Remove From CRL",
            .PRIVILEGE_WITHDRAWN: "Privilege Withdrawn",
            .AA_COMPROMISED: "AA Compromised"
        ]
        
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if reason != .NONE, let reasonCode = mapping[reason] {
            extensionValues.append(.keyValue("Reason Code", .string(reasonCode)))
        }
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateIssuerExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if !names.isEmpty {
            extensionValues.append(contentsOf: names.map {
                BraveCertificateUtilities.generalNameToExtensionValueType($0)
            })
        }
        
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}
    
// OCSP Extensions
extension BraveCertificatePKIXOCSPNonceExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        if !nonce.isEmpty {
            extensionValues.append(.keyValue("Nonce", .string(nonce)))
        }
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateSCTExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        var extensionValues: [BraveCertificateExtensionKeyValueType] = [
            .keyValue("Critical", .boolean(isCritical))
        ]
        
        let scts = scts.enumerated().map({ enumerated -> BraveCertificateExtensionKeyValueType in
            if let hexRepresentation = enumerated.element.hexRepresentation {
                return .keyValue("SCT #\(enumerated.offset + 1)", .string(
                    BraveCertificateUtilities.formatHex(hexRepresentation)
                ))
            } else {
                var sctInfo: [BraveCertificateExtensionKeyValueType] = [
                    .keyValue("Version", .string("\(enumerated.element.version + 1)")),
                    .keyValue("Log Entry Type", .string("\(enumerated.element.logEntryType)")),
                ]
                
                if !enumerated.element.logId.isEmpty {
                    sctInfo.append(.keyValue("Log ID", .string(BraveCertificateUtilities.formatHex(enumerated.element.logId))))
                }
                
                sctInfo.append(.keyValue("Timestamp", .string(BraveCertificateUtilities.formatDate(enumerated.element.timestamp))))
                if !enumerated.element.extensions.isEmpty {
                    sctInfo.append(.keyValue("Extensions", .string(enumerated.element.extensions)))
                }
                
                if !enumerated.element.signatureName.isEmpty {
                    sctInfo.append(.keyValue("Signature Algorithm", .string(enumerated.element.signatureName)))  // Maybe add NID too?
                }
                
                if !enumerated.element.signature.isEmpty {
                    sctInfo.append(.keyValue("Signature", .string("\(enumerated.element.signature.count / 2) bytes : \(BraveCertificateUtilities.formatHex(enumerated.element.signature))")))
                }
                
                return .keyValue("SCT #\(enumerated.offset + 1)", .nested(sctInfo))
            }
        })
        
        extensionValues.append(contentsOf: scts)
        return BraveCertificateSimplifiedExtensionModel(genericModel: self, extensionInfo: .nested(extensionValues))
    }
}

extension BraveCertificateGenericExtensionModel {
    override var simplifiedModel: BraveCertificateAnySimplifiedExtensionModel {
        return BraveCertificateSimplifiedExtensionModel(genericModel: self)
    }
}
