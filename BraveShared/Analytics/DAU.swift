/* This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = Logger.browserLogger

public class DAU {

    /// Default installation date for legacy woi version.
    public static let defaultWoiDate = "2016-01-04"
    
    private static let apiVersion = 1
    private static let baseUrl = "https://laptop-updates.brave.com/\(apiVersion)/usage/ios?platform=ios"
    
    /// Number of seconds that determins when a user is "active"
    private let pingRefreshDuration = 5.minutes
    
    /// We always use gregorian calendar for DAU pings. This also adds more anonymity to the server call.
    fileprivate static var calendar: Calendar { return Calendar(identifier: .gregorian) }
    
    private var launchTimer: Timer?
    private let today: Date?
    /// Whether a current ping attempt is being made
    private var processingPing = false
    private var todayComponents: DateComponents {
        return DAU.calendar.dateComponents([.day, .month, .year, .weekday], from: today ?? Date())
    }
    
    public init(date: Date? = nil) {
        today = date
    }
    
    /// Sends ping to server and returns a boolean whether a timer for the server call was scheduled.
    /// A user needs to be active for a certain amount of time before we ping the server.
    @discardableResult public func sendPingToServer() -> Bool {
        if AppConstants.BuildChannel == .developer {
            log.info("Development build detected, no server ping.")
            return false
        }
        
        // Sending ping immediately
        sendPingToServerInternal()
        
        // Setting up timer to try to send ping after certain amount of time.
        // This helps in offline mode situations.
        if launchTimer != nil { return false }
        launchTimer =
            Timer.scheduledTimer(
                timeInterval: pingRefreshDuration,
                target: self,
                selector: #selector(sendPingToServerInternal),
                userInfo: nil,
                repeats: true)
        
        return true
    }
    
    @objc public func sendPingToServerInternal() {
        guard let paramsAndPrefs = paramsAndPrefsSetup() else {
            log.debug("dau, no changes detected, no server ping")
            return
        }
        
        if processingPing {
            log.info("Currently processing a ping, blocking ping re-attempt")
            return
        }
        processingPing = true
        
        // Sending ping to server
        var pingRequest = URLComponents(string: DAU.baseUrl)
        pingRequest?.queryItems = paramsAndPrefs.queryParams
        
        guard let pingRequestUrl = pingRequest?.url else {
            log.error("Stats failed to update, via invalud URL: \(pingRequest?.description ?? "😡")")
            return
        }
        
        log.debug("send ping to server, url: \(pingRequestUrl)")
        
        let task = URLSession.shared.dataTask(with: pingRequestUrl) { _, _, error in
            defer {
                self.processingPing = false
            }
            
            if let e = error {
                log.error("status update error: \(e)")
                return
            }
            
            // Ping was successful, next ping should be sent with `first` parameter set to false.
            // This preference is set for future DAU pings.
            Preferences.DAU.firstPingParam.value = false
            
            // This preference is used to calculate whether user used the app in this month and/or day.
            Preferences.DAU.lastLaunchInfo.value = paramsAndPrefs.lastLaunchInfoPreference
        }
        
        task.resume()
    }
    
    /// A helper struct that stores all data from params setup.
    struct ParamsAndPrefs {
        let queryParams: [URLQueryItem]
        let lastLaunchInfoPreference: [Optional<Int>]
    }
    
    /// Return params query or nil if no ping should be send to server and also preference values to set
    /// after a succesful ing.
    func paramsAndPrefsSetup() -> ParamsAndPrefs? {
        var params = [channelParam(), versionParam()]
        
        let firstLaunch = Preferences.DAU.firstPingParam.value
        
        // All installs prior to this key existing (e.g. intallWeek == unknown) were set to `defaultWoiDate`
        // Enough time has passed where accounting for installs prior to this DAU improvement is unnecessary
        
        // See `woi` logic elsewhere to see fallback is handled
        
        // This could lead to an upgraded device having no `woi`, and that's fine
        if firstLaunch {
            Preferences.DAU.weekOfInstallation.value = today.mondayOfCurrentWeekFormatted ?? DAU.defaultWoiDate
        }
        
        guard let dauStatParams = dauStatParams(firstPing: firstLaunch) else {
            return nil
        }
        
        params += dauStatParams
        params += [
            firstLaunchParam(for: firstLaunch),
            // Must be after setting up the preferences
            weekOfInstallationParam()
        ]

        if let referralCode = UserReferralProgram.getReferralCode() {
            params.append(URLQueryItem(name: "ref", value: referralCode))
            UrpLog.log("DAU ping with added ref, params: \(params)")
        }
        
        let lastPingTimestamp = [Int((today ?? Date()).timeIntervalSince1970)]
        
        return ParamsAndPrefs(queryParams: params, lastLaunchInfoPreference: lastPingTimestamp)
    }
    
    func channelParam(for channel: AppBuildChannel = AppConstants.BuildChannel) -> URLQueryItem {
        return URLQueryItem(name: "channel", value: channel.isRelease ? "stable" : "beta")
    }
    
    func versionParam(for version: String = AppInfo.appVersion) -> URLQueryItem {
        var version = version
        if DAU.shouldAppend0(toVersion: version) {
            version += ".0"
        }
        return URLQueryItem(name: "version", value: version)
    }

    /// All app versions for dau pings must be saved in x.x.x format where x are digits.
    static func shouldAppend0(toVersion version: String) -> Bool {
        let correctAppVersionPattern = "^\\d+.\\d+$"
        do {
            let regex = try NSRegularExpression(pattern: correctAppVersionPattern, options: [])
            let match = regex.firstMatch(in: version, options: [], range: NSRange(location: 0, length: version.count))
            
            return match != nil
        } catch {
            log.error("Version regex pattern error")
            return false
        }
    }
    
    func firstLaunchParam(for isFirst: Bool) -> URLQueryItem {
        return URLQueryItem(name: "first", value: isFirst.description)
    }
    
    /// All first app installs are normalized to first day of the week.
    /// e.g. user installs app on wednesday 2017-22-11, his install date is recorded as of 2017-20-11(Monday)
    func weekOfInstallationParam(for woi: String? = Preferences.DAU.weekOfInstallation.value) -> URLQueryItem {
        var woi = woi
        // This _should_ be set all the time
        if woi == nil {
            woi = DAU.defaultWoiDate
            log.error("woi, is nil, using default: \(woi ?? "")")
        }
        return URLQueryItem(name: "woi", value: woi)
    }
    
    private enum PingType {
        case daily
        case weekly
        case monthly
    }
    
    private func getPings(forDate date: Date, lastPingDate: Date) -> [PingType] {
        let calendar = DAU.calendar
        var pings = [PingType]()

        func eraDayOrdinal(_ date: Date) -> Int? {
            return calendar.ordinality(of: .day, in: .era, for: date)
        }
        func nextDate(matching components: DateComponents) -> Date? {
            return calendar.nextDate(after: lastPingDate, matching: components, matchingPolicy: .nextTime)
        }
        
        if let nowDay = eraDayOrdinal(date), let lastPingDay = eraDayOrdinal(lastPingDate), nowDay > lastPingDay {
            pings.append(.daily)
        }
        
        let mondayWeekday = 2
        if let nextMonday = nextDate(matching: DateComponents(weekday: mondayWeekday)), date >= nextMonday {
            pings.append(.weekly)
        }
        if let nextFirstOfMonth = nextDate(matching: DateComponents(day: 1)), date >= nextFirstOfMonth {
            pings.append(.monthly)
        }
        return pings
    }
    
    /// Returns nil if no dau changes detected.
    func dauStatParams(_ dauStat: [Int?]? = Preferences.DAU.lastLaunchInfo.value,
                       firstPing: Bool,
                       channel: AppBuildChannel = AppConstants.BuildChannel) -> [URLQueryItem]? {
        
        func dauParams(_ daily: Bool, _ weekly: Bool, _ monthly: Bool) -> [URLQueryItem] {
            return ["daily": daily, "weekly": weekly, "monthly": monthly].map {
                URLQueryItem(name: $0.key, value: $0.value.description)
            }
        }
        
        if firstPing {
            return dauParams(true, true, true)
        }

        guard let stat = dauStat?.compactMap({ $0 }) else {
            log.error("Cannot cast dauStat to [Int]")
            return nil
        }
        
        guard let lastPingStat = stat.first else {
            log.error("Can't get last ping timestamp from dauStats")
            return nil
        }
        
        let lastPingDate = Date(timeIntervalSince1970: TimeInterval(lastPingStat))
        
        let pings = getPings(forDate: today, lastPingDate: lastPingDate)
        
        let daily = pings.contains(.daily)
        let weekly = pings.contains(.weekly)
        let monthly = pings.contains(.monthly)
        
        // No changes, no ping
        if pings.isEmpty {
            return nil
        }
        
        return dauParams(daily, weekly, monthly)
    }
}

extension Date {
    /// Returns date of current week's monday in YYYY-MM-DD formatted String
    var mondayOfCurrentWeekFormatted: String? {
        // We look for a previous monday because Sunday is considered a beggining of a new week using default gregorian calendar.
        // For example if today is Sunday, the next Monday using Calendar would be the day after Sunday which is wrong.
        // That's why backward search may sound counter intuitive.
        guard let monday = self.next(.monday, direction: .backward, considerSelf: true) else { return nil }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        return dateFormatter.string(from: monday)
    }
    
    private func next(_ weekday: Weekday, direction: Calendar.SearchDirection = .forward, considerSelf: Bool = false) -> Date? {
        let calendar = DAU.calendar
        let components = DateComponents(weekday: weekday.rawValue)
        
        if considerSelf && calendar.component(.weekday, from: self) == weekday.rawValue {
            return self
        }
        
        return calendar.nextDate(after: self,
                                 matching: components,
                                 matchingPolicy: .nextTime,
                                 direction: direction)
    }
    
    enum Weekday: Int {
        case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    }
}
