// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WebKit
import Data
import BraveShared
import ObjectiveC.runtime

public protocol Disposable {
    func dispose()
    func bind(to: NSObject)
}

private class DisposableReference: Disposable {
    private var associatedKey: Int
    private var disposer: ((DisposableReference) -> Void)?
    
    init(_ disposer: @escaping (DisposableReference) -> Void) {
        associatedKey = 0
        self.disposer = disposer
    }
    
    deinit {
        dispose()
    }
    
    func dispose() {
        self.disposer?(self)
        self.disposer = nil
    }
    
    func bind(to object: NSObject) {
        objc_setAssociatedObject(object, &associatedKey, self, .OBJC_ASSOCIATION_RETAIN)
    }
}

public class Observable<T> {
    public typealias Observer = (_ newValue: T, _ oldValue: T?) -> Void
    private var subscribers = [(Observer, AnyObject)]()
    
    public init(_ value: T) {
        self.value = value
    }
    
    public var value: T {
        didSet {
            subscribers.forEach({
                $0.0(value, oldValue)
            })
        }
    }
    
    @discardableResult
    public func observe(_ observer: @escaping Observer) -> Disposable {
        let disposable = DisposableReference({ [weak self] in self?.removeObserver($0) })
        subscribers.append((observer, disposable))
        subscribers.forEach { $0.0(value, nil) }
        return disposable
    }
    
    public func removeObserver(_ object: AnyObject) {
        subscribers = subscribers.filter { $0.1 !== object }
    }
    
    public func removeAllObservers() {
        subscribers.removeAll()
    }
}

struct PlaylistInfo: Decodable {
    let name: String
    let src: String
    
    static func from(message: WKScriptMessage) throws -> PlaylistInfo? {
        if !JSONSerialization.isValidJSONObject(message.body) {
            return nil
        }
        
        let data = try JSONSerialization.data(withJSONObject: message.body, options: .prettyPrinted)
        return try JSONDecoder().decode(PlaylistInfo.self, from: data)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = (try? container.decode(String.self, forKey: .name)) ?? ""
        self.src = (try? container.decode(String.self, forKey: .src)) ?? ""
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case src
    }
}

class PlaylistManager: TabContentScript {
    fileprivate weak var tab: Tab?
    
    init(tab: Tab) {
        self.tab = tab
    }
    
    static func name() -> String {
        return "PlaylistManager"
    }
    
    func scriptMessageHandlerName() -> String? {
        return "playlistManager"
    }
    
    func userContentController(_ userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        
        do {
            guard let item = try PlaylistInfo.from(message: message) else { return }
            if tab?.playlistItems.value.contains(where: { $0.src == item.src }) == false {
                if !item.src.isEmpty {
                    tab?.playlistItems.value.append(item)
                }
            }
        } catch {
            print(error)
        }
    }
}
