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
    let customPurpleColor = UIColor(red:0.39, green:0.37, blue:0.85, alpha:1.0)
    
    // on viewDidLoad, initialize the form components
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.ref = Database.database().reference()
        self.tableView.backgroundColor = customPurpleColor
        
        // first section displays party information
        // editing section labels: https://github.com/xmartlabs/Eureka/issues/379
        form +++ Section(){ section in
            var header = HeaderFooterView<UILabel>(.class)
            header.height = { 60.0 }
            header.onSetupView = {view, _ in
                view.textColor = .white
                view.text = "Party Information"
                view.font = UIFont.boldSystemFont(ofSize: 24)
            }
            section.header = header
        }
            <<< TextRow(){ row in
                row.title = "Party Name"
                row.placeholder = SpotifyPlayer.shared.currentParty?.name
                row.disabled = true
                }
            <<< TextRow(){ row in
                row.title = "Party Password"
                row.placeholder = SpotifyPlayer.shared.currentParty?.password
                row.disabled = true
            }
        
        // second section is a button to end the party
        form +++ Section(){ section in
            var header = HeaderFooterView<UILabel>(.class)
            header.height = { 60.0 }
            header.onSetupView = {view, _ in
                view.textColor = .white
                view.text = "End Party"
                view.font = UIFont.boldSystemFont(ofSize: 24)
            }
            section.header = header
        }
            // logout button section
            <<< ButtonRow("EndButton") {
                $0.title = "End Party"
                $0.onCellSelection { cell, row in
                    SpotifyPlayer.shared.endCurrentParty()
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "partyListener"), object: nil)
                    self.dismiss(animated: true, completion: nil)
                }
        }
        
        // third section allows the host to log out (does not end party)
        form +++ Section(){ section in
            var header = HeaderFooterView<UILabel>(.class)
            header.height = { 60.0 }
            header.onSetupView = {view, _ in
                view.textColor = .white
                view.text = "Log Out"
                view.font = UIFont.boldSystemFont(ofSize: 24)
            }
            section.header = header
        }
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
