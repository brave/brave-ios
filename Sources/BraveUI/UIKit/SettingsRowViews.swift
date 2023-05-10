// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Static
import Preferences
import UIKit
import DesignSystem
import SnapKit
import Strings

/// The same style switch accessory view as in Static framework, except will not be recreated each time the Cell
/// is configured, since it will be stored as is in `Row.Accessory.view`
public class SwitchAccessoryView: UISwitch {
  public typealias ValueChange = (Bool) -> Void

  public init(initialValue: Bool, valueChange: (ValueChange)? = nil) {
    self.valueChange = valueChange
    super.init(frame: .zero)
    isOn = initialValue
    addTarget(self, action: #selector(valueChanged), for: .valueChanged)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  var valueChange: ValueChange?

  @objc func valueChanged() {
    valueChange?(self.isOn)
  }
}

public protocol PickerAccessoryViewValue {
  var id: String { get }
  var localizedTitle: String { get }
}

public class PickerAccessoryView: UIButton {
  public typealias ValueChange = (PickerAccessoryViewValue) -> Void
  private let textColor = UIColor.secondaryBraveLabel
  
  private let options: [PickerAccessoryViewValue]
  private let valueChange: ValueChange

  /// The current selected id for the options above
  /// Needs to be one of the values available in options
  public var selectedValue: PickerAccessoryViewValue {
    didSet {
      guard oldValue.id != selectedValue.id else { return }
      setTitle(selectedValue.localizedTitle, for: .normal)
      setMenu()
    }
  }
  
  public override var accessibilityValue: String? {
    get { return title(for: .normal) }
    set { assertionFailure() } // swiftlint:disable:this unused_setter_value
  }

  public init(options: [PickerAccessoryViewValue], selectedValue: PickerAccessoryViewValue, valueChange: @escaping ValueChange) {
    self.selectedValue = selectedValue
    self.options = options
    self.valueChange = valueChange
    super.init(frame: CGRect(width: 105, height: 40))
    
    var configuration = UIButton.Configuration.plain()
    configuration.image = UIImage(systemName: "chevron.up.chevron.down")
    configuration.imagePlacement = .trailing
    configuration.titleAlignment = .trailing
    configuration.contentInsets = .zero
    configuration.imagePadding = 4
    configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 10)
    configuration.baseForegroundColor = .secondaryBraveLabel
    configuration.title = selectedValue.localizedTitle
    self.configuration = configuration
    showsMenuAsPrimaryAction = true
    setMenu()
  }
  
  private func setMenu() {
    menu = UIMenu(
      title: "",
      options: [.displayInline, .singleSelection],
      
      children: options.map { value in
        let state: UIMenuElement.State = value.id == selectedValue.id ? .on : .off
        
        return UIAction(title: value.localizedTitle, state: state, handler: { [weak self] _ in
          self?.selectedValue = value
          self?.valueChange(value)
        })
      }
    )
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

extension Row {
  /// Creates a switch toggle `Row` which updates a `Preferences.Option<Bool>`
  public static func boolRow(title: String, detailText: String? = nil, option: Preferences.Option<Bool>, onValueChange: SwitchAccessoryView.ValueChange? = nil, image: UIImage? = nil) -> Row {
    return Row(
      text: title,
      detailText: detailText,
      image: image,
      accessory: .view(SwitchAccessoryView(initialValue: option.value, valueChange: onValueChange ?? { option.value = $0 })),
      cellClass: MultilineSubtitleCell.self,
      uuid: option.key
    )
  }

  /// Creates a switch toggle `Row` which holds local value and no preference update
  public static func boolRow(uuid: UUID = UUID(), title: String, detailText: String? = nil, toggleValue: Bool, valueChange: @escaping ValueChange, cellReuseId: String) -> Row {
    return Row(
      text: title,
      detailText: detailText,
      accessory: .view(SwitchAccessoryView(initialValue: toggleValue, valueChange: valueChange)),
      cellClass: MultilineSubtitleCell.self,
      uuid: uuid.uuidString,
      reuseIdentifier: cellReuseId
    )
  }
  
  /// Creates a switch toggle `Row` which holds local value and no preference update
  public static func pickerRow(uuid: UUID = UUID(), title: String, detailText: String?, options: [PickerAccessoryViewValue], selectedValue: PickerAccessoryViewValue, valueChange: @escaping PickerAccessoryView.ValueChange) -> Row {
    let pickerView = PickerAccessoryView(
      options: options, selectedValue: selectedValue, valueChange: valueChange
    )
    
    // Get the largest possible size
    var frame: CGRect = pickerView.frame
    for option in options {
      pickerView.selectedValue = option
      pickerView.sizeToFit()
      
      if frame.width < pickerView.frame.width {
        frame = pickerView.frame
      }
    }
    pickerView.selectedValue = selectedValue
    pickerView.frame = frame
    
    return Row(
      text: title,
      detailText: detailText,
      accessory: .view(pickerView),
      cellClass: MultilineSubtitleCell.self,
      uuid: uuid.uuidString,
      reuseIdentifier: "picker_row"
    )
  }
}

public class MultilineButtonCell: ButtonCell {

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    textLabel?.numberOfLines = 0
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

public class CenteredButtonCell: ButtonCell, TableViewReusable {
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    textLabel?.textAlignment = .center
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

public class MultilineValue1Cell: Value1Cell {

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    textLabel?.numberOfLines = 0
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

public class ColoredDetailCell: UITableViewCell, Cell {

  public static let colorKey = "color"

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: .value1, reuseIdentifier: reuseIdentifier)
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  public func configure(row: Row) {
    textLabel?.text = row.text
    detailTextLabel?.text = row.detailText
    accessoryType = row.accessory.type
    imageView?.image = row.image

    guard let detailColor = row.context?[ColoredDetailCell.colorKey] as? UIColor else { return }
    detailTextLabel?.textColor = detailColor
  }
}

open class MultilineSubtitleCell: SubtitleCell {

  public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    textLabel?.numberOfLines = 0
    detailTextLabel?.numberOfLines = 0
    detailTextLabel?.textColor = .secondaryBraveLabel
  }

  public required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
