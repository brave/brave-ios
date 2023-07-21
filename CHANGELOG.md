# Changelog


## [1.51](https://github.com/brave/brave-ios/releases/tag/v1.51)

### Web3

- Added network icons to be shown for native assets. ([#7123](https://github.com/brave/brave-ios/issues/7123))
- Implemented Market tab in Brave Wallet. ([#7202](https://github.com/brave/brave-ios/issues/7202))
- Implemented NFT tab in Brave Wallet. ([#7173](https://github.com/brave/brave-ios/issues/7173))
- Updated label for "Reset and clear wallet data" under Wallet settings. ([#7337](https://github.com/brave/brave-ios/issues/7337))
- Fixed Ethereum DApp error response formatting. ([#7392](https://github.com/brave/brave-ios/issues/7392))

### General

- Added VPN region selector in the main menu. ([#7380](https://github.com/brave/brave-ios/issues/7380))
- Added VPN Protocol options in VPN settings. ([#7255](https://github.com/brave/brave-ios/issues/7255))
- Implemented built-in find-in-page controls on iOS 16 or higher. ([#7238](https://github.com/brave/brave-ios/issues/7238))
- Implemented optimizations for popover callout logic. ([#5981](https://github.com/brave/brave-ios/issues/5981))
- Removed “Blocklists Anti-porn list” from filter lists. ([#7278](https://github.com/brave/brave-ios/issues/7278))
- Removed “Block Phishing and Malware” toggle from Brave Shields. ([#7373](https://github.com/brave/brave-ios/issues/7373))
- Moved “Block Popups” toggle to General settings menu. ([#7247](https://github.com/brave/brave-ios/issues/7247))
- Updated copy for Rewards settings and Rewards Internals. ([#7221](https://github.com/brave/brave-ios/issues/7221))
- Updated session restore to use Webkit’s session restore. ([#7166](https://github.com/brave/brave-ios/issues/7166))
- Updated “Sync playlist folders automatically” to be enabled by default in Playlist settings. ([#7293](https://github.com/brave/brave-ios/issues/7293))
- Improved parsing for headers to be case-insensitive. ([#7394](https://github.com/brave/brave-ios/issues/7394))
- Resolved blank screen issue when launching browser. ([#6444](https://github.com/brave/brave-ios/issues/6444))
- Fixed incorrect reporting of connection protocol when visiting HTTP websites. ([#7403](https://github.com/brave/brave-ios/issues/7403))
- Fixed crash when using long-press while scrolling in Tab View. ([#7397](https://github.com/brave/brave-ios/issues/7397))
- Fixed tabs from losing their order when being restored or restored as blank screen. ([#7366](https://github.com/brave/brave-ios/issues/7366))
- Fixed tabs from not restoring properly. ([#7303](https://github.com/brave/brave-ios/issues/7303))
- Fixed colors being inverted on [presearch.com](http://presearch.com/) in Dark Mode. ([#7229](https://github.com/brave/brave-ios/issues/7229)) 
- Fixed CSS transitions not being animated. ([#7224](https://github.com/brave/brave-ios/issues/7224))
- Fixed shields panel showing session restore data with reader mode enabled. ([#7103](https://github.com/brave/brave-ios/issues/7103))
- Fixed "show more” under recent searches being cut off in some languages. ([#6824](https://github.com/brave/brave-ios/issues/6824))

## [1.50](https://github.com/brave/brave-ios/releases/tag/v1.50)

### Web3

- Added support for opening ipns:// scheme URL from other apps. ([#7227](https://github.com/brave/brave-ios/issues/7227))
- Added domain resolution support for Unstoppable Domains. ([#7089](https://github.com/brave/brave-ios/issues/7089))
- Added support for IPFS Navigation in omnibox. ([#7013](https://github.com/brave/brave-ios/issues/7013))
- Added checksum validation of addresses on the "Send" screen in Brave Wallet. ([#7136](https://github.com/brave/brave-ios/issues/7136))

### General

- Added Brave News Widgets feature for home screen and lock screen. ([#7168](https://github.com/brave/brave-ios/issues/7168))
- Added capability to add custom filter lists. ([#6841](https://github.com/brave/brave-ios/issues/6841))
- Added support for scriptlets using uBlock Origin format. ([#7194](https://github.com/brave/brave-ios/issues/7194))
- Added "Never Saved" section in Logins & Passwords Page when syncing passwords. ([#6991](https://github.com/brave/brave-ios/issues/6991))
- Blocked Playlist from appearing in menu and URL bar when using Brave Talk. ([#7213](https://github.com/brave/brave-ios/issues/7213))
- Enhanced Brave VPN to use WireGuard protocol by default. ([#6646](https://github.com/brave/brave-ios/issues/6646))
- Improved caching for VPN SKU credentials. ([#7196](https://github.com/brave/brave-ios/issues/7196))
- Improved load time for adblock filter lists. ([#7147](https://github.com/brave/brave-ios/issues/7147))
- Improved storage management when re-launching the browser. ([#7114](https://github.com/brave/brave-ios/issues/7114))
- Fixed crash with adblock engine/cosmetic filters. ([#6254](https://github.com/brave/brave-ios/issues/6254))
- Fixed crash for Playlist when entering picture-in-picture mode. ([#7347](https://github.com/brave/brave-ios/issues/7347))
- Fixed issue causing Playlist to play a short chime instead of the actual video that was added. ([#7345](https://github.com/brave/brave-ios/issues/7345))
- Fixed flickering or low resolution favicon in Playlist and on New Tab Page. ([#7271](https://github.com/brave/brave-ios/issues/7271))
- Fixed images/thumbnails not displaying on sites such as Mastodon and Airbnb when Brave Shields is enabled. ([#7215](https://github.com/brave/brave-ios/issues/7215))
- Fixed padding for items under "Saved Logins" section in Password Manager when syncing. ([#7197](https://github.com/brave/brave-ios/issues/7197))
- Fixed white gradient appearing on the URL bar in private mode. ([#7132](https://github.com/brave/brave-ios/issues/7132))
- Fixed favicon size on lock screen widget. ([#7124](https://github.com/brave/brave-ios/issues/7124))

## [1.49.1](https://github.com/brave/brave-ios/releases/tag/v1.49.1)

- Fixed issues with fingerprinting protection. [#7231](https://github.com/brave/brave-ios/issues/7231)
- Fixed transaction confirmation view from auto-dismissing when presented in Brave Wallet. [#7200](https://github.com/brave/brave-ios/issues/7200)

## [1.49](https://github.com/brave/brave-ios/releases/tag/v1.49)

### Web3

- Added Solana Swap integration into existing Swap UI using Jupiter as the DEX aggregator. ([#6847](https://github.com/brave/brave-ios/issues/6847))
- Added transaction submitted and transaction completed state in wallet panel. ([#6881](https://github.com/brave/brave-ios/issues/6861))
- Added UI to display "signed" status for Ethereum transactions. ([#6606](https://github.com/brave/brave-ios/issues/6606))
- Added support for sending to ENS wallet address. ([#5787](https://github.com/brave/brave-ios/issues/5787))
- Added auto-complete when entering token address for custom Solana assets. ([#6982](https://github.com/brave/brave-ios/issues/6982))
- Added support for Solana Name Service (SNS) navigation in app. ([#6706](https://github.com/brave/brave-ios/issues/6706))
- Fixed wallet issue where the Origin Password field was shown when adding Solana account. ([#7175](https://github.com/brave/brave-ios/issues/7175))
- Fixed reporting Brave Wallet usage stats. ([#7143](https://github.com/brave/brave-ios/issues/7143))
- Fixed issue adding a custom network via panel. ([#6965](https://github.com/brave/brave-ios/issues/6965))
- Fixed issue with ERC721 NFTs with different token identifiers showing incorrect balance. ([#6954](https://github.com/brave/brave-ios/issues/6954))
- Fixed crash related to loading URLs when selecting one of the on-ramp purchase options. ([#6993](https://github.com/brave/brave-ios/issues/6993))

### General

- Added support for only loading HTTP/HTTPS URLs when scanning a QR code from the URL bar. ([#6997](https://github.com/brave/brave-ios/issues/6997))
- Added capability to permanently delete sync accounts. ([#6820](https://github.com/brave/brave-ios/issues/6829))
- Added promotional callout for VPN cross-platform linking on https://account.brave.com. ([#6164](https://github.com/brave/brave-ios/issues/6164))
- Added support for selecting full page view when taking screenshots in Brave. ([#2806](https://github.com/brave/brave-ios/issues/2806))
- Dropped support for iOS 14 devices. ([#6695](https://github.com/brave/brave-ios/issues/6695))
- Fixed website favicons flickering when searching history. ([#7116](https://github.com/brave/brave-ios/issues/7116))
- Fixed issue where some playlist folders were not shown when using CarPlay. ([#7105](https://github.com/brave/brave-ios/issues/7105))
- Fixed Brave News feed not showing when following only individual sources and no channels. ([#7093](https://github.com/brave/brave-ios/issues/7093))
- Fixed Brave News feed being updated every time NTP is viewed with RSS-only sources enabled. ([#7059](https://github.com/brave/brave-ios/issues/7059))
- Fixed suppressing "open in app" dialog on Google Maps website. ([#7024](https://github.com/brave/brave-ios/issues/7024))
- Fixed an issue with cross-platform VPN configuration not being refreshed after credentials expire. ([#7014](https://github.com/brave/brave-ios/issues/7014))
- Fixed issue where full URL is shown under the shields panel. ([#6964](https://github.com/brave/brave-ios/issues/6964))
- Fixed Playlist folder reordering feature. ([#6961](https://github.com/brave/brave-ios/issues/6961))
- Fixed "Blocking Switch to App Notices" switch from being in disabled state causing "open in app" dialogs to not be suppressed on webpages. ([#6953](https://github.com/brave/brave-ios/issues/6953))
- Fixed favorites not showing in the widget. ([#6859](https://github.com/brave/brave-ios/issues/6859))
- Fixed opening ad notifications that use items-appss:// where new tab is opened but isn’t resolved. ([#6782](https://github.com/brave/brave-ios/issues/6782))
- Fixed an issue where scrolling/swiping stops on https://www.theblock.co after loading links using "Open in New Tab" option. ([#6518](https://github.com/brave/brave-ios/issues/6518))
- Fixed shields panel toggle alignment for localized German string. ([#6171](https://github.com/brave/brave-ios/issues/6171))

## [1.45.1](https://github.com/brave/brave-ios/releases/tag/v1.45.1)

 - Implemented Brave Shields to be loaded before the first tab loads. ([#6261](https://github.com/brave/brave-ios/issues/6261)) 
 - Fixed ads from being shown on YouTube videos. ([#6411](https://github.com/brave/brave-ios/issues/6411))

## [1.45](https://github.com/brave/brave-ios/releases/tag/v1.45)

 - Added dialog for blocking cookie consent banners. ([#1358](https://github.com/brave/brave-ios/issues/1358))
 - Added lock screen widgets for favorites & shortcuts for iOS 16 devices. ([#5920](https://github.com/brave/brave-ios/issues/5920))
 - Added Ramp.Network and Sardine buy support in Brave Wallet. ([#5465](https://github.com/brave/brave-ios/issues/5465))
 - Added currency selector for "Buy" tokens in Brave Wallet. ([#6032](https://github.com/brave/brave-ios/issues/6032))
 - [Security] Added additional password protection for Brave Wallet backup seed. ([#5882](https://github.com/brave/brave-ios/issues/5882))
 - [Security] Added additional password protection when revealing Brave Wallet private keys. ([#5881](https://github.com/brave/brave-ios/issues/5881))
 - [Security] Added additional password protection for Brave Wallet account removal. ([#5967](https://github.com/brave/brave-ios/issues/5967))
 - [Security] Fixed reader mode crash on visiting certain pages as reported on Hackerone by dogeshark. ([#6137](https://github.com/brave/brave-ios/issues/6137))
 - Updated logic for user rating prompt. ([#5722](https://github.com/brave/brave-ios/issues/5722))
 - Fixed bottom toolbar from not showing when on-screen keyboard is dismissed when focus is set on URL bar. ([#6259](https://github.com/brave/brave-ios/issues/6259))

## [1.42](https://github.com/brave/brave-ios/releases/tag/v1.42)

- Added Solana support for account creation, sending SOL and sending SPL tokens with Brave Wallet. ([#5716](https://github.com/brave/brave-ios/issues/5716))
- Added support for Dynamic Type on the URL bar & toolbar enhancement. ([#5683](https://github.com/brave/brave-ios/issues/5683))
- [Security] Fixed security tokens leak as reported on HackerOne by nishimunea. ([#5859](https://github.com/brave/brave-ios/issues/5859))
- [Security] Fixed persistent user tracking via "window.cache" as reported on HackerOne by nishimunea.([#5860](https://github.com/brave/brave-ios/issues/5860))
- Implemented tapping near bottom of screen when URL bar and bottom toolbar are collapsed during page scroll. ([#5695](https://github.com/brave/brave-ios/issues/5695))
- Implemented hiding of recovery seed phrase in Brave Wallet when the app is backgrounded. ([#5744](https://github.com/brave/brave-ios/issues/5744))
- Updated placeholder text from "Send Token" screen on Brave Wallet to only mentioned of address. ([#5786](https://github.com/brave/brave-ios/issues/5786))

## [1.41.1](https://github.com/brave/brave-ios/releases/tag/v1.41.1)

- Fixed usage ping from reporting week of install as Sunday instead of Monday. ([#5750](https://github.com/brave/brave-ios/issues/5750))

## [1.41](https://github.com/brave/brave-ios/releases/tag/v1.41)

- Updated Ecosia search engine logo under search engine settings. ([#5504](https://github.com/brave/brave-ios/issues/5504))
- Updated URL bar and bottom toolbar transition during page scroll. ([#5645](https://github.com/brave/brave-ios/issues/5645))
- Fixed "Try Brave Search" button to show full text on multi-line for certain languages. ([#5644](https://github.com/brave/brave-ios/issues/5644))
- Fixed Brave Wallet panel from being shown during page reload. ([#5616](https://github.com/brave/brave-ios/issues/5616))

## [1.40](https://github.com/brave/brave-ios/releases/tag/v1.40.1)

- Implemented Get Encryption Public Key & Decrypt Requests for wallets. ([#5424](https://github.com/brave/brave-ios/issues/5424))
- Added context menu to show full account address. ([#5477](https://github.com/brave/brave-ios/issues/5477))
- Added badge to Brave Wallet URL bar icon when there is a pending request. ([#5358](https://github.com/brave/brave-ios/issues/5358))
- Fixed tab from loading YouTube home page when browser is restarted. ([#5615](https://github.com/brave/brave-ios/issues/5615))
- Fixed Reader mode to use custom fonts. ([#5553](https://github.com/brave/brave-ios/issues/5553))
- Fixed Brave Wallet to show eTLD+1 prominently in request panel. ([#5188](https://github.com/brave/brave-ios/issues/5188))
- Fixed Brave Wallet to show eTLD+1 in bold and show the full URL. ([#5534](https://github.com/brave/brave-ios/issues/5534))
- Fixed Brave Wallet to show eTLD+1 in bold on transaction confirmation screens. ([#5405](https://github.com/brave/brave-ios/issues/5405))
- Fixed Brave Wallet provider object to be only available for "https" sites. ([#5518](https://github.com/brave/brave-ios/issues/5518))
- Fixed Brave Wallet Blockie colors to match other platforms. ([#5472](https://github.com/brave/brave-ios/issues/5472))
- Fixed white screen when restoring a tab via tab tray. ([#5508](https://github.com/brave/brave-ios/issues/5508))

## [1.39.1](https://github.com/brave/brave-ios/releases/tag/v1.39.1)

- Fixed page from going into infinite redirect loop when trying to load an amp page. ([#5461](https://github.com/brave/brave-ios/issues/5461))

## [1.39](https://github.com/brave/brave-ios/releases/tag/v1.39)

- Implemented debouncing feature on iOS. ([#5225](https://github.com/brave/brave-ios/issues/5225))
- Implemented additional farbling protections for fingerprinters accessing CPU information. ([#5268](https://github.com/brave/brave-ios/issues/5268))
- Added "Force Paste" option to long press context menu. ([#5292](https://github.com/brave/brave-ios/issues/5292))
- Added ability to set default currency via Brave Wallet settings. ([#4341](https://github.com/brave/brave-ios/issues/4341))
- Fixed "Share" menu from showing up when selecting "Share Link" via "Mobile bookmarks". ([#5331](https://github.com/brave/brave-ios/issues/5331))

## [1.38](https://github.com/brave/brave-ios/releases/tag/v1.38)

- Implemented farbling & fingerprinting protections for iOS. ([#3700](https://github.com/brave/brave-ios/issues/3700))
- Implemented approval confirmation for Swaps in Brave Wallet. ([#5107](https://github.com/brave/brave-ios/issues/5107))
- Implemented transactions details view when tapped on a transaction in Brave Wallet. ([#4425](https://github.com/brave/brave-ios/issues/4425))
- Added extra validation of ETH address in send transaction screen in Brave Wallet. ([#4744](https://github.com/brave/brave-ios/issues/4744))
- Fixed rounding of token balance to show correct balance on transaction screen in Brave Wallet. ([#5247](https://github.com/brave/brave-ios/issues/5247))
- Fixed crash on clicking a recovery phrase on the seed phrase verification screen in Brave Wallet. ([#4938](https://github.com/brave/brave-ios/issues/4938))
- Fixed settings menu from staying open when a bookmark is opened in a new tab via long press on the bookmark. ([#4820](https://github.com/brave/brave-ios/issues/4820))

## [1.37](https://github.com/brave/brave-ios/releases/tag/v1.37)

- Implemented cosmetic filtering. ([#2683](https://github.com/brave/brave-ios/issues/2683)) 
- Added ability to save PDF opened in Brave via share sheet menu. ([#3323](https://github.com/brave/brave-ios/issues/3323))
- Added ability to specify custom nonce for a transaction in Brave Wallet via the settings feature in transaction confirmation panel. ([#5052](https://github.com/brave/brave-ios/issues/5052))
- Added ability to reset local transactions from Brave Wallet settings. ([#5051](https://github.com/brave/brave-ios/issues/5051))
- Fixed portfolio balance from showing incorrect balance when the same switching network multiple times in Brave Wallet. ([#5027](https://github.com/brave/brave-ios/issues/5027))

## [1.36](https://github.com/brave/brave-ios/releases/tag/v1.36)

- Added ability to add, modify and remove a custom network from Brave Wallet settings. ([#4822](https://github.com/brave/brave-ios/issues/4822))
- Added ability to swap selected tokens directly from swap screen in Brave Wallet. ([#4979](https://github.com/brave/brave-ios/issues/4979))
- Fixed Inline ads from showing up in Brave News when all sources are disabled. ([#4995](https://github.com/brave/brave-ios/issues/4995))
- Fixed displaying custom token in Swap tokens list in Brave Wallet. ([#4981](https://github.com/brave/brave-ios/issues/4981))
- Fixed displaying native currency at the top of the token list by default in Buy/Send/Swap screens in Brave Wallet. ([#4980](https://github.com/brave/brave-ios/issues/4980))

## [1.35.1](https://github.com/brave/brave-ios/releases/tag/v1.35.1)

- Fixed issue to show certificate error on restart when bypasses ignores the error and closes the browser. ([#4973](https://github.com/brave/brave-ios/issues/4973))
- Fixed app crash on devices running iOS 14. ([#4967](https://github.com/brave/brave-ios/issues/4967))

## [1.35](https://github.com/brave/brave-ios/releases/tag/v1.35)

- Implemented ability to delete site-specific data. ([#4835](https://github.com/brave/brave-ios/issues/4835))
- Deprecated Yubico SDK in favor of built-in WebAuth of WKWebView. ([#4473](https://github.com/brave/brave-ios/issues/4473))
- Restored transform-style animation to tab tray. ([#4841](https://github.com/brave/brave-ios/issues/4841))
- Fixed websites from crashing browser in certain cases when using print functionality. ([#4848](https://github.com/brave/brave-ios/issues/4848))
- Fixed token selection on Swap screen when opened via token details screen in Brave Wallet. ([#4677](https://github.com/brave/brave-ios/issues/4677))
- Fixed asset detail screen to list newly added account instantly in Brave Wallet. ([#4562](https://github.com/brave/brave-ios/issues/4562))
- Fixed padding in address bar to be symmetrical on both ends. ([#4214](https://github.com/brave/brave-ios/issues/4214))
- Fixed a crash when dragging the rewards panel. ([#4631](https://github.com/brave/brave-ios/issues/4631))
- Fixed Quick Search Engine not being shown in certain cases. ([#3959](https://github.com/brave/brave-ios/issues/3959))
- Fixed Quick Search Engine bar to appear if less than 2 quick search engines are enabled. ([#3190](https://github.com/brave/brave-ios/issues/3190))
- Fixed an issue where some page elements are not shown on page load. ([#4871](https://github.com/brave/brave-ios/issues/4871))

## [1.34.1](https://github.com/brave/brave-ios/releases/tag/v1.34.1)

- Implemented ERC20 Token Swap hardening against future 0x API changes. ([#4886](https://github.com/brave/brave-ios/issues/4886))

## [1.34](https://github.com/brave/brave-ios/releases/tag/v1.34)

- Added support for initial set of Brave Widgets. ([#4329](https://github.com/brave/brave-ios/issues/4329))
- Removed older Canvas Fingerprinting protection implementation which was causing web compat issues. ([#4522](https://github.com/brave/brave-ios/issues/4522))
- Implemented "Login & Passwords" feature for managing saved credentials. ([#4112](https://github.com/brave/brave-ios/issues/4112))
- [Security] Fixed reader mode issue as reported on HackerOne by nishimunea. ([#4772](https://github.com/brave/brave-ios/issues/4772))
- [Security] Fixed message token handling as reported on HackerOne by nishimunea. ([#4775](https://github.com/brave/brave-ios/issues/4775))
- [Security] Added "no-referrer" for content for all internal pages as reported on HackerOne by nishimunea. ([#4784](https://github.com/brave/brave-ios/issues/4784))
- Fixed Wallet page indicator width on portfolio screen. ([#4586](https://github.com/brave/brave-ios/issues/4586))

## [1.33](https://github.com/brave/brave-ios/releases/tag/v1.33)

- Added first steps of Brave Wallet (Dapps and EVM support in future releases).([#4837](https://github.com/brave/brave-ios/issues/4837))
- Implemented drag-and-drop option to rearrange favorites on New Tab Page. ([#3713](https://github.com/brave/brave-ios/issues/3713))
- Improved auto-fill of saved credentials on websites. ([#4113](https://github.com/brave/brave-ios/issues/4113))
- Implemented time-limited sync QR codes. ([#4534](https://github.com/brave/brave-ios/issues/4534))
- Fixed last active tab not being focused when closing and relaunching the browser. ([#736](https://github.com/brave/brave-ios/issues/736))
- Fixed searching on opened PDF's within Brave not working in certain cases. ([#3312](https://github.com/brave/brave-ios/issues/3312))
- Fixed PDF tab from showing blank when opening tab-tray and re-selecting the PDF tab. ([#3534](https://github.com/brave/brave-ios/issues/3534))
- Fixed auto-fill issue on certain Japanese websites. ([#4483](https://github.com/brave/brave-ios/issues/4483))
- Disabled Brave Shields from opening on new tab page. ([#4660](https://github.com/brave/brave-ios/issues/4660))

## [1.32.3](https://github.com/brave/brave-ios/releases/tag/v1.32.3)

- Replaced Brave's HTTPSE with Apple's HTTPS upgrades in WKWebView and removed Brave HTTPSE setting from shields, still available as an option in global settings. ([#4335](https://github.com/brave/brave-ios/issues/4335))
- Updated designs for error and interstitial pages. ([#4338](https://github.com/brave/brave-ios/issues/4338))
- Fixed crash when closing Brave via the app switcher. ([#4490](https://github.com/brave/brave-ios/issues/4490))

## [1.32.2](https://github.com/brave/brave-ios/releases/tag/v1.32.2)

- [Security] Clarified sync setup instructions. ([#4470](https://github.com/brave/brave-ios/issues/4470))

## [1.32.1](https://github.com/brave/brave-ios/releases/tag/v1.32.1)

- Added CarPlay support for Brave Playlist. ([#3673](https://github.com/brave/brave-ios/issues/3673))
- Added a new section in browsing history for entries older than last month. ([#4040](https://github.com/brave/brave-ios/issues/4040))
- Added support for sharing playlist items. ([#4191](https://github.com/brave/brave-ios/issues/4191))
- Added an option to disable "Add to playlist" button in toolbar. ([#4234](https://github.com/brave/brave-ios/issues/4234))
- Implemented "Bookmark all tabs" feature. ([#4132](https://github.com/brave/brave-ios/issues/4132))
- Updated default browser notification to display device's iOS version. ([#3899](https://github.com/brave/brave-ios/issues/3899))
- [Security] Fixed address bar spoofing via interstitial content as reported on HackerOne by dogeshark. ([#4396](https://github.com/brave/brave-ios/issues/4396))
- Fixed app freeze when enabling rewards. ([#3941](https://github.com/brave/brave-ios/issues/3941))
- Fixed black screen on tabs when launching Brave app. ([#4190](https://github.com/brave/brave-ios/issues/4190))
- Removed "Favorites" title when there are no favorites on New Tab Page. ([#4128](https://github.com/brave/brave-ios/issues/4128))


## [1.32](https://github.com/brave/brave-ios/releases/tag/v1.32)

- Updated default search engine to "Brave Search" for selected regions on new install. ([#4221](https://github.com/brave/brave-ios/issues/4221))
- Fixed issue where tabs appear blank and URL is not shown when browser is restarted after visiting certain sites. ([#4301](https://github.com/brave/brave-ios/issues/4301))

## [1.31.1](https://github.com/brave/brave-ios/releases/tag/v1.31.1)

- Updated user agent for devices running iOS 15. ([#4230](https://github.com/brave/brave-ios/issues/4230))
- Fixed "Create PDF" action button in menu. ([#4193](https://github.com/brave/brave-ios/issues/4193))
- Fixed app freeze on iOS 13 devices when setting focus on the URL bar. ([#4200](https://github.com/brave/brave-ios/issues/4200))
- Fixed reader mode bug where wrong content is shown when reader mode is enabled. ([#4208](https://github.com/brave/brave-ios/issues/4208))

## [1.31](https://github.com/brave/brave-ios/releases/tag/v1.31)

- Added auto-play settings for sites to auto-play video/audio. ([#1738](https://github.com/brave/brave-ios/issues/1738))
- Added "Scan QR Code" shortcut when long pressed on Brave on home-screen. ([#3798](https://github.com/brave/brave-ios/issues/3798))
- Added new playlist URL button and menu notification icon. ([#3976](https://github.com/brave/brave-ios/issues/3976))
- Added support for background playback and picture-in-picture (PiP) support for videos. ([#4031](https://github.com/brave/brave-ios/issues/4031))
- Added support for IPv6 address resolution. ([#3866](https://github.com/brave/brave-ios/issues/3866))
- Updated "Brave Search beta" to "Brave Search" under search engines and on the on-boarding screen. ([#4049](https://github.com/brave/brave-ios/issues/4049))
- Updated settings for playlist menu notification. ([#4098](https://github.com/brave/brave-ios/issues/4098))
- Fixed preview URLs always showing in lowercase. ([#3901](https://github.com/brave/brave-ios/issues/3901))
- Fixed shields stats not updating in certain cases. ([#4021](https://github.com/brave/brave-ios/issues/4021))
- Fixed share menu only sharing the canonical (base) URL instead of the actual page URL. ([#4071](https://github.com/brave/brave-ios/issues/4071))
- Fixed Brave crashing in certain cases when history sync is enabled. ([#4073](https://github.com/brave/brave-ios/issues/4073))
- Fixed issue when returning search results instead of computing arithmetic queries typed into the URL bar. ([#4081](https://github.com/brave/brave-ios/issues/4081))
- Fixed links not marked as visited when revisiting a search link via "Open in Brave". ([#4082](https://github.com/brave/brave-ios/issues/4082))
- Fixed issue where audio continues to play on tab when opening and closing the settings menu. ([#4092](https://github.com/brave/brave-ios/issues/4092))
- Fixed playlist playback speed when playing in background. ([#4102](https://github.com/brave/brave-ios/issues/4102))
- Fixed issue with playlist where it continues to play even after removing the item from playlist. ([#4129](https://github.com/brave/brave-ios/issues/4129))
- Fixed tab appearing black when the subsequent tab is closed. ([#4149](https://github.com/brave/brave-ios/issues/4149))

## [1.30.1](https://github.com/brave/brave-ios/releases/tag/v1.30.1)

- Reordered "Pull-to-Refresh" setting position to be above "Set default browser" option for iOS 14 devices. ([#4045](https://github.com/brave/brave-ios/issues/4045))
- Fixed previously viewed websites from being displayed in the tab webView when opening or closing a tab via the tab tray. ([#4019](https://github.com/brave/brave-ios/issues/4019))

## [1.30](https://github.com/brave/brave-ios/releases/tag/v1.30)

- Implemented History Sync. ([#3227](https://github.com/brave/brave-ios/issues/3227))
- Added display ads to the Brave News feed. ([#3872](https://github.com/brave/brave-ios/issues/3872))
- Added "Delete All" functionality to clear history via history page. ([#3723](https://github.com/brave/brave-ios/issues/3723))
- Added ability to share selected text from other apps to Brave via share sheet. ([#3863](https://github.com/brave/brave-ios/issues/3863))
- Fixed an issue with rewards not being disabled when toggling off via rewards panel. ([#3591](https://github.com/brave/brave-ios/issues/3591))
- Fixed app theme issue at launch, being set to light mode, when Private Browsing only mode is enabled. ([#3936](https://github.com/brave/brave-ios/issues/3936))
- Fixed menu to auto-close when a bookmark is selected. ([#3950](https://github.com/brave/brave-ios/issues/3950))
- Fixed "Clear private data" global settings from resetting to defaults when menu is closed after changing the settings. ([#3958](https://github.com/brave/brave-ios/issues/3958))
- Fixed crash when editing/deleting favorites when focus is set on URL (show more mode). ([#3974](https://github.com/brave/brave-ios/issues/3974))

## [1.29](https://github.com/brave/brave-ios/releases/tag/v1.29)

 - Added Siri Shortcuts. ([#2227](https://github.com/brave/brave-ios/issues/2227))
 - Added Pull-to-Refresh functionality. ([#916](https://github.com/brave/brave-ios/issues/916))
 - Added brave://search URL scheme support. ([#627](https://github.com/brave/brave-ios/issues/627))
 - Updated custom browser PIN feature to use users native device authentication instead. ([#3921](https://github.com/brave/brave-ios/issues/3921))
 - Updated adblock-rust library to support new DAT format. ([#3848](https://github.com/brave/brave-ios/issues/3848))
 - Updated URLs for custom top tiles for the Japan region. ([#3568](https://github.com/brave/brave-ios/issues/3568))
 - Improved Playlist performance. ([#3855](https://github.com/brave/brave-ios/issues/3855))
 - Improved progress bar reactivity when loading pages. ([#3892](https://github.com/brave/brave-ios/issues/3892))
 - Fixed favicon crash in certain cases. ([#3868](https://github.com/brave/brave-ios/issues/3868))
 - Fixed custom search URLs being capped at 150 characters. ([#3914](https://github.com/brave/brave-ios/issues/3914))
 - Fixed memory performance issues when re-opening new tabs in certain cases. ([#3867](https://github.com/brave/brave-ios/issues/3867))
 - Fixed setting toggles not persisting when scrolling away from changed settings. ([#3543](https://github.com/brave/brave-ios/issues/3543))
 - Fixed add search button not resizing correctly when moving between text fields. ([#3735](https://github.com/brave/brave-ios/issues/3735))
 - Fixed on-screen keyboard overlapping quick search bar in certain cases. ([#3688](https://github.com/brave/brave-ios/issues/3688))
 - Fixed % characters not being parsed correctly in certain cases. ([#3865](https://github.com/brave/brave-ios/issues/3865))

## [1.28](https://github.com/brave/brave-ios/releases/tag/v1.28)

- Added switch app alert message to be shown when clicking on telephone numbers. ([#3361](https://github.com/brave/brave-ios/issues/3361))
- Fixed menu to open in full when settings is opened. ([#3779](https://github.com/brave/brave-ios/issues/3779))
- Fixed bookmarks from being hidden behind the bottom toolbar. ([#3788](https://github.com/brave/brave-ios/issues/3788))
- Fixed Private browsing disclaimer text to reflect as Wi-Fi. ([#3794](https://github.com/brave/brave-ios/issues/3794))
- Fixed long search queries to be truncated to show search engine details. ([#3815](https://github.com/brave/brave-ios/issues/3815))
- Fixed menu position to be easily dismissed when VoiceOver is active. ([#3838](https://github.com/brave/brave-ios/issues/3838))
- Fixed quick search engine overlay to only scroll horizontally. ([#3843](https://github.com/brave/brave-ios/issues/3843))
- Fixed browser crash when long pressed on a visited site in search overlay. ([#3853](https://github.com/brave/brave-ios/issues/3853))
- Fixed browser crash when dragging favorites beyond the favorites list. ([#3879](https://github.com/brave/brave-ios/issues/3879))

## [1.27.1](https://github.com/brave/brave-ios/releases/tag/v1.27.1)

- Added Brave Search beta to the list of available search engines. ([#3745](https://github.com/brave/brave-ios/issues/3745))
- Added Search Overlay. ([#3554](https://github.com/brave/brave-ios/issues/3554))
- Added QR code scanner to the URL bar. ([#3399](https://github.com/brave/brave-ios/issues/3675))
- Added support for better Playlist video scrolling. ([#3675](https://github.com/brave/brave-ios/issues/3399))
- Renamed Brave Today to Brave News. ([#3736](https://github.com/brave/brave-ios/issues/3736))
- Updated User Agent to 14.6. ([#3647](https://github.com/brave/brave-ios/issues/3647))
- Improved visibility of “Share with...” by increasing the height of the settings menu. ([#3763](https://github.com/brave/brave-ios/issues/3763))
- Fixed reader mode unavailable when “Blocked Scripts” has been enabled. ([#3256](https://github.com/brave/brave-ios/issues/3256))
- Fixed “Find in Page” not working when “Blocked Scripts” has been enabled. ([#2968](https://github.com/brave/brave-ios/issues/2968))
- Fixed Playlist losing current video position when moving Brave to background. ([#3650](https://github.com/brave/brave-ios/issues/3650))

## [1.26](https://github.com/brave/brave-ios/releases/tag/v1.26)

- Added support for Auto-Close Tabs. ([#1514](https://github.com/brave/brave-ios/issues/1514))
- Added ability to disable long press to add media into playlist via the “Playlist” settings. ([#3670](https://github.com/brave/brave-ios/issues/3670))
- Added Playlist support for https://odysee.com. ([#3663](https://github.com/brave/brave-ios/issues/3663))
- Added Playlist support for https://www.listennotes.com. ([#3726](https://github.com/brave/brave-ios/issues/3726))
- Added a new tab tutorial page on startup for Japan region. ([#3389](https://github.com/brave/brave-ios/issues/3389))
- Updated settings menu to display scrollable modal which will allow for more dynamic actions. ([#3491](https://github.com/brave/brave-ios/issues/3491))
- Updated Startpage icon under onboarding and search engine settings. ([#3584](https://github.com/brave/brave-ios/issues/3584))
- [Security] Fixed cookie persistence via download request in private mode as reported on Bugzilla by Muneaki Nishimura. ([#2984](https://github.com/brave/brave-ios/issues/2984))
- [Security] Fixed cross-site scripting issue in RSS feed as reported on HackerOne by Muneaki Nishimura. ([#3630](https://github.com/brave/brave-ios/issues/3630))
- Improved readability of text under “Brave Shields & Privacy” settings by reducing font weight. ([#3180](https://github.com/brave/brave-ios/issues/3180))
- Fixed playlist videos appearing under “Downloaded Videos” via iOS storage settings. ([#3633](https://github.com/brave/brave-ios/issues/3633))
- Fixed memory leak when restoring tabs. ([#1086](https://github.com/brave/brave-ios/issues/1086))
- Fixed PIN not being removed from keychain when re-installing Brave. ([#3598](https://github.com/brave/brave-ios/issues/3598))
- Fixed crash when opening certain PDFs. ([#3572](https://github.com/brave/brave-ios/issues/3572))
- Fixed audio continuing to play after tab has already been closed in certain cases. ([#3544](https://github.com/brave/brave-ios/issues/3544))
- Fixed Brave News feed state is retained when source is removed and re-added. ([#3468](https://github.com/brave/brave-ios/issues/3468))
- Fixed moving between text fields causes search button to be hidden. ([#3454](https://github.com/brave/brave-ios/issues/3454))
- Fixed “Trackers & ads blocked on this page” tooltip being displayed when tab tray is opened in certain cases. ([#3461](https://github.com/brave/brave-ios/issues/3461))
- Fixed incorrect link being used when using “Share” in certain cases. ([#3246](https://github.com/brave/brave-ios/issues/3246))
- Fixed “Cancel” button next to URL bar not being completely dismissed in certain cases. ([#2925](https://github.com/brave/brave-ios/issues/2925))
- Fixed “History” window using incorrect theme under private tab when empty. ([#3719](https://github.com/brave/brave-ios/issues/3719))
- Fixed theme issue when changing device theme via iOS “Control Center” while an ad notification is shown. ([#2053](https://github.com/brave/brave-ios/issues/2053))
- Fixed “Downloads”, “Bookmarks” and “History” windows not being updated when changing theme via iOS “Control Center”. ([#1722](https://github.com/brave/brave-ios/issues/1722))
- Fixed tab theme not being dynamically updated when changing theme via iOS settings and Brave theme settings is set as “Auto”. ([#1572](https://github.com/brave/brave-ios/issues/1572))
- Fixed closing private tab switches theme from dark to light. ([#1572](https://github.com/brave/brave-ios/issues/1572))
- Fixed menus and shields not being updated when switching themes via the iOS “Control Center”. ([#1506](https://github.com/brave/brave-ios/issues/1506))

## [1.25.1](https://github.com/brave/brave-ios/releases/tag/v1.25.1)

- Fixed several performance issues due to Playlist. ([#3665](https://github.com/brave/brave-ios/issues/3665))
- Fixed “Add to Brave Playlist” toast being displayed even though Playlist has been disabled. ([#3656](https://github.com/brave/brave-ios/issues/3656))
- Fixed Playlist toast being displayed when scrubbing through videos. ([#3616](https://github.com/brave/brave-ios/issues/3616))

## [1.25](https://github.com/brave/brave-ios/releases/tag/v1.25)

- Added Playlists. ([#3368](https://github.com/brave/brave-ios/issues/3368))
- Added setting for “Show Last Visited Bookmarks”. ([#3371](https://github.com/brave/brave-ios/issues/3371))
- Dropped support for iOS 12. ([#3369](https://github.com/brave/brave-ios/issues/3369))
- Updated legacy wallet transfer UI to display progress and current state of pending transfers. ([#3162](https://github.com/brave/brave-ios/issues/3162))
- Updated HTTPS Everywhere data files. ([#3358](https://github.com/brave/brave-ios/issues/3358))
- Updated themes to match Brave color palettes. ([#3482](https://github.com/brave/brave-ios/issues/3482))
- Removed educational notification for HTTPS upgrade. ([#3556](https://github.com/brave/brave-ios/issues/3556))
- Fixed context menu not being displayed when double tapping in URL input. ([#3444](https://github.com/brave/brave-ios/issues/3444))
- Fixed rewards outbound calls being made when no interaction with rewards has occurred. ([#3410](https://github.com/brave/brave-ios/issues/3410))
- Fixed tab bar theme not changing when device theme is changed via iOS control center. ([#3549](https://github.com/brave/brave-ios/issues/3549))
- Fixed duplicate text appearing on VPN subscription modal. ([#3484](https://github.com/brave/brave-ios/issues/3484))

## [1.24](https://github.com/brave/brave-ios/releases/tag/v1.24)

- Implemented opt-in for Brave Today. ([#3374](https://github.com/brave/brave-ios/issues/3374))
- Added support for OpenSearch. ([#936](https://github.com/brave/brave-ios/issues/936))
- Added server location support for Brave Firewall + VPN. ([#2934](https://github.com/brave/brave-ios/issues/2934))
- Added support to remove other devices from sync chain. ([#3195](https://github.com/brave/brave-ios/issues/3195))
- Added support for custom RSS feeds within Brave Today. ([#3249](https://github.com/brave/brave-ios/issues/3249))
- Added support for Japanese content feed of Brave Today. ([#3051](https://github.com/brave/brave-ios/issues/3051))
- Added share button in Brave Shields to increase app virality. ([#2981](https://github.com/brave/brave-ios/issues/2981))
- Added support for including New Tab Page Sponsored Image views in “Estimated pending rewards” and “Ad notifications received this month” for Brave Ads. ([#3235](https://github.com/brave/brave-ios/issues/3235))
- Added ability to control “Allow universal links to open in external apps” via “Other Privacy Settings”. ([#2119](https://github.com/brave/brave-ios/issues/2119))
- Improved visuals for YubiKey security key PIN modal. ([#2129](https://github.com/brave/brave-ios/issues/2129))
- Improved Brave Today by updating feed when publishers are removed or added. ([#3033](https://github.com/brave/brave-ios/issues/3033))
- Fixed Brave Shields educational messages being shown when shields icon not visible. ([#3412](https://github.com/brave/brave-ios/issues/3412))

## [1.23.1](https://github.com/brave/brave-ios/releases/tag/v1.23.1)

- Refactored both user scripts and content scripts to restrict web-pages interacting with content scripts. ([#2957](https://github.com/brave/brave-ios/issues/2957))
- Improved handling of incorrect Brave VPN credentials. ([#3334](https://github.com/brave/brave-ios/issues/3334))
- Improved search engine onboarding by displaying scrollbar to indicate list is scrollable. ([#3223](https://github.com/brave/brave-ios/issues/3223))

## [1.23](https://github.com/brave/brave-ios/releases/tag/v1.23)

- [Security] Fixed "about:blank" spoofing issue as reported on HackerOne by rayyanh12. ([#2952](https://github.com/brave/brave-ios/issues/2952))
- [Security] Fixed URL parsing issue with fully qualified domain name (FQDN) as reported on HackerOne by nishimunea. ([#3168](https://github.com/brave/brave-ios/issues/3168))
- Added find previous text and add new bookmark keyboard shortcuts. ([#2973](https://github.com/brave/brave-ios/issues/2973))
- Changed "HTTPS" to "Est. Data Saved" under New Tab Page. ([#2859](https://github.com/brave/brave-ios/issues/2859))
- Improved bookmark scrolling performance. ([#3071](https://github.com/brave/brave-ios/issues/3071))
- Updated User Agent to 14.3. ([#3020](https://github.com/brave/brave-ios/issues/3020))
- Updated Adblock list fetch frequency from once during startup to once every 24 hours. ([#3113](https://github.com/brave/brave-ios/issues/3113))
- Updated HTTPSE data files. ([#3122](https://github.com/brave/brave-ios/issues/3122))
- Updated New Tab Page background images. ([#3112](https://github.com/brave/brave-ios/issues/3112))
- Updated images and text under the Brave VPN intro card. ([#2933](https://github.com/brave/brave-ios/issues/2933))
- Fixed "Clear Private Data" not removing tab history from "Back" and "Forward" buttons. ([#2907](https://github.com/brave/brave-ios/issues/2907))
- Fixed Brave VPN switch not visible in the settings menu when using certain locales. ([#3012](https://github.com/brave/brave-ios/issues/3012))
- Fixed search engine not being displayed under "Quick-Search" when only a single search engine is enabled. ([#2908](https://github.com/brave/brave-ios/issues/2908))
- Fixed not being able to share PDF files with various apps such as "Books.app" and "Mail.app". ([#2961](https://github.com/brave/brave-ios/issues/2961))
- Fixed bookmarks and folders being moved to bottom of list when being edited. ([#3137](https://github.com/brave/brave-ios/issues/3137))
- Fixed search suggestion text color blinking when text is being entered into the URL bar. ([#3044](https://github.com/brave/brave-ios/issues/3044))
- Fixed incorrect Twitter icons being displayed under New Tab Page when using sponsored referral builds. ([#2722](https://github.com/brave/brave-ios/issues/2722))
- Fixed text visibility when editing favorites or bookmarks under iOS 12. ([#2644](https://github.com/brave/brave-ios/issues/2644))
- Fixed reader mode toolbar visible when reader mode disabled. ([#2649](https://github.com/brave/brave-ios/issues/2649))

## [1.22.2](https://github.com/brave/brave-ios/releases/tag/v1.22.2)

- Added the "navigator.globalPrivacyControl" property to express do-not-sell or share preference. ([#3133](https://github.com/brave/brave-ios/issues/3133))
- Updated pre-populated search engine list in certain regions. ([#3177](https://github.com/brave/brave-ios/issues/3177))
- Fixed startup database crash in certain cases. ([#3169](https://github.com/brave/brave-ios/issues/3169))
- Fixed crash when deleting bookmarks in certain cases. ([#3194](https://github.com/brave/brave-ios/issues/3194))
- Fixed crash when selecting tabs from the "Tab Manager" in certain cases. ([#3215](https://github.com/brave/brave-ios/issues/3215))

## [1.22.1](https://github.com/brave/brave-ios/releases/tag/v1.22.1)

- Fixed Brave Core/Chromium framework causing increased storage usage. ([#3099](https://github.com/brave/brave-ios/issues/3099))
- Fixed last visited bookmark view not being retained. ([#3123](https://github.com/brave/brave-ios/issues/3123))

## [1.22](https://github.com/brave/brave-ios/releases/tag/v1.22)

 - Added Brave Today news feed on the New Tab Page. ([#2863](https://github.com/brave/brave-ios/issues/2863))
 - Removed redundant rewards setting to address user confusion. ([#3009](https://github.com/brave/brave-ios/issues/3009))
 - Updated default search engine to Yandex for new installations in certain regions. ([#3022](https://github.com/brave/brave-ios/issues/3022))
 - Fixed crash when opening links from other applications while Brave set as default browser. ([#3041](https://github.com/brave/brave-ios/issues/3041))
 - Fixed crash when adding or editing bookmarks in certain cases. ([#3032](https://github.com/brave/brave-ios/issues/3032))
 - Fixed last bookmark location not being saved when revisiting bookmarks. ([#3045](https://github.com/brave/brave-ios/issues/3045))
 - Fixed URL autocomplete not suggesting saved bookmarks. ([#3034](https://github.com/brave/brave-ios/issues/3034))

## [1.20](https://github.com/brave/brave-ios/releases/tag/v1.20)

 - Added ability to set Brave as the default browser. ([#2785](https://github.com/brave/brave-ios/issues/2785))
 - Fixed YouTube failing to load the next page of videos when scrolling. ([#2810](https://github.com/brave/brave-ios/issues/2810))
 - Updated onboarding flow to inform users about one-time clipboard check on first launch. ([#2832](https://github.com/brave/brave-ios/issues/2832))
 - Updated user agent to be the same per iOS version. ([#2864](https://github.com/brave/brave-ios/issues/2864))
 - Updated text to be more clear under the VPN In-App Purchase (IAP) subscription model. ([#2747](https://github.com/brave/brave-ios/issues/2747))
 - Removed all references to USD on both the rewards panel and tips banner. ([#2829](https://github.com/brave/brave-ios/issues/2829))

## [1.19.2](https://github.com/brave/brave-ios/releases/tag/v1.19.2)

 - Implemented URL scheme handlers for both "HTTP" and "HTTPS". ([#2784](https://github.com/brave/brave-ios/issues/2784))
 - Removed Sync UI from settings. ([#2718](https://github.com/brave/brave-ios/issues/2718))

## [1.19](https://github.com/brave/brave-ios/releases/tag/v1.19)

 - Implemented "Brave Firewall + VPN". ([#2739](https://github.com/brave/brave-ios/issues/2739))
 - Updated Brave Rewards to display BAT values to three decimal places. ([#2596](https://github.com/brave/brave-ios/issues/2596))
 - Fixed favorite list not updating on New Tab Page when an existing favorite is deleted. ([#2685](https://github.com/brave/brave-ios/issues/2685))

## [1.18.1](https://github.com/brave/brave-ios/releases/tag/v1.18.1)

 - Fixed pre-roll ads being shown on YouTube videos. ([#511](https://github.com/brave/brave-ios/issues/511))
 - Fixed crash when loading favicons for bookmarks in certain cases. ([#2697](https://github.com/brave/brave-ios/issues/2697))
 - Fixed crash in certain cases when Ad-block list is updated. ([#2699](https://github.com/brave/brave-ios/issues/2699))

## [1.18](https://github.com/brave/brave-ios/releases/tag/v1.18)

 - Implemented enhancements to New Tab Page and favorites overlay. ([#2578](https://github.com/brave/brave-ios/issues/2578))
 - Implemented enhancements to favorites to use fallback monogram letters instead of low-resolution icons. ([#2579](https://github.com/brave/brave-ios/issues/2579))
 - Fixed an issue where favorites icon mismatch when they are reordered. ([#2099](https://github.com/brave/brave-ios/issues/2099))
 - Fixed New Tab Page from loading new images when switching between tabs. ([#2071](https://github.com/brave/brave-ios/issues/2071))
 - Fixed fuzzy/low-resolution favicons for favorites. ([#528](https://github.com/brave/brave-ios/issues/528))

## [1.17](https://github.com/brave/brave-ios/releases/tag/v1.17)

 - Implemented super referral improvements. ([#2539](https://github.com/brave/brave-ios/issues/2539))
 - Fixed an issue where grants were not claimed in first attempt. ([#2146](https://github.com/brave/brave-ios/issues/2146))
 - Fixed an issue where Javascript URLs should only work for bookmarklets. ([#2463](https://github.com/brave/brave-ios/issues/2463))


## [1.16.2](https://github.com/brave/brave-ios/releases/tag/v1.16.2)

 - Fixed an issue where total balance did not include old promotions in certain scenarios. ([#2556](https://github.com/brave/brave-ios/issues/2556)

## [1.16.1](https://github.com/brave/brave-ios/releases/tag/v1.16.1)

 - Implemented pagination for publisher list. ([#2529](https://github.com/brave/brave-ios/issues/2529))
 - Fixed users not receiving ad promotion due to empty public key in certain cases. ([#2536](https://github.com/brave/brave-ios/issues/2536))
 - Fixed missing estimated ads payout details. ([#2531](https://github.com/brave/brave-ios/issues/2531))
 - Fixed ads initialization between app relaunch. ([#2541](https://github.com/brave/brave-ios/issues/2541))


## [1.16](https://github.com/brave/brave-ios/releases/tag/v1.16)

 - Added support for referral background images and top sites on the New Tab Page. ([#2324](https://github.com/brave/brave-ios/issues/2324))
 - Fixed missing urlbar icons for certificate errors. ([#1963](https://github.com/brave/brave-ios/issues/1963))
 - Fixed certain websites not being classified correctly for Brave ads. ([#2444](https://github.com/brave/brave-ios/issues/2444))
 - Fixed monthly contributions panel still editable when Brave Rewards is disabled. [#2401](https://github.com/brave/brave-ios/issues/2401))
 - Fixed all tabs being destroyed when partially clearing data using "Clear Private Data". ([#2155](https://github.com/brave/brave-ios/issues/2155))
 - Fixed alignment issue in urlbar. ([#1964](https://github.com/brave/brave-ios/issues/1964))
 - Updated text from "Allow contribution to non-verified sites" to "Show non-verified sites in list" under auto-contribution settings. ([#2402](https://github.com/brave/brave-ios/issues/2402))

## [1.15.2](https://github.com/brave/brave-ios/releases/tag/v1.15.2)

 - Fixed crash on certain devices when downloading publisher list by improving load times. ([#2378](https://github.com/brave/brave-ios/issues/2477))

## [1.15.1](https://github.com/brave/brave-ios/releases/tag/v1.15.1)

 - Migrated rewards database to new code base to improve stability and performance. ([#2378](https://github.com/brave/brave-ios/issues/2378))
 - [Security] Updated Minimist package. ([#2423](https://github.com/brave/brave-ios/issues/2423))
 - Fixed claiming grant from the rewards panel not always working on the first attempt. ([#2329](https://github.com/brave/brave-ios/issues/2329))

## [1.15](https://github.com/brave/brave-ios/releases/tag/v1.15)

 - Implemented Safari / iOS User Agent. ([#2210](https://github.com/brave/brave-ios/issues/2210))
 - Added haptic feedback. ([#2283](https://github.com/brave/brave-ios/issues/2283))
 - Added detailed view of pending contributions for rewards. ([#1670](https://github.com/brave/brave-ios/issues/1670))
 - Added ability to restore individual publishers from the "Sites Excluded" list. ([#1674](https://github.com/brave/brave-ios/issues/1674))
 - Added "Open Brave Rewards Settings" under rewards settings. ([#1966](https://github.com/brave/brave-ios/issues/1966))
 - Improved New Tab Page Sponsored Images modals. ([#2363](https://github.com/brave/brave-ios/issues/2363))
 - Changed settings header from "BRAVE SHIELD DEFAULTS" to "SHIELDS DEFAULTS". ([#1196](https://github.com/brave/brave-ios/issues/1196))
 - Fixed crash when downloading New Tab Page Sponsored Images in certain cases. ([#2375](https://github.com/brave/brave-ios/issues/2375))
 - Fixed tabs opened using "window.open" not being restored when restarting Brave. ([#1397](https://github.com/brave/brave-ios/issues/1397))
 - Fixed "Claim my rewards" button under the New Tab Page Sponsored Images modal not always working on the first attempt. ([#2280](https://github.com/brave/brave-ios/issues/2280))
 - Fixed custom images not being displayed under the publisher tipping banner. ([#2164](https://github.com/brave/brave-ios/issues/2164))
 - Fixed on-screen keyboard being dismissed while typing. ([#2016](https://github.com/brave/brave-ios/issues/2016))
 - Fixed rendering glitch affecting the tab bar on iPadOS. ([#2124](https://github.com/brave/brave-ios/issues/2124))
 - Fixed spacing issues between sync text and warning message under "Enter the sync code" screen. ([#2006](https://github.com/brave/brave-ios/issues/2006))

## [1.14.3](https://github.com/brave/brave-ios/releases/tag/v1.14.3)

  - Added New Tab Page Sponsored Images. ([#2151](https://github.com/brave/brave-ios/issues/2151))
  - Disable bookmarklets in URL bar. ([#2297](https://github.com/brave/brave-ios/issues/2297))
  - Fix ads region support when calendar is set to non-default. ([#2022](https://github.com/brave/brave-ios/issues/2022))
  - Removed unverified info message for Brave verified publisher. ([#2202](https://github.com/brave/brave-ios/issues/2202))

## [1.14.2](https://github.com/brave/brave-ios/releases/tag/v1.14.2)

  - Added support for NFC authentication. ([#1609](https://github.com/brave/brave-ios/issues/1609))
  - Restore lost bookmarks and favorites during 1.12 migration experienced by a subset of users. ([#2015](https://github.com/brave/brave-ios/issues/2015))

## [1.14.1](https://github.com/brave/brave-ios/releases/tag/v1.14.1)

 - Added images to new tab page. ([#1782](https://github.com/brave/brave-ios/issues/1782))
 - Fixed wallet details not being displayed for empty wallets. ([#1852](https://github.com/brave/brave-ios/issues/1852))
 - Fixed top bar visibility when settings page is opened on iPhones with iOS 13. ([#1714](https://github.com/brave/brave-ios/issues/1714))
 - Fixed ad notification from being stacked underneath the shield and reward panels. ([#1904](https://github.com/brave/brave-ios/issues/1904))

## [1.14](https://github.com/brave/brave-ios/releases/tag/v1.14)

 - Added download preview option. ([#1467](https://github.com/brave/brave-ios/issues/1467))
 - Added user confirmation when external links try to switch apps. ([#551](https://github.com/brave/brave-ios/issues/551))
 - Added time out details for incorrect pin-code lockout. ([#443](https://github.com/brave/brave-ios/issues/443))
 - Switching to "Private Browsing Only" closes normal tabs and delete sessions. ([#580](https://github.com/brave/brave-ios/issues/580))
 - Fixed rewards button being displayed even when disabled in settings. ([#1954](https://github.com/brave/brave-ios/issues/1954))
 - Fixed browser crash when attempting to clear private data on iPadOS 13.2. ([#1951](https://github.com/brave/brave-ios/issues/1951))
 - Fixed AppStore button functionality when AppStore links are opened in the browser. ([#1941](https://github.com/brave/brave-ios/issues/1941))
 - Fixed several keyboard shortcuts when using a Bluetooth keyboard. ([#1146](https://github.com/brave/brave-ios/issues/1146))
 - Fixed force 3D Touch cursor movement in the URL bar when URL is highlighted. ([#1081](https://github.com/brave/brave-ios/issues/1081))

## [1.13](https://github.com/brave/brave-ios/releases/tag/v1.13)

 - Added Brave Rewards and Ads. ([#1920](https://github.com/brave/brave-ios/issues/1920))
 - Added new preview menu on iOS13. ([#1499](https://github.com/brave/brave-ios/issues/1499))
 - Added bookmarklet support. ([#1119](https://github.com/brave/brave-ios/issues/1119))
 - Updated text size and colors on new tab stats to match desktop. ([#1641](https://github.com/brave/brave-ios/issues/1641))
 - Updated StartPage icon. ([#1598](https://github.com/brave/brave-ios/issues/1598))
 - Fixed wrong device name being shown when tapping on sync devices. ([#1587](https://github.com/brave/brave-ios/issues/1587))
 - Fixed readability of website/tab names in dark mode. ([#1551](https://github.com/brave/brave-ios/issues/1551))
 - Fixed button border visibility under Brave Shields when using the light theme. ([#1548](https://github.com/brave/brave-ios/issues/1548))
 - Fixed missing long press context menu on image search results. ([#1547](https://github.com/brave/brave-ios/issues/1547))
 - Fixed "Download Cancelled" not visible after cancelling a download under iOS 12. ([#1516](https://github.com/brave/brave-ios/issues/1516))
 - Removed "www" from the URL bar. ([#1533](https://github.com/brave/brave-ios/issues/1533))
 - Removed Alexa top sites recommendations from showing up as search suggestions. ([#868](https://github.com/brave/brave-ios/issues/868))
 - Removed URL autocomplete while editing an existing URL. ([#807](https://github.com/brave/brave-ios/issues/807))

## [1.12.1](https://github.com/brave/brave-ios/releases/tag/v1.12.1)

 - Fixed data loss on upgrade to 1.12 under certain scenarios. ([#1554](https://github.com/brave/brave-ios/issues/1554))

## [1.12](https://github.com/brave/brave-ios/releases/tag/v1.12)

 - Added dark mode support for iOS 12 and iOS 13. ([#1493](https://github.com/brave/brave-ios/issues/1493))
 - Added onboarding experience for new users. ([#1416](https://github.com/brave/brave-ios/issues/1416))
 - Added file downloading into the Downloads folder. ([#206](https://github.com/brave/brave-ios/issues/206))
 - Added "DuckDuckGo" as default search engine for Australia/Germany/Ireland and New Zealand. ([#1451](https://github.com/brave/brave-ios/issues/1451))
 - Added URLs to 2FA modals. ([#1359](https://github.com/brave/brave-ios/issues/1359))
 - Added option in settings to enable bookmarks button beside the URL bar. ([#1391](https://github.com/brave/brave-ios/issues/1391))
 - Improved handling of truncated domains. ([#552](https://github.com/brave/brave-ios/issues/552))
 - Updated default iPad user agent to desktop from mobile. ([#1290](https://github.com/brave/brave-ios/issues/1290))
 - Updated several text strings under settings to have proper capitalization. ([#1431](https://github.com/brave/brave-ios/issues/1431))
 - Updated "Add to.." to "Add Bookmark" and "Always request desktop site" to "Request Desktop Site". ([#1453](https://github.com/brave/brave-ios/issues/1453))
 - Disabled edit mode when there are no added bookmarks. ([#882](https://github.com/brave/brave-ios/issues/882))
 - Removed empty brackets from the download popup when files are smaller than a certain size. ([#1433](https://github.com/brave/brave-ios/issues/1433))
 - Fixed denial of service vulnerability using JS. ([#87](https://github.com/brave/brave-ios/issues/87))
 - Fixed ability to access "Brave.sqlite" database from Documents folder. ([#195](https://github.com/brave/brave-ios/issues/195))
 - Fixed inability to share content with Brave using Feedly. ([#661](https://github.com/brave/brave-ios/issues/661))
 - Fixed status bar position when device is oriented to landscape mode. ([#867](https://github.com/brave/brave-ios/issues/867))
 - Fixed an issue when exiting private browsing mode causes normal tab to show blank page with an incorrect URL. ([#888](https://github.com/brave/brave-ios/issues/888))
 - Fixed PIN window not being shown in certain cases where app is minimized and brought into focus. ([#980](https://github.com/brave/brave-ios/issues/980))
 - Fixed on-screen keyboard not being displayed in certain cases when viewing PIN window. ([#1122](https://github.com/brave/brave-ios/issues/1122))
 - Fixed incorrect URL being shared with Brave on certain websites. ([#1032](https://github.com/brave/brave-ios/issues/1032))
 - Fixed new tab page not being shown in certain cases. ([#1244](https://github.com/brave/brave-ios/issues/1244))
 - Fixed source link on long press context menu on an image. ([#1266](https://github.com/brave/brave-ios/issues/1266))
 - Fixed text string capitalization on sync screen. ([#1274](https://github.com/brave/brave-ios/issues/1274))
 - Fixed tap area near the edge of Brave Shields which selected the URL. ([#1280](https://github.com/brave/brave-ios/issues/1280))
 - Fixed issue where websites can't be shared/added to bookmarks in reader mode. ([#1340](https://github.com/brave/brave-ios/issues/1340))
 - Fixed report a bug in settings not working. ([#1354](https://github.com/brave/brave-ios/issues/1354))
 - Fixed crash when using YubiKey in certain cases. ([#1388](https://github.com/brave/brave-ios/issues/1388))
 - Fixed search data being retained in private browsing in certain cases. ([#1395](https://github.com/brave/brave-ios/issues/1395))
 - Fixed modals not using the entire screen on mobile on iOS 13. ([#1414](https://github.com/brave/brave-ios/issues/1414))
 - Fixed full screen issue for video sites when viewed in desktop mode. ([#1419](https://github.com/brave/brave-ios/issues/1419))
 - Fixed crash when transitioning from portrait to landscape while context menu opened. ([#1513](https://github.com/brave/brave-ios/issues/1513))
 - Fixed "DuckDuckGo" modal not being shown on private tab when a different search engine is set during onboarding. ([#1515](https://github.com/brave/brave-ios/issues/1515))
 - Fixed an issue where tab highlight is lost when the device is locked and unlocked. ([#1526](https://github.com/brave/brave-ios/issues/1526))

## [1.11.4](https://github.com/brave/brave-ios/releases/tag/v1.11.4)

 - Added support for Adblock Rust library. ([#1442](https://github.com/brave/brave-ios/issues/1442))

## [1.11.3](https://github.com/brave/brave-ios/releases/tag/v1.11.3)

 - Added support for U2F/WebAuthn hardware security keys. ([#1406](https://github.com/brave/brave-ios/issues/1406))
 - Fixed app crash when switching from Private mode to normal mode. ([#1309](https://github.com/brave/brave-ios/issues/1309))

## [1.11](https://github.com/brave/brave-ios/releases/tag/v1.11)

 - Added quick action for New Private Tab from home screen. ([#1258](https://github.com/brave/brave-ios/issues/1258))
 - Improved video orientation on Youtube. ([#1189](https://github.com/brave/brave-ios/issues/1189))
 - Fixed passcode not being reset when resuming from background. ([#1203](https://github.com/brave/brave-ios/issues/1203))
 - Fixed browser becoming unresponsive when using print preview in certain conditions. ([#1144](https://github.com/brave/brave-ios/issues/1144))

## [1.10](https://github.com/brave/brave-ios/releases/tag/v1.10)

 - Implemented new address bar layout. ([#1134](https://github.com/brave/brave-ios/issues/1134))
 - Implemented new main menu layout. ([#1130](https://github.com/brave/brave-ios/issues/1130))
 - Added ability to "Find in page" using the URL bar. ([#1019](https://github.com/brave/brave-ios/issues/1019))
 - Added 1Password activity in share sheet. ([#948](https://github.com/brave/brave-ios/issues/948))
 - Added image titles when using long-press on images. ([#851](https://github.com/brave/brave-ios/issues/851))
 - Added privacy warning on Brave Sync code page. ([#1225](https://github.com/brave/brave-ios/issues/1225))
 - Improved swipe gesture on bookmark hanger. ([#953](https://github.com/brave/brave-ios/issues/953))
 - Improved scrolling issue on websites with sticky headers and footers. ([#631](https://github.com/brave/brave-ios/issues/631))
 - Improved icon resolution for favourites. ([#463](https://github.com/brave/brave-ios/issues/463))
 - Fixed several random crashes in certain conditions. ([#1120](https://github.com/brave/brave-ios/issues/1120))
 - Fixed "Block-all-cookies" toggle behaviour. ([#897](https://github.com/brave/brave-ios/issues/897))
 - Fixed not being able to enter passcode after lockout timer. ([#938](https://github.com/brave/brave-ios/issues/938))
 - Fixed browser failing to start on iPad Air2 in certain conditions. ([#1040](https://github.com/brave/brave-ios/issues/1040))
 - Fixed browser failing to launch when device uses Swedish as default language. ([#1111](https://github.com/brave/brave-ios/issues/1111))
 - Fixed auto-focus of a tab when a link is opened using the share sheet. ([#698](https://github.com/brave/brave-ios/issues/698))
 - Fixed missing translations when viewing introduction summary under private tab. ([#1239](https://github.com/brave/brave-ios/issues/1239))
 - Fixed webcompat issues with https://borsen.dk/ due to Brave shields. ([#1061](https://github.com/brave/brave-ios/issues/1061))
