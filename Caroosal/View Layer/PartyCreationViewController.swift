//
//  PartyCreationViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 11/6/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import Eureka
import FirebaseDatabase

// Added by Thomas Deeter: Form for users to create their parties
class PartyCreationViewController: FormViewController {
    
    var spotifySession: SPTSession?
    var currentUsername: String?
    var ref: DatabaseReference?
    
    // on viewDidLoad, initialize the form components
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.ref = Database.database().reference()
        
        // first section is information about creating the party
        form +++ Section("Create Party!")
            <<< TextRow("Name"){ row in
                row.title = "Party Name"
                row.placeholder = "Enter party name here"
            }
            // second section is the submit button
            +++ Section()
            <<< ButtonRow("SaveButton") {
                $0.title = "Submit"
                $0.onCellSelection { cell, row in
                    self.validateForm(values: self.form.values(includeHidden: true))
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "partyListener"), object: nil)
                }
            }
            <<< ButtonRow("DismissButton") {
                $0.title = "Dismiss"
                $0.onCellSelection { cell, row in
                    self.dismiss(animated: true, completion: {})
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "partyListener"), object: nil)
                }
        }
    }
    
    // Validate the user's responses to ensure they entered in the correct data
    func validateForm(values: [String: Any?]){
        guard case let name as String = values["Name"] else {
            displayError()
            return
        }
        
        // random alphanumeric string code found from:
        // https://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let password = String((0...5-1).map{ _ in letters.randomElement()! })
        
        let formData = ["Password": password, "Name": name, "Token": self.spotifySession?.accessToken!]
        pushToFirebase(data: formData)
    }
    
    func pushToFirebase(data: [String: Any]){
        self.ref!.child("parties").child(self.currentUsername!).setValue(data)
        self.dismiss(animated: true, completion: {})
    }
    
    // alert the user that their form data is invalid
    func displayError(){
        let alert = UIAlertController(title: "Invalid Form Data", message: "You left one or more of the sections blank!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
}


