//
//  CategoriesTableViewController.swift
//  Multiple Event Countdown
//
//  Created by Edward Manning on 8/21/18.
//  Copyright © 2018 Ed Manning. All rights reserved.
//

import UIKit
import RealmSwift

class CategoriesTableViewController: UITableViewController, UITextFieldDelegate {
    
    var editableCategories = [String]()
    fileprivate var deletions = [String]()
    fileprivate var modifications = [String: String]()
    fileprivate var additions = [String]()
    
    fileprivate let mainRealm = try! Realm(configuration: appRealmConfig)

    override func viewDidLoad() {
        super.viewDidLoad()
        if let categories = userDefaults.value(forKey: "Categories") as? [String] {
            for category in categories {
                if !immutableCategories.contains(category) {editableCategories.append(category)}
            }
        }
        else {
            // TODO: Error Handling
            fatalError("Unable to fetch categories from user defaults in NewEventViewController")
        }
        
        tableView.setEditing(true, animated: false)
        tableView.tableFooterView = UIView()
        
        let confirmButton = UIBarButtonItem()
        confirmButton.target = self
        confirmButton.action = #selector(confirmAndExit)
        confirmButton.tintColor = GlobalColors.orangeDark
        let attributes: [NSAttributedStringKey: Any] = [.font: UIFont(name: GlobalFontNames.ralewayRegular, size: 14.0)! as Any]
        confirmButton.setTitleTextAttributes(attributes, for: .normal)
        confirmButton.setTitleTextAttributes(attributes, for: .disabled)
        confirmButton.title = "CONFIRM"
        
        navigationItem.rightBarButtonItem = confirmButton
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {if deletions.count == 0 {return 1} else {return 2}}
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {return editableCategories.count + 1} else {return deletions.count}
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Category", for: indexPath) as! CategoryTableViewCell
        cell.undoButton.addTarget(self, action: #selector(handleUndoButtonTap(_:)), for: .touchUpInside)
        let standardFontSizeForCell: CGFloat = 18.0
        if indexPath.section == 0 {
            if indexPath.row == editableCategories.count {
                cell.titleTextField.text = nil
                cell.undoButton.isHidden = true
            }
            else {
                cell.titleTextField.text = editableCategories[indexPath.row]
                cell.titleTextField.delegate = self
                if modifications.values.contains(editableCategories[indexPath.row]) {
                    cell.titleTextField.textColor = UIColor.yellow
                    cell.titleTextField.font = UIFont(name: GlobalFontNames.ralewayMediumItalic, size: standardFontSizeForCell)
                    cell.undoButton.isHidden = false
                }
                else if additions.contains(editableCategories[indexPath.row]) {
                    cell.titleTextField.textColor = UIColor.green
                    cell.titleTextField.font = UIFont(name: GlobalFontNames.ralewayMediumItalic, size: standardFontSizeForCell)
                    cell.undoButton.isHidden = true
                }
                else {
                    cell.titleTextField.textColor = GlobalColors.orangeRegular
                    cell.titleTextField.font = UIFont(name: GlobalFontNames.ralewayMedium, size: standardFontSizeForCell)
                    cell.undoButton.isHidden = true
                }
            }
        }
        else {
            cell.titleTextField.text = deletions[indexPath.row]
            cell.titleTextField.delegate = self
            cell.titleTextField.textColor = UIColor.lightText
            cell.undoButton.isHidden = false
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCellEditingStyle {
        if indexPath.section == 0 {
            if indexPath.row == editableCategories.count {return .insert}
            else {return .delete}
        }
        else {return .none}
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            let removed = editableCategories.remove(at: indexPath.row)
            if let index = additions.index(of: removed) {
                additions.remove(at: index)
                tableView.beginUpdates(); tableView.deleteRows(at: [indexPath], with: .fade); tableView.endUpdates()
            }
            else {
                deletions.append(removed)
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .fade)
                if deletions.count == 1 {
                    let sectionToInsert = IndexSet([1])
                    tableView.insertSections(sectionToInsert, with: .fade)
                }
                else {tableView.insertRows(at: [IndexPath(row: deletions.count - 1, section: 1)], with: .fade)}
                tableView.endUpdates()
            }
        }
        
        else if editingStyle == .insert {
            var index = 0
            var foundIndex = false
            while !foundIndex {
                if index == 0 {if editableCategories.contains("New Category") {index += 1} else {foundIndex = true}}
                else {if editableCategories.contains("New Category \(index)") {index += 1} else {foundIndex = true}}
            }
            var newEntry = ""
            if index == 0 {newEntry = "New Category"} else {newEntry = "New Category \(index)"}
            editableCategories.append(newEntry)
            additions.append(newEntry)
            tableView.beginUpdates()
            tableView.insertRows(at: [indexPath], with: .fade)
            tableView.endUpdates()
        }
        
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        if indexPath.row == editableCategories.count || indexPath.section == 1 {return false} else {return true}
    }
    
    override func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        if proposedDestinationIndexPath.row == editableCategories.count {
            return IndexPath(row: editableCategories.count - 1, section: proposedDestinationIndexPath.section)
        }
        else {return proposedDestinationIndexPath}
    }

    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        let movingItem = editableCategories.remove(at: fromIndexPath.row)
        editableCategories.insert(movingItem, at: to.row)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {return 0.0} else {return 20.0}
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 {return UIView()} else {return nil}
    }
    
    //
    // MARK: Text field delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if let text = textField.text, text.contains("New Category") {textField.selectAll(nil)}}
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text {
            if checkForDuplicates(withText: text) {
                let duplicateController = UIAlertController(title: "Duplicate Category", message: "That category already exists, please select a different category title.", preferredStyle: .alert)
                let okayAction = UIAlertAction(title: "Okay", style: .default) { (action) in
                    self.dismiss(animated: true, completion: nil)
                }
                
                duplicateController.addAction(okayAction)
                present(duplicateController, animated: true, completion: nil)
            }
            else {textField.resignFirstResponder(); return true}
        }
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextFieldDidEndEditingReason) {
        let cell = textField.superview!.superview as! CategoryTableViewCell
        let ipForCell = tableView.indexPath(for: cell)!
        switch reason {
        case .committed:
            if let text = textField.text {
                if let index = additions.index(of: editableCategories[ipForCell.row]) {additions[index] = text}
                else if let key = modifications.firstKey(forValue: editableCategories[ipForCell.row]) {modifications[key] = text}
                else {if editableCategories[ipForCell.row] != text {modifications[editableCategories[ipForCell.row]] = text}}
                editableCategories[ipForCell.row] = text
                tableView.reloadRows(at: [ipForCell], with: .fade)
            }
            else {textField.text = editableCategories[ipForCell.row]}
        case .cancelled: textField.text = editableCategories[ipForCell.row]
        }
    }
    
    //
    // MARK: Actions
    @objc fileprivate func handleUndoButtonTap(_ sender: UIButton) {
        let cell = sender.superview!.superview as! CategoryTableViewCell
        let indexPath = tableView.indexPath(for: cell)!
        if indexPath.section == 0 {
            if let key = modifications.firstKey(forValue: editableCategories[indexPath.row]) {
                modifications[key] = nil
                editableCategories[indexPath.row] = key
            }
            else {
                #if DEBUG
                fatalError("A non-modified cell had the undo button active probably.")
                #endif
            }
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
        else {
            let deleted = deletions.remove(at: indexPath.row)
            editableCategories.append(deleted)
            tableView.beginUpdates()
            if deletions.isEmpty {tableView.deleteSections(IndexSet([1]), with: .fade)}
            else {tableView.deleteRows(at: [indexPath], with: .fade)}
            tableView.insertRows(at: [IndexPath(row: editableCategories.count - 1, section: 0)], with: .fade)
            tableView.endUpdates()
        }
    }
    
    @objc fileprivate func confirmAndExit() {
        
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        let allEvents = mainRealm.objects(SpecialEvent.self)
        
        func finalCleanup() {
            
            let allCategories = editableCategories + immutableCategories
            userDefaults.set(allCategories, forKey: "Categories")
            
            var eventsWithAModifiedCategory = [SpecialEvent]()
            for modified in  modifications.keys {
                let predicate = NSPredicate(format: "category = %@", argumentArray: [modified])
                let events = allEvents.filter(predicate)
                for event in events {eventsWithAModifiedCategory.append(event)}
            }
            
            if !eventsWithAModifiedCategory.isEmpty {
                do {try! mainRealm.write {for event in eventsWithAModifiedCategory {event.category = modifications[event.category]!}}}
                alertController.title = "Updates Successful"
                alertController.message = "Existing event categories that have been modified have been updated to reflect your changes. Any events with a category that was deleted have become uncategorized."
                
                let okayAction = UIAlertAction(title: "Okay!", style: .default) { (action) in
                    self.dismiss(animated: true) {self.performSegue(withIdentifier: "Unwind to Settings", sender: self)}
                }
                
                alertController.addAction(okayAction)
                present(alertController, animated: true, completion: nil)
            }
            
            else {performSegue(withIdentifier: "Unwind to Settings", sender: self)}
        }
        
        var eventsWithADeletedCategory = [SpecialEvent]()
        for deleted in deletions {
            let predicate = NSPredicate(format: "category = %@", argumentArray: [deleted])
            let events = allEvents.filter(predicate)
            for event in events {eventsWithADeletedCategory.append(event)}
        }
        
        if !eventsWithADeletedCategory.isEmpty {
            alertController.title = "Deleted Categories"
            let first = eventsWithADeletedCategory[0].title
            let second: String? = {if eventsWithADeletedCategory.count == 2 {return ", " + eventsWithADeletedCategory[1].title} else {return nil}}()
            let third: String? = {if eventsWithADeletedCategory.count == 3 {return ", " + eventsWithADeletedCategory[2].title} else {return nil}}()
            let remainder: String? = {
                if eventsWithADeletedCategory.count > 3 {return ", and " + String(eventsWithADeletedCategory.count - 3) + " more event(s)"}
                else {return nil}
            }()
            alertController.message = "\nWould you like to delete the events in the categories you have chosen to delete? The affected events are:\n\n\(first)\(second ?? "")\(third ?? "")\(remainder ?? "")"
            
            let deleteAction = UIAlertAction(title: "Delete Events", style: .destructive) { (action) in
                for event in eventsWithADeletedCategory {event.cascadeDelete()}
                do {try! self.mainRealm.write {self.mainRealm.delete(eventsWithADeletedCategory)}}
                finalCleanup()
            }
            let keepAction = UIAlertAction(title: "Keep Events", style: .default) { (action) in
                do {try! self.mainRealm.write {for event in eventsWithADeletedCategory {event.category = "Uncategorized"}}}
                finalCleanup()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alertController.addAction(deleteAction)
            alertController.addAction(keepAction)
            alertController.addAction(cancelAction)
            present(alertController, animated: true, completion: nil)
        }
        else {finalCleanup()}
    }
    
    //
    // MARK: Private helper functions
    fileprivate func checkForDuplicates(withText text: String) -> Bool {
        if editableCategories.contains(text) {return true} else {return false}
    }
}
