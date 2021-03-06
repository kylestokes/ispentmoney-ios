//
//  EditBudgetViewController.swift
//  groovy
//
//  Created by Kyle Stokes on 7/15/18.
//  Copyright © 2018 Kyle Stokes. All rights reserved.
//

import UIKit
import Firebase
import DeviceKit

class EditBudgetViewController: UIViewController {
    
    // MARK: - Properties
    
    var databaseReference: DatabaseReference!
    var budget: Budget!
    var userEmail: String!
    
    // MARK: - Outlets
    
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var name: UITextField!
    @IBOutlet weak var amount: UITextField!
    @IBOutlet weak var resetButton: UIBarButtonItem!
    
    // MARK: - Actions
    
    @IBAction func dismiss(_ sender: Any) {
        resignAndDismiss()
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        save()
    }
    
    @IBAction func reset(_ sender: UIBarButtonItem) {
        showResetAlert()
    }
    
    // MARK: - Life cycle
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configName()
        configAmount()
        configResetButton()
    }
    
    func configName() {
        let device = Device()
        name.text = budget.name!
        name.delegate = self
        name.tintColor = UIColor(red: 255/255, green: 45/255, blue: 85/255, alpha: 1)
        name.addTarget(self, action: #selector(textFieldDidChange), for: UIControlEvents.editingChanged)
        if device.isOneOf(iPadsThatNeedAdjusting.noniPadPro12InchDevices) {
            name.autocorrectionType = .no
        }
    }
    
    func configAmount() {
        var budgetAmountFormatted = formatAsCurrency(budget.setAmount!)
        budgetAmountFormatted = budgetAmountFormatted.replacingOccurrences(of: "$", with: "")
        amount.text = budgetAmountFormatted.replacingOccurrences(of: ",", with: "")
        amount.delegate = self
        amount.tintColor = UIColor(red: 255/255, green: 45/255, blue: 85/255, alpha: 1)
        amount.addTarget(self, action: #selector(textFieldDidChange), for: UIControlEvents.editingChanged)
    }
    
    func configResetButton() {
        resetButton.isEnabled = budget.createdBy == userEmail ? true : false
    }
    
    func formatAsCurrency(_ number: Double) -> String {
        let formatter = NumberFormatter()
        var currency: String = ""
        formatter.numberStyle = .currency
        if let formattedCurrencyAmount = formatter.string(from: number as NSNumber) {
            currency = "\(formattedCurrencyAmount)"
        }
        return currency
    }
    
    func textFieldsHaveValues() -> Bool {
        if amount.hasText && name.hasText {
            let isAmountGreaterThanEqualOneCent = Double(amount.text!)! >= 0.01 ? true : false
            let isAmountGreaterThanFiveMillion = Double(amount.text!)! > 5000000 ? true : false
            let amountHasValue = (amount.text?.count)! > 0  && isAmountGreaterThanEqualOneCent && !isAmountGreaterThanFiveMillion ? true : false
            return amountHasValue
        } else {
            return false
        }
    }
    
    func resignAndDismiss() {
        amount.resignFirstResponder()
        name.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    func showResetAlert() {
        let deleteAction = UIAlertAction(title: "Reset", style: .default, handler: { (delete) in
            self.resetBudget()
        })
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let actions = [deleteAction, cancelAction]
        showActionSheetAlert(title: "Reset \(name.text!)", message: "Resetting \(name.text!) will remove all purchase history and set spending back to $0.00", actions: actions)
    }
    
    func resetBudget() {
        var budgetDictionary: [String:Any] = [:]
        budgetDictionary["name"] = budget.name
        budgetDictionary["createdBy"] = budget.createdBy
        budgetDictionary["hiddenFrom"] = budget.hiddenFrom
        budgetDictionary["history"] = ["none:none"]
        budgetDictionary["isShared"] = budget.isShared
        budgetDictionary["left"] = budget.setAmount
        budgetDictionary["setAmount"] = budget.setAmount
        budgetDictionary["sharedWith"] = budget.sharedWith
        budgetDictionary["spent"] = 0
        budgetDictionary["userDate"] = ["none:none"]
        databaseReference.child("budgets").child("\(budget.id!)").setValue(budgetDictionary as NSDictionary)
        self.resignAndDismiss()
    }
    
    @objc func save() {
        let setAmount = Double(self.amount.text!)
        var budgetDictionary: [String:Any] = [:]
        budgetDictionary["name"] = name.text!
        budgetDictionary["createdBy"] = budget.createdBy
        budgetDictionary["hiddenFrom"] = budget.hiddenFrom
        budgetDictionary["history"] = budget.history
        budgetDictionary["isShared"] = budget.isShared
        budgetDictionary["left"] = setAmount! - budget.spent!
        budgetDictionary["setAmount"] = setAmount!
        budgetDictionary["sharedWith"] = budget.sharedWith
        budgetDictionary["spent"] = budget.spent
        budgetDictionary["userDate"] = budget.userDate
        databaseReference.child("budgets").child("\(budget.id!)").setValue(budgetDictionary as NSDictionary)
        self.resignAndDismiss()
    }
    
    @objc func textFieldDidChange() {
        saveButton.isEnabled = textFieldsHaveValues()
    }
    
    // Close keyboard when tapping outside of keyboard
    // https://medium.com/@KaushElsewhere/how-to-dismiss-keyboard-in-a-view-controller-of-ios-3b1bfe973ad1
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

extension EditBudgetViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if name.isEditing {
            amount.becomeFirstResponder()
        } else {
            if textFieldsHaveValues() {
                save()
            }
        }
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // Only allow numbers and 1 decimal in amount text field
        // https://stackoverflow.com/a/48093890
        if textField.keyboardType == .decimalPad {
            let s = NSString(string: textField.text ?? "").replacingCharacters(in: range, with: string)
            guard !s.isEmpty else { return true }
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = .none
            return numberFormatter.number(from: s)?.intValue != nil
        } else {
            return true
        }
    }
}
