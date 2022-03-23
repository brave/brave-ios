// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Shared
import BraveShared
import BraveCore

private let logger = Logger.browserLogger

protocol NTPDownloaderDelegate: AnyObject {
  func onSponsorUpdated(sponsor: NTPSponsor?)
  func onThemeUpdated(theme: CustomTheme?)
  func preloadCustomTheme(theme: CustomTheme?)
}

class NTPDownloader {
  enum ResourceType {
    /// Downloaded only when users installs the app via special referral code.
    case superReferral(code: String)
    /// Downloaded for all users if a sponsor is available in their region.
    case sponsor

    func resourceBaseURL(
      for buildChannel: AppBuildChannel = AppConstants.buildChannel,
      locale: Locale = .current
    ) -> URL? {
      // This should _probably_ correspond host for URP
      let baseUrl =
        buildChannel.isPublic
        ? "https://mobile-data.s3.brave.com/"
        : "https://mobile-data-dev.s3.brave.software"

      switch self {
      case .superReferral(let code):
        return URL(string: baseUrl)?
          .appendingPathComponent("superreferrer")
          .appendingPathComponent(code)
      case .sponsor:
        guard let region = locale.regionCode else { return nil }
        let url = URL(string: baseUrl)?
          .appendingPathComponent(region)
          .appendingPathComponent("ios")
        return url
      }
    }

    /// Name of the metadata file on the server.
    var resourceName: String {
      switch self {
      case .superReferral: return "data.json"
      case .sponsor: return "photo.json"
      }
    }

    /// Where the file is saved locally.
    var saveLocation: URL? {
      guard
        let baseUrl = FileManager.default
          .urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
          .appendingPathComponent(self.saveTopFolderName)
      else { return nil }

      switch self {
      case .sponsor:
        return baseUrl
      case .superReferral(let code):
        // Each super referral is saved in separate folder,
        // this allows to have multiple themes installed on the device in the future.
        return baseUrl.appendingPathComponent(code)
      }
    }

    /// Resources are downloaded in different folders to support multiple themes and mixing super referrals with branded images
    /// in the future.
    var saveTopFolderName: String {
      switch self {
      case .sponsor: return "NTPDownloads"
      case .superReferral: return "Themes"
      }
    }
  }

  /// Returns resource type that should be fetched given present app state.
  var currentResourceType: ResourceType {
    if let currentTheme = Preferences.NewTabPage.selectedCustomTheme.value {
      return .superReferral(code: currentTheme)
    }

    if let retryDeadline = Preferences.NewTabPage.superReferrerThemeRetryDeadline.value,
      let refCode = Preferences.URP.referralCode.value {

      if Date() < retryDeadline {
        return .superReferral(code: refCode)
      }
    }

    return .sponsor
  }

  /// Folder where custom favicons are stored.
  static let faviconOverridesDirectory = "favorite_overrides"
  /// For each favicon override, there should be a file that contains info of what background color to use.
  static let faviconOverridesBackgroundSuffix = ".background_color"

  private static let etagFile = "crc.etag"
  private var timer: Timer?
  private var backgroundObserver: NSObjectProtocol?
  private var foregroundObserver: NSObjectProtocol?

  weak var delegate: NTPDownloaderDelegate?

  deinit {
    self.removeObservers()
  }

  func preloadCustomTheme() {
    guard let themeId = Preferences.NewTabPage.selectedCustomTheme.value else { return }
    let customTheme = loadNTPResource(for: .superReferral(code: themeId)) as? CustomTheme

    delegate?.preloadCustomTheme(theme: customTheme)
  }

  private func getNTPResource(for type: ResourceType) async throws -> NTPThemeable? {
    // Load from cache because the time since the last fetch hasn't expired yet..
    if let nextDate = Preferences.NTP.ntpCheckDate.value,
      Date().timeIntervalSince1970 - nextDate < 0 {

      if self.timer == nil {
        let relativeTime = abs(Date().timeIntervalSince1970 - nextDate)
        self.scheduleObservers(relativeTime: relativeTime)
      }

      return loadNTPResource(for: type)
    }

    // Download the NTP resource to a temporary directory
    do {
      let (url, cacheInfo) = try await downloadMetadata(type: type)
      // Start the timer no matter what..
      startNTPTimer()

      if let cacheInfo = cacheInfo, cacheInfo.statusCode == 304 {
        logger.debug("NTPDownloader Cache is still valid")
        return loadNTPResource(for: type)
      }

      guard let url = url else {
        logger.error("Invalid NTP Temporary Downloads URL")
        return loadNTPResource(for: type)
      }

      // Move contents of `url` directory
      // to somewhere more permanent where we'll load the images from..
      guard let saveLocation = type.saveLocation else { throw "Can't find location to save" }

      try FileManager.default.createDirectory(at: saveLocation, withIntermediateDirectories: true, attributes: nil)

      if FileManager.default.fileExists(atPath: saveLocation.path) {
        try FileManager.default.removeItem(at: saveLocation)
      }

      try FileManager.default.moveItem(at: url, to: saveLocation)

      // Store the ETag
      if let cacheInfo = cacheInfo {
        setETag(cacheInfo.etag, type: type)
      }
    } catch {
      // Start the timer no matter what..
      startNTPTimer()

      if case .campaignEnded = error as? NTPError {
        do {
          try removeCampaign(type: type)
        } catch {
          logger.error(error)
        }
        return nil
      }

      if let error = (error as? NTPError)?.underlyingError() {
        logger.error(error)
      }
    }

    return loadNTPResource(for: type)
  }

  func notifyObservers(for type: ResourceType) {
    Task {
      do {
        let item = try await getNTPResource(for: type)
        switch type {
        case .superReferral(let code):
          if item == nil {
            // Even if referral is nil we stil want to call this code
            // to trigger side effects of theme update function.
            self.delegate?.onThemeUpdated(theme: item as? CustomTheme)
            return
          }

          self.delegate?.onThemeUpdated(theme: item as? CustomTheme)
          Preferences.NewTabPage.selectedCustomTheme.value = code
          Preferences.NewTabPage.superReferrerThemeRetryDeadline.value = nil
        case .sponsor:
          self.delegate?.onSponsorUpdated(sponsor: item as? NTPSponsor)
        }
      } catch {
        logger.error(error)
      }
    }
  }

  private func startNTPTimer() {
    let relativeTime = { () -> TimeInterval in
      if !AppConstants.buildChannel.isPublic {
        return 3.minutes
      }

      let baseTime = 1.hours
      let minVariance = 1.10  // 10% variance
      let maxVariance = 1.14  // 14% variance
      return baseTime * Double.random(in: ClosedRange<Double>(uncheckedBounds: (lower: minVariance, upper: maxVariance)))
    }()

    Preferences.NTP.ntpCheckDate.value = Date().timeIntervalSince1970 + relativeTime
    self.scheduleObservers(relativeTime: relativeTime)
  }

  private func removeObservers() {
    self.timer?.invalidate()

    if let backgroundObserver = self.backgroundObserver {
      NotificationCenter.default.removeObserver(backgroundObserver)
    }

    if let foregroundObserver = self.foregroundObserver {
      NotificationCenter.default.removeObserver(foregroundObserver)
    }
  }

  private func scheduleObservers(relativeTime: TimeInterval) {
    let resourceType = currentResourceType

    self.removeObservers()
    self.timer = Timer.scheduledTimer(withTimeInterval: relativeTime, repeats: true) { [weak self] _ in
      self?.notifyObservers(for: resourceType)
    }

    self.backgroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
      guard let self = self else { return }
      self.timer?.invalidate()
      self.timer = nil
    }

    self.foregroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
      guard let self = self else { return }

      self.timer?.invalidate()
      self.timer = nil

      // If the time hasn't passed yet, reschedule the timer with the relative time..
      if let nextDate = Preferences.NTP.ntpCheckDate.value,
        Date().timeIntervalSince1970 - nextDate < 0 {

        let relativeTime = abs(Date().timeIntervalSince1970 - nextDate)
        self.timer = Timer.scheduledTimer(withTimeInterval: relativeTime, repeats: true) { [weak self] _ in
          self?.notifyObservers(for: resourceType)
        }
      } else {
        // Else the time has already passed so download the new data, reschedule the timers and notify the observers
        self.notifyObservers(for: resourceType)
      }
    }
  }

  private func loadNTPResource(for type: ResourceType) -> NTPThemeable? {
    do {
      let metadataFileURL = try self.ntpMetadataFileURL(type: type)
      if !FileManager.default.fileExists(atPath: metadataFileURL.path) {
        return nil
      }

      let metadata = try Data(contentsOf: metadataFileURL)

      guard let downloadsFolderURL = type.saveLocation else { throw "Can't find location to save" }

      switch type {
      case .sponsor:
        if Self.isSponsorCampaignEnded(data: metadata) {
          try self.removeCampaign(type: type)
          return nil
        }

        let schema = try JSONDecoder().decode(NTPSchema.self, from: metadata)

        var campaigns: [NTPCampaign] = [NTPCampaign]()

        if let schemaCampaigns = schema.campaigns {
          campaigns.append(contentsOf: schemaCampaigns)
        }

        if let schemaWallpapers = schema.wallpapers, campaigns.isEmpty {
          /// If campaigns are not defined in the scema fallback to wallpapers
          let campaign: NTPCampaign = NTPCampaign(wallpapers: schemaWallpapers, logo: schema.logo)
          campaigns.append(campaign)
        }

        let fullPathCampaigns = campaigns.map {
          NTPCampaign(
            wallpapers: mapNTPWallpapersToFullPath($0.wallpapers, basePath: downloadsFolderURL),
            logo: mapNTPLogoToFullPath($0.logo, basePath: downloadsFolderURL))
        }

        return NTPSponsor(schemaVersion: 1, campaigns: fullPathCampaigns)
      case .superReferral(let code):
        if Self.isSuperReferralCampaignEnded(data: metadata) {
          try self.removeCampaign(type: type)
          return nil
        }

        let customTheme = try JSONDecoder().decode(CustomTheme.self, from: metadata)

        let wallpapers = mapNTPWallpapersToFullPath(customTheme.wallpapers, basePath: downloadsFolderURL)

        // At the moment we do not anything with logo for super referrals.
        let logo: NTPLogo? = nil

        return CustomTheme(
          themeName: customTheme.themeName, wallpapers: wallpapers,
          logo: logo, topSites: customTheme.topSites, refCode: code)
      }
    } catch {
      logger.error(error)
    }

    return nil
  }

  private func mapNTPWallpapersToFullPath(_ wallpapers: [NTPWallpaper], basePath: URL) -> [NTPWallpaper] {
    wallpapers.map {
      NTPWallpaper(
        imageUrl: basePath.appendingPathComponent($0.imageUrl).path, logo: $0.logo,
        focalPoint: $0.focalPoint, creativeInstanceId: $0.creativeInstanceId)
    }
  }

  private func mapNTPLogoToFullPath(_ logo: NTPLogo?, basePath: URL) -> NTPLogo? {
    guard let logo = logo else {
      return nil
    }

    return NTPLogo(
      imageUrl: basePath.appendingPathComponent(logo.imageUrl).path, alt: logo.alt,
      companyName: logo.companyName, destinationUrl: logo.destinationUrl)
  }

  private func getETag(type: ResourceType) -> String? {
    do {
      let etagFileURL = try self.ntpETagFileURL(type: type)
      if !FileManager.default.fileExists(atPath: etagFileURL.path) {
        return nil
      }

      return try? String(contentsOfFile: etagFileURL.path, encoding: .utf8)
    } catch {
      logger.error(error)
      return nil
    }
  }

  private func setETag(_ etag: String, type: ResourceType) {
    do {
      let etagFileURL = try self.ntpETagFileURL(type: type)
      try etag.write(to: etagFileURL, atomically: true, encoding: .utf8)
    } catch {
      logger.error(error)
    }
  }

  private func removeETag(type: ResourceType) throws {
    let etagFileURL = try self.ntpETagFileURL(type: type)
    if FileManager.default.fileExists(atPath: etagFileURL.path) {
      try FileManager.default.removeItem(at: etagFileURL)
    }
  }

  func removeCampaign(type: ResourceType) throws {
    try self.removeETag(type: type)
    guard let saveLocation = type.saveLocation else { throw "Can't find location to save" }

    switch type {
    case .superReferral(let code):
      Preferences.NewTabPage.selectedCustomTheme.value = nil
      // Force to download assets for regular sponsored resource on next app launch.
      Preferences.NTP.ntpCheckDate.value = nil
      var installedThemes = Preferences.NewTabPage.installedCustomThemes.value

      installedThemes.removeAll(where: { $0 == code })
      Preferences.NewTabPage.installedCustomThemes.value = installedThemes
    case .sponsor:
      break
    }

    if FileManager.default.fileExists(atPath: saveLocation.path) {
      try FileManager.default.removeItem(at: saveLocation)
    }
  }

  private func downloadMetadata(type: ResourceType) async throws -> (URL?, CacheResponse?) {
    let data: Data
    let cacheInfo: CacheResponse

    do {
      (data, cacheInfo) = try await download(
        type: type,
        path: type.resourceName,
        etag: getETag(type: type))
    } catch {
      throw NTPError.metadataError(error)
    }

    if cacheInfo.statusCode == 304 {
      return (nil, cacheInfo)
    }

    if data.isEmpty {
      throw "Invalid \(type.resourceName) for NTP Download"
    }

    switch type {
    case .sponsor:
      if Self.isSponsorCampaignEnded(data: data) {
        throw NTPError.campaignEnded
      }
    case .superReferral(_):
      if Self.isSuperReferralCampaignEnded(data: data) {
        throw NTPError.campaignEnded
      }
    }

    return (try await unpackMetadata(type: type, data: data), nil)
  }

  // MARK: - Download & Unpacking

  private func parseETagResponseInfo(_ response: HTTPURLResponse) -> CacheResponse {
    if let etag = response.allHeaderFields["Etag"] as? String {
      return CacheResponse(statusCode: response.statusCode, etag: etag)
    }

    if let etag = response.allHeaderFields["ETag"] as? String {
      return CacheResponse(statusCode: response.statusCode, etag: etag)
    }

    return CacheResponse(statusCode: response.statusCode, etag: "")
  }

  // Downloads the item at the specified url relative to the baseUrl
  private func download(type: ResourceType, path: String?, etag: String?) async throws -> (Data, CacheResponse) {
    guard var url = type.resourceBaseURL() else {
      throw "Invalid Resource Base URL"
    }

    if let path = path {
      url = url.appendingPathComponent(path)
    }

    var request = URLRequest(url: url)
    if let etag = etag {
      request.setValue(etag, forHTTPHeaderField: "If-None-Match")
    }

    let (data, response) = try await NetworkManager(session: URLSession(configuration: .ephemeral)).dataRequest(with: request)

    guard let response = response as? HTTPURLResponse else {
      throw "Response is not an HTTP Response"
    }

    if response.statusCode != 304 && (response.statusCode < 200 || response.statusCode > 299) {
      throw "Invalid Response Status Code: \(response.statusCode)"
    }

    return (data, parseETagResponseInfo(response))
  }

  // Unpacks NTPResource by downloading all of its assets to a temporary directory
  // and returning the URL to the directory
  private func unpackMetadata(type: ResourceType, data: Data) async throws -> URL {
    func decodeAndSave(type: ResourceType) throws -> (wallpapers: [NTPWallpaper], logos: [NTPLogo], topSites: [CustomTheme.TopSite]?) {
      switch type {
      case .sponsor:
        let schema = try JSONDecoder().decode(NTPSchema.self, from: data)
        let metadataFileURL = directory.appendingPathComponent(type.resourceName)
        try JSONEncoder().encode(schema).write(to: metadataFileURL, options: .atomic)

        var wallpapers: [NTPWallpaper] = [NTPWallpaper]()
        var logos: [NTPLogo] = [NTPLogo]()

        if let schemaCampaigns = schema.campaigns {
          wallpapers.append(contentsOf: schemaCampaigns.flatMap(\.wallpapers))
          logos.append(contentsOf: schemaCampaigns.compactMap(\.logo))
        }

        logos.append(contentsOf: wallpapers.compactMap(\.logo))

        if let schemaWallpapers = schema.wallpapers, wallpapers.isEmpty {
          /// If campaigns are not defined in the scema fallback to wallpapers
          wallpapers.append(contentsOf: schemaWallpapers.compactMap { $0 })
          logos.append(contentsOf: [schema.logo].compactMap { $0 })
        }

        return (wallpapers, logos, nil)
      case .superReferral:
        let item = try JSONDecoder().decode(CustomTheme.self, from: data)
        let metadataFileURL = directory.appendingPathComponent(type.resourceName)
        try JSONEncoder().encode(item).write(to: metadataFileURL, options: .atomic)
        return (item.wallpapers, [item.logo].compactMap { $0 }, item.topSites)
      }
    }

    let tempDirectory = FileManager.default.temporaryDirectory
    let directory = tempDirectory.appendingPathComponent(type.saveTopFolderName)

    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)

      let item = try decodeAndSave(type: type)

      var imagesToDownload = [String]()

      imagesToDownload.append(contentsOf: item.logos.map { $0.imageUrl })
      imagesToDownload.append(contentsOf: item.wallpapers.map { $0.imageUrl })
      imagesToDownload.append(contentsOf: item.wallpapers.compactMap { $0.logo?.imageUrl })

      try await withThrowingTaskGroup(
        of: Void.self,
        body: { group in
          imagesToDownload.forEach { itemURL in
            group.addTask {
              let (data, _) = try await self.download(type: type, path: itemURL, etag: nil)
              let file = directory.appendingPathComponent(itemURL)
              try data.write(to: file, options: .atomicWrite)
            }
          }

          if let topSites = item.topSites {
            /// For favicons we do not move them to temp directory but write directly to a folder with favicon overrides.
            guard
              let saveLocation =
                FileManager.default.getOrCreateFolder(name: NTPDownloader.faviconOverridesDirectory)
            else {
              throw "Failed to create directory for favicon overrides"
            }

            topSites.forEach { topSite in
              group.addTask {
                let (data, _) = try await self.download(type: type, path: topSite.iconUrl, etag: nil)

                let name = topSite.destinationUrl.toBase64()
                // FIXME: this saves even if error, should move to temp dir, and then move
                let file = saveLocation.appendingPathComponent(name)
                try data.write(to: file, options: .atomicWrite)

                let topSiteBackgroundColorFileName =
                  name + NTPDownloader.faviconOverridesBackgroundSuffix
                let topSiteBackgroundColorURL = saveLocation.appendingPathComponent(topSiteBackgroundColorFileName)

                try topSite.backgroundColor.write(
                  to: topSiteBackgroundColorURL,
                  atomically: true, encoding: .utf8)
              }
            }
          }
        })
      return directory
    } catch {
      throw NTPError.unpackError(error)
    }
  }

  private func ntpETagFileURL(type: ResourceType) throws -> URL {
    guard let saveLocation = type.saveLocation else { throw "Can't find location to save" }
    return saveLocation.appendingPathComponent(NTPDownloader.etagFile)
  }

  private func ntpMetadataFileURL(type: ResourceType) throws -> URL {
    guard let saveLocation = type.saveLocation else { throw "Can't find location to save" }
    return saveLocation.appendingPathComponent(type.resourceName)
  }

  static func isSponsorCampaignEnded(data: Data) -> Bool {
    var hasWallpapers = false
    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
      let wallpapers = json["wallpapers"] as? [[String: Any]],
      wallpapers.count > 0 {
      hasWallpapers = true
    }

    var hasCampaigns = false
    if let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
      let campaigns = json["campaigns"] as? [[String: Any]],
      campaigns.count > 0 {
      hasCampaigns = true
    }

    if !hasWallpapers && !hasCampaigns {
      return true
    }

    return false
  }

  static func isSuperReferralCampaignEnded(data: Data) -> Bool {
    guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
      let wallpapers = json["wallpapers"] as? [[String: Any]],
      wallpapers.count > 0
    else {
      return true
    }

    return false
  }

  private struct CacheResponse {
    let statusCode: Int
    let etag: String
  }

  private enum NTPError: Error {
    case campaignEnded
    case metadataError(Error)
    case unpackError(Error)
    case loadingError(Error)

    func underlyingError() -> Error? {
      switch self {
      case .campaignEnded:
        return nil

      case .metadataError(let error),
        .unpackError(let error),
        .loadingError(let error):
        return error
      }
    }
  }
}
