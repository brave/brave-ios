egrep --exclude-dir={ThirdParty,Carthage,fastlane,L10nSnapshotTests,l10n} --include=\*.swift -nR "NSLocalizedString(.*[\n]*)" . > localizedStringLocations.txt
