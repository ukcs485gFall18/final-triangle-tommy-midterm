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
            <<< TextRow("Password"){ row in
                row.title = "Password"
                row.placeholder = "Enter password for your party"
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
        guard case let password as String = values["Password"] else {
            displayError()
            return
        }
        guard case let name as String = values["Name"] else {
            displayError()
            return
        }
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
    
//    //MARK: - Navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        let tabVc = segue.destination as! UITabBarController
//        let dvc = tabVc.viewControllers![0] as! SongViewController
//        let playlistVC = tabVc.viewControllers![1] as! PlaylistViewController
//        // send the access token and player over to the SongViewController
//        dvc.spotifySession = self.spotifySession
//        dvc.playlistVC = playlistVC
//    }
}


