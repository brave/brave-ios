// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Static
import BraveShared
import Shared
import BraveCore
import BraveUI

class AppearanceDetailsViewController: TableViewController {
  typealias SelectedThemeChanged = (DefaultTheme) -> Void

  private let themeOptions: [DefaultTheme]
  
  private let themeChanged: SelectedThemeChanged
  private let nightModeEnabled: (Bool) -> Void
  private let autoNightModeEnabled: (Bool) -> Void

  private var selectedTheme: DefaultTheme {
    didSet {
      themeChanged(selectedTheme)
    }
  }

  init(themeChanged: @escaping SelectedThemeChanged, nightModeEnabled: @escaping (Bool) -> Void, autoNightModeEnabled: @escaping (Bool) -> Void) {
    self.themeOptions = DefaultTheme.normalThemesOptions
    selectedTheme = DefaultTheme(rawValue: Preferences.General.themeNormalMode.value) ?? .system
    
    self.themeChanged = themeChanged
    self.nightModeEnabled = nightModeEnabled
    self.autoNightModeEnabled = autoNightModeEnabled
    
    super.init(style: .insetGrouped)
  }

  public override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .braveGroupedBackground
    view.tintColor = .braveOrange
    
    loadSections()

    Preferences.General.nightModeEnabled.observe(from: self)
  }

  @available(*, unavailable)
  required init?(coder aDecoder: NSCoder) {
    fatalError()
  }

  private func updateRowsForSelectedOption() {
    for (index, option) in themeOptions.enumerated() {
      if option.key == selectedTheme.key {
        dataSource.sections[0].rows[index].accessory = .checkmark
      } else {
        dataSource.sections[0].rows[index].accessory = .none
      }
    }
  }
  
  public func loadSections() {
    let appearanceSection = Section(
      header: .title(Strings.themesDisplayBrightness),
      rows: themeOptions.map { option in
        Row(
          text: option.displayString,
          selection: { [unowned self] in
            // Update selected option
            self.selectedTheme = option
            self.updateRowsForSelectedOption()
          },
          image: option.image,
          accessory: option == selectedTheme ? .checkmark : .none)
      },
      footer: .title(Strings.themesDisplayBrightnessFooter)
    )
    
    var nightModeSection = Section(
      header: .title(Strings.NightMode.sectionTitle.uppercased()),
      rows: [
        .boolRow(
          title: Strings.NightMode.settingsTitle,
          detailText: Strings.NightMode.settingsDescription,
          option: Preferences.General.nightModeEnabled,
          onValueChange: { [unowned self] enabled in
            self.nightModeEnabled(enabled)
          },
          image: UIImage(systemName: "moon"))
      ],
      footer: .title(Strings.NightMode.sectionDescription)
    )
    
    if Preferences.General.nightModeEnabled.value {
      nightModeSection.rows.append(
        .boolRow(
          title: Strings.NightMode.autoModeSettingsTitle,
          detailText: Strings.NightMode.autoModeSettingsDescription,
          option: Preferences.General.automaticNightModeEnabled,
          onValueChange: { [unowned self] enabled in
            self.autoNightModeEnabled(enabled)
          })
      )
    }

    dataSource.sections = [appearanceSection, nightModeSection]
  }
}

extension AppearanceDetailsViewController: PreferencesObserver {
  func preferencesDidChange(for key: String) {
    loadSections()
  }
}
