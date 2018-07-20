//
//  ShareViewController.swift
//  groovy
//
//  Created by Kyle Stokes on 7/15/18.
//  Copyright © 2018 Kyle Stokes. All rights reserved.
//

import UIKit
import Firebase
import Spring

class ShareViewController: UIViewController {
    
    // MARK: Properties
    
    var databaseReference: DatabaseReference!
    var budget: Budget!
    var userEmail: String!
    
    // MARK: - Outlets
    
    @IBOutlet weak var shareIcon: SpringImageView!
    @IBOutlet weak var sharedWith: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var email: UITextField!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var shareLabel: UILabel!
    
    // MARK: - Actions
    
    @IBAction func dismiss(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
        email.resignFirstResponder()
    }
    
    @IBAction func shareBudgetOnSave(_ sender: UIBarButtonItem) {
        shareBudget()
    }
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configEmailTextField()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configNavBar()
        configShareIcon()
        animateShareIcon()
        configShareLabel()
        configTableView()
    }
    
    func configNavBar() {
        // Owner
        if userEmail == budget.createdBy {
            navigationItem.rightBarButtonItem?.isEnabled = false
            // Hide for non-owner
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }
    
    func configEmailTextField() {
        // Owner
        if userEmail == budget.createdBy {
            email.delegate = self
            email.addTarget(self, action: #selector(textFieldDidChange), for: UIControlEvents.editingChanged)
            // Hide for non-owner
        } else {
            email.isEnabled = false
        }
    }
    
    func configShareLabel() {
        shareLabel.text = userEmail == budget.createdBy ? "Add email address to share" : "Only owner can share"
    }
    
    func configTableView() {
        // Open keyboard for email if no shared emails exist
        if budget.sharedWith?.count == 1 {
            email.becomeFirstResponder()
        }
        
        // Separator color lines
        tableView.separatorColor = UIColor.lightGray
        
        // Remove 'excess' lines
        tableView.tableFooterView = UIView()
    }
    
    func configShareIcon() {
        shareIcon.image = budget.isShared! ? #imageLiteral(resourceName: "share-filled") : #imageLiteral(resourceName: "share-display")
        shareIcon.image = shareIcon.image!.withRenderingMode(.alwaysTemplate)
        shareIcon.tintColor = UIColor(red: 255/255, green: 45/255, blue: 85/255, alpha: 1)
    }
    
    func animateShareIcon() {
        shareIcon.animation = "zoomIn"
        shareIcon.duration = 1.5
        shareIcon.animate()
    }
    
    func removeEmailFromSharing(_ email: String) {
        let indexOfEmailToRemove = budget.sharedWith?.index(of: email)
        budget.sharedWith?.remove(at: indexOfEmailToRemove!)
        firebaseSave(sharedWith: budget.sharedWith!)
        tableView.reloadData()
    }
    
    @objc func shareBudget() {
        // Add new email
        var sharedWith = budget.sharedWith!
        sharedWith.append(email.text!)
        budget.sharedWith = sharedWith
        
        // Save in Firebase
        firebaseSave(sharedWith: sharedWith)
        
        // Add email to table with animation
        let indexOfEmailToAdd = budget.sharedWith?.index(of: email.text!)
        let indexPath = IndexPath(item: indexOfEmailToAdd!, section: 0)
        tableView.insertRows(at: [indexPath], with: .top)
        
        // Reconfig email text field
        email.text = ""
        email.resignFirstResponder()
        
        // Reconfig 'Save' button
        saveButton.isEnabled = false
    }
    
    func firebaseSave(sharedWith: [String]) {
        databaseReference.child("budgets").child("\(budget.id!)").child("sharedWith").setValue(sharedWith)
    }
    
    @objc func textFieldDidChange() {
        saveButton.isEnabled = (email.text?.count)! > 0 ? true : false
    }
    
    // Close keyboard when tapping outside of keyboard
    // https://medium.com/@KaushElsewhere/how-to-dismiss-keyboard-in-a-view-controller-of-ios-3b1bfe973ad1
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
}

extension ShareViewController: UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - UITableViewDelegate, UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return budget.sharedWith?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "emailCell", for: indexPath)
        cell.textLabel?.textColor = UIColor.darkGray
        // Show gray for Owner email
        if budget.sharedWith![indexPath.row] == budget.createdBy {
            cell.textLabel?.text = (budget.sharedWith?[indexPath.row])! + " (Owner)"
            cell.textLabel?.textColor = UIColor.lightGray
        } else if budget.sharedWith![indexPath.row] != "none" {
            // If owner, then show all emails as default
            if budget.createdBy == userEmail {
                cell.textLabel?.text = budget.sharedWith?[indexPath.row]
            // Non-owner can only see themselves as default
            } else {
                cell.textLabel?.text = budget.sharedWith?[indexPath.row]
                if budget.sharedWith?[indexPath.row] != userEmail {
                    cell.textLabel?.textColor = UIColor.lightGray
                }
            }
        // Hide table if no shared emails
        } else {
            tableView.isHidden = true
            sharedWith.isHidden = true
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let emailToDelete = budget.sharedWith![indexPath.row]
            
            let alert = UIAlertController(title: "Remove \(emailToDelete)?", message: "Removing \(emailToDelete) will no longer allow them to see this budget", preferredStyle: .actionSheet)
            
            alert.view.tintColor = UIColor(red: 255/255, green: 45/255, blue: 85/255, alpha: 1)
            
            let deleteAction = UIAlertAction(title: "Remove", style: .default, handler: { (email) in
                self.removeEmailFromSharing(emailToDelete)
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteButton = UITableViewRowAction(style: .default, title: "Remove") { (action, indexPath) in
            self.tableView.dataSource?.tableView!(self.tableView, commit: .delete, forRowAt: indexPath)
            return
        }
        deleteButton.backgroundColor = UIColor(red: 255/255, green: 45/255, blue: 85/255, alpha: 1)
        return [deleteButton]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // If owner, all budgets are editable other than owner email
        if budget.createdBy == userEmail {
            let isOwnerEmail = budget.sharedWith![indexPath.row] == budget.createdBy
            let returnValue = isOwnerEmail ? false : true
            return returnValue
            // Not owner so only user email is editable
        } else {
            let isUserEmail = budget.sharedWith![indexPath.row] == userEmail
            return isUserEmail
        }
    }
}

extension ShareViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if !(email.text?.isEmpty)! {
            shareBudget()
        }
        email.resignFirstResponder()
        return true
    }
}