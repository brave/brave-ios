// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SnapshotTesting
import XCTest

@testable import Client

// MARK: - Float

extension Float {

    static let defaultSnapshotTolerance: Float = 0.005
}

// MARK: - TestDevice

struct TestDevice {

    // MARK: Model
    
    enum Model: String {

        // MARK: Internal
        
        case iPhone8Plus
        case iPhoneSe
        case iPhoneXr
        case iPadPro11

        // MARK: Fileprivate
        
        fileprivate func config(orientation: ViewImageConfig.Orientation) -> ViewImageConfig {
            switch self {
            case .iPhone8Plus:
                return ViewImageConfig.iPhone8Plus(orientation)
            case .iPhoneSe:
                return ViewImageConfig.iPhoneSe(orientation)
            case .iPhoneXr:
                return ViewImageConfig.iPhoneXr(orientation)
            case .iPadPro11:
                return ViewImageConfig.iPadPro11(orientation)
            }
        }
    }

    // MARK: Internal
    
    static let defaultDevices: [TestDevice] = {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [
                TestDevice(orientation: .landscape, model: .iPadPro11)
            ]
        } else {
            return [
                TestDevice(model: .iPhone8Plus),
                TestDevice(model: .iPhoneSe),
                TestDevice(model: .iPhoneXr)
            ]
        }
    }()

    init(
        orientation: ViewImageConfig.Orientation = .portrait,
        model: Model = .iPhoneSe,
        heightMultiplier: CGFloat = 1,
        tolerance: Float = 0,
        userInterfaceStyle: UIUserInterfaceStyle = .light)
    {
        self.orientation = orientation
        self.model = model
        self.heightMultiplier = heightMultiplier
        self.precision = 1 - tolerance
        self.userInterfaceStyle = userInterfaceStyle
    }

    let orientation: ViewImageConfig.Orientation
    let model: Model
    let heightMultiplier: CGFloat
    let precision: Float
    let userInterfaceStyle: UIUserInterfaceStyle

}

extension Collection where Element == TestDevice {

    func with(
        orientaion: ViewImageConfig.Orientation = .defaultOrientation,
        heightMultipliers: [(model: TestDevice.Model, multiplier: CGFloat)]? = nil,
        tolerance: Float = 0) -> [Element]
    {
        map { device in
            TestDevice(
                orientation: orientaion,
                model: device.model,
                heightMultiplier: heightMultipliers?.first(where: { $0.model == device.model })?.multiplier ??
                    device.heightMultiplier,
                tolerance: tolerance,
                userInterfaceStyle: device.userInterfaceStyle
            )
        }
    }
}

extension ViewImageConfig.Orientation {

    static let defaultOrientation: ViewImageConfig.Orientation = {
        UIDevice.current.userInterfaceIdiom == .pad ? .landscape : .portrait
    }()
}

fileprivate extension TestDevice {

    // MARK: Fileprivate
    
    var size: CGSize? {
        guard let modelSize = model.config(orientation: self.orientation).size else { return nil }

        return CGSize(width: modelSize.width, height: modelSize.height * heightMultiplier)
    }

    var snapShotting: Snapshotting<UIViewController, UIImage> {
        Snapshotting<UIViewController, UIImage>.image(
            on: model.config(orientation: orientation),
            precision: precision,
            size: size,
            traits: UITraitCollection())
    }

}

// MARK: - UIUserInterfaceStyle

fileprivate extension UIUserInterfaceStyle {

    var identifier: String {
        switch self {
        case .dark: return "dark"
        default: return "light"
        }
    }
}

// MARK: - XCTestCase
extension XCTestCase {

    // MARK: Internal
    
    /// Global recording mode for all iOS snapshot tests
    var snapshotRecordMode: Bool {
        false
    }

    func verifyViewController(
        _ value: UIViewController,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line,
        identifier: String? = nil,
        delay: TimeInterval? = nil,
        testDevices: [TestDevice] = TestDevice.defaultDevices)
    {
        verifyNavigationController(
            UINavigationController(rootViewController: value),
            file: file,
            testName: testName,
            line: line,
            identifier: identifier,
            delay: delay,
            testDevices: testDevices)
    }

    func verifyNavigationController(
        _ value: UINavigationController,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line,
        identifier: String? = nil,
        delay: TimeInterval? = nil,
        testDevices: [TestDevice] = TestDevice.defaultDevices)
    {
        testDevices.forEach { testDevice in
            self.verifyNavigationController(
                value,
                file: file,
                testName: testName,
                line: line,
                identifier: identifier,
                delay: delay,
                size: testDevice.size,
                snapshotConfig: testDevice.snapShotting,
                deviceName: testDevice.model.rawValue,
                userInterfaceStyle: testDevice.userInterfaceStyle)
        }
    }

    // MARK: Private
    
    private func verifyNavigationController(
        _ value: UINavigationController,
        file: StaticString = #file,
        testName: String = #function,
        line: UInt = #line,
        identifier: String? = nil,
        delay: TimeInterval? = nil,
        size: CGSize?,
        snapshotConfig: Snapshotting<UIViewController, UIImage>,
        deviceName: String,
        userInterfaceStyle: UIUserInterfaceStyle)
    {
        if #available(iOS 13.0, *) {
            value.view.overrideUserInterfaceStyle = userInterfaceStyle
        }

        let displayName = FileManager.default.displayName(atPath: "\(file)")

        let filePath = URL(fileURLWithPath: "\(file)")
            .pathComponents.prefix(while: { $0 != "ClientTests" })
            .joined(separator: "/")
            .dropFirst()
            .appending("/Snapshots")
            .appending("/\(displayName)")
            .appending("/\(UIDevice.current.model)")
            .appending("/\(userInterfaceStyle.identifier)")

        var named: String = deviceName

        if let size = size {
            let width = Int(size.width)
            let height = Int(size.height)
            named += "-\(width)X\(height)"
        }

        if let id = identifier {
            named += ".\(id)"
        }

        let snapshotting: Snapshotting<UIViewController, UIImage>

        if let delay = delay {
            snapshotting = .wait(for: delay, on: snapshotConfig)
        } else {
            snapshotting = snapshotConfig
        }

        let failure = verifySnapshot(
            matching: value,
            as: snapshotting,
            named: named,
            snapshotDirectory: filePath,
            file: file,
            testName: testName,
            line: line)

        guard let message = failure else { return }
        XCTFail(message, file: file, line: line)
    }
}
