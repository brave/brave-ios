private let _singleton = TrackingProtection()

class TrackingProtection {
    fileprivate static let prefKey: Bool? = nil // Use the prefkey from Adblock for both

    static let dataVersion = "1"
    var isEnabled = true

    var parser: TrackingProtectionCpp = TrackingProtectionCpp()

    lazy var networkFileLoader: NetworkDataFileLoader = {
        let dataUrl = URL(string: "https://s3.amazonaws.com/tracking-protection-data/\(dataVersion)/TrackingProtection.dat")!
        let dataFile = "tp-data-\(dataVersion).dat"
        let loader = NetworkDataFileLoader(url: dataUrl, file: dataFile, localDirName: "tp-data")
        loader.delegate = self
        return loader
    }()

    class var singleton: TrackingProtection {
        return _singleton
    }

    fileprivate init() {
        NotificationCenter.default.addObserver(self, selector: #selector(TrackingProtection.prefsChanged(_:)), name: UserDefaults.didChangeNotification, object: nil)
        updateEnabledState()
    }

    func updateEnabledState() {
        isEnabled = BraveApp.getPrefs()?.boolForKey(AdBlocker.prefKey) ?? AdBlocker.prefKeyDefaultValue
    }

    @objc func prefsChanged(_ info: Notification) {
        updateEnabledState()
    }


    func shouldBlock(_ request: URLRequest) -> Bool {
        // synchronize code from this point on.
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }

        if !isEnabled {
            return false
        }

        guard let url = request.url,
            var mainDocDomain = request.mainDocumentURL?.host else {
                return false
        }
        guard var host = url.host else { return false}

        if request.mainDocumentURL?.absoluteString.startsWith(WebServer.sharedInstance.base) ?? false {
            return false
        }

        let whitelist = ["connect.facebook.net", "connect.facebook.com", "staticxx.facebook.com", "www.facebook.com", "scontent.xx.fbcdn.net", "pbs.twimg.com", "scontent-sjc2-1.xx.fbcdn.net", "platform.twitter.com", "syndication.twitter.com", "cdn.syndication.twimg.com"]

        if whitelist.contains(host) {
            return false
        }

        mainDocDomain = stripGenericSubdomainPrefixFromUrl(stripLocalhostWebServer(mainDocDomain))

        if host.contains(mainDocDomain) {
            return false // ignore top level doc
        }

        host = stripGenericSubdomainPrefixFromUrl(stripLocalhostWebServer(host))

        let isBlocked = parser.checkHostIsBlocked(host, mainDocumentHost: mainDocDomain)

        //if isBlocked { print("blocked \(url.absoluteString)") }
        return isBlocked
    }
}

extension TrackingProtection: NetworkDataFileLoaderDelegate {
    func fileLoader(_: NetworkDataFileLoader, setDataFile data: Data?) {
        parser.setDataFile(data)
    }

    func fileLoaderHasDataFile(_: NetworkDataFileLoader) -> Bool {
        return parser.hasDataFile()
    }

    func fileLoaderDelegateWillHandleInitialRead(_: NetworkDataFileLoader) -> Bool {
        return false
    }
}

