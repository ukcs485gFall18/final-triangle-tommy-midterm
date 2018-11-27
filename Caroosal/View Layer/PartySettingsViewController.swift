//
//  PartySettingsViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 11/6/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import Eureka
import FirebaseDatabase

class PartySettingsViewController: FormViewController {
    
    var spotifySession: SPTSession?
    var ref: DatabaseReference?
    
    // on viewDidLoad, initialize the form components
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.ref = Database.database().reference()
        
        // first section is information about creating the party
        
        form +++ Section("End Party")
            // logout button section
            <<< ButtonRow("EndButton") {
                $0.title = "End Party"
                $0.onCellSelection { cell, row in
                    SpotifyPlayer.shared.endCurrentParty()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "partyListener"), object: nil)
                    self.dismiss(animated: true, completion: nil)
                }
        }
        
        form +++ Section("Log Out")
            // logout button section
            <<< ButtonRow("LogoutButton") {
                $0.title = "Logout"
                $0.onCellSelection { cell, row in
                    SpotifyPlayer.shared.logoutPlayer()
                    
                    let presentedVc = self.storyboard?.instantiateViewController(withIdentifier: "homeVC") as! LoginViewController
                    if presentedVc != nil {
                        presentedVc.providesPresentationContextTransitionStyle = true
                        presentedVc.definesPresentationContext = true
                        presentedVc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext;
                        self.present(presentedVc, animated: true, completion: nil)
                    }
                    
                }
        }
    }
    
    // alert the user that their form data is invalid
    func displayError(){
        let alert = UIAlertController(title: "Invalid Form Data", message: "You left one or more of the sections blank!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alert, animated: true)
    }
    
}
