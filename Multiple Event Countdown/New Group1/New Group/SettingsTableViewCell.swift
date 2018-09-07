//
//  SettingsTableViewCell.siwft
//  Multiple Event Countdown
//
//  Created by Ed Manning on 7/8/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit

class SettingsTableViewCell: UITableViewCell, UIPickerViewDataSource, UIPickerViewDelegate {

    var delegate: SettingsTableViewCellDelegate?
    var title: String? {didSet {titleLabel.text = title}}
    
    var rowType = SettingsTypeDataSource.RowTypes.action {
        didSet {
            switch rowType {
            case .action:
                selectedOptionLabel.isHidden = true
                onOffSwitch.isHidden = true
                optionsPickerView.isHidden = true
            case .onOrOff:
                selectedOptionLabel.isHidden = true
                onOffSwitch.isHidden = false
                optionsPickerView.isHidden = true
            case .segue:
                selectedOptionLabel.isHidden = false
                selectedOptionLabel.text = ">"
                onOffSwitch.isHidden = true
                optionsPickerView.isHidden = true
            case .selectOption:
                selectedOptionLabel.isHidden = false
                onOffSwitch.isHidden = true
            }
        }
    }
    
    var options: [SettingsTypeDataSource.Option]? {
        didSet {
            if let _options = options, !_options.isEmpty {
                optionsPickerView.reloadAllComponents()
                optionsPickerView.selectRow(selectedOptionIndex, inComponent: 0, animated: false)
            }
        }
    }
    
    fileprivate var selectedOptionIndex = 0 {
        didSet {
            if selectedOptionLabel.text != options![selectedOptionIndex].text {
                
                if !isUserChange {optionsPickerView.selectRow(selectedOptionIndex, inComponent: 0, animated: false)}
                
                if !selectedOptionLabel.isHidden {
                    let labelTransition = CATransition()
                    labelTransition.duration = 0.3
                    labelTransition.type = kCATransitionFade
                    selectedOptionLabel.layer.add(labelTransition, forKey: nil)
                }
                selectedOptionLabel.text = options![selectedOptionIndex].text ?? ""
                if rowType == .segue {selectedOptionLabel.text = selectedOptionLabel.text! + " >"}
                else if rowType == .onOrOff {
                    if selectedOptionIndex == 0 {onOffSwitch.isOn = true}
                    else {onOffSwitch.isOn = false}
                }
                
                isUserChange = false
                delegate?.selectedOptionDidUpdate(cell: self)
            }
        }
    }
    
    var selectedOption: SettingsTypeDataSource.Option? {
        get {
            if let _options = options, !_options.isEmpty {return _options[selectedOptionIndex]}
            else {return nil}
        }
        set {
            if let _newValue = newValue {
                guard let _options = options else {fatalError("Can't set selected option because there are no options!!")}
                guard let index = _options.index(of: _newValue) else {
                    fatalError("Could not find \(_newValue) in current options list!!")
                }
                selectedOptionIndex = index
            }
            else {
                if rowType == .segue {selectedOptionLabel.text = ">"}
                else {selectedOptionLabel.text = nil}
            }
        }
    }
    
    func selectNextOption() {
        guard let _options = options, !_options.isEmpty else {return}
        if selectedOptionIndex == _options.count - 1 {selectedOptionIndex = 0}
        else {selectedOptionIndex += 1}
    }
    
    static var collapsedHeight: CGFloat = 47 // switch height + top margin + bottom margin
    static var expandedHeight: CGFloat = SettingsTableViewCell.collapsedHeight + 118 // + PickerView Height + 10 spacing + corner radius for some reason.
    
    fileprivate var isUserChange = false
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var selectedOptionLabel: UILabel!
    @IBOutlet weak var onOffSwitch: UISwitch!
    @IBOutlet weak var optionsPickerView: UIPickerView!
    
    override func awakeFromNib() {super.awakeFromNib()}
    
    override func prepareForReuse() {selectedOptionLabel.text = nil}
    
    //
    // Picker View Data Source
    func numberOfComponents(in pickerView: UIPickerView) -> Int {return 1}
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return options?.count ?? 0
    }
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var _viewToReturn = view as? UILabel
        if _viewToReturn == nil {
            _viewToReturn = UILabel()
            _viewToReturn!.font = UIFont(name: GlobalFontNames.ralewayLight, size: 14.0)
            _viewToReturn!.textColor = GlobalColors.cyanRegular
            _viewToReturn!.textAlignment = .center
        }
        let viewToReturn = _viewToReturn!
        viewToReturn.text = options![row].text
        return viewToReturn
    }
    
    //
    // Picker View Delegate
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        isUserChange = true
        selectedOption = options![row]
    }

}
