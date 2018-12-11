//
//  LoginViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SwiftSpinner
// LoginViewController
// Login with Spotify, and upon successful login, go to the HostViewController scene
// Created by Thomas Deeter
// Partially referenced from Brian Hans' tutorial and Elon Rubin's
// Brian Hans: https://medium.com/@brianhans/spotify-ios-sdk-authentication-b2c35cd4affb
// Elon Rubin: https://medium.com/@elonrubin/ios-spotify-sdk-swift-3-0-tutorial-b629af4b889d

class LoginViewController: UIViewController, SPTAudioStreamingPlaybackDelegate, SPTAudioStreamingDelegate {
    
    var auth = SPTAuth.defaultInstance()!
    var session:SPTSession!
    var player: SPTAudioStreamingController?
    var webUrl: URL?
    var appUrl: URL?
    var ref: DatabaseReference?
    var currentParties: [Party]?
    
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var voteButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAuth()
        // Define identifier
        let notificationName = Notification.Name("loginSuccessful")
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateAfterFirstLogin), name: notificationName, object: nil)
        loginButton.layer.cornerRadius = 5
        voteButton.layer.cornerRadius = 5
        self.ref = Database.database().reference()
        
        self.ref!.child("parties").observe(DataEventType.value, with: {(snapshot) in
            self.currentParties = FirebaseController.shared.getAllParties(snapshot: snapshot)
        })
    }
    
    /**
     Function that configures the authentication parameters
     */
    func setupAuth() {
        // Client ID (Assigned in Spotify Developer Console)
        SPTAuth.defaultInstance().clientID = "ae41de22b4334892a03f943d6d344267"
        // Redirect URL for after a successful login
        SPTAuth.defaultInstance().redirectURL = URL(string: "tdeets.razeware.RazePlayer://")
        // Scopes requested from the API
        SPTAuth.defaultInstance().requestedScopes = [SPTAuthStreamingScope, SPTAuthPlaylistModifyPrivateScope, SPTAuthPlaylistModifyPublicScope, SPTAuthPlaylistReadPrivateScope]
        // Web and iOS app versions of login URLs
        webUrl = SPTAuth.defaultInstance().spotifyWebAuthenticationURL()
        appUrl = SPTAuth.defaultInstance().spotifyAppAuthenticationURL()
    }
    
    /**
     Upon first login, initialize certain session objects
     */
    @objc func updateAfterFirstLogin () {
        let defaults = UserDefaults.standard
        // Check if the login session is valid
        if let sessionObj:AnyObject = defaults.object(forKey: "SpotifySession") as AnyObject? {
            let sessionDataObj = sessionObj as! Data
            if let firstTimeSession = NSKeyedUnarchiver.unarchiveObject(with: sessionDataObj) as? SPTSession {
                self.session = firstTimeSession
                self.performSegue(withIdentifier: "loginSuccessful", sender: nil)
            }
            else {
                print("Error logging in!!")
            }
        }
        else{
            print("Error initializing session")
        }
    }
    
    // Present the user with a dialog to enter the party passphrase, and navigate them to that party if successful
    @IBAction func votePressed(_ sender: Any) {
        
        // Alert Controller w/ Text field code from: https://stackoverflow.com/questions/47045930/swift-4-alert-with-input
        let alert = UIAlertController(title: "Enter Party Password", message: "Please enter the party passphrase generated.", preferredStyle: .alert)
        
        alert.addTextField(configurationHandler: { (textField) in
            textField.placeholder = "Party Password"
        })
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { [weak alert] (_) in
            let enteredPassword = alert?.textFields![0].text!
            var isSuccessful = false
            for party in self.currentParties! {
                if party.password == enteredPassword {
                    self.presentVoteVC(selectedParty: party)
                    isSuccessful = true
                    break
                }
            }
            
            if !isSuccessful {
                // send an error message
                let errorAlert = UIAlertController(title: "Party Not Found",
                                              message: "Please check to make sure you entered the correct password", preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                self.present(errorAlert, animated: true)
            }
            
        }))
        self.present(alert, animated: true)
    }
    
    
    func presentVoteVC(selectedParty: Party){
        let navVC = self.storyboard?.instantiateViewController(withIdentifier: "voteVC") as! UINavigationController
        if navVC != nil {
            let voteVC = navVC.viewControllers[0] as! VoterViewController
            SpotifyPlayer.shared.setCurrentParty(party: selectedParty)
            voteVC.currentParty = selectedParty
            voteVC.ref = Database.database().reference()
            voteVC.setPlaylistListener()
            
            // Set the transition animation parameters
            navVC.providesPresentationContextTransitionStyle = true
            navVC.definesPresentationContext = true
            navVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext;
            navVC.view.backgroundColor = UIColor.init(white: 0.4, alpha: 0.8)
            self.present(navVC, animated: true, completion: nil)
        }
    }
    
    
    /**
     Handle the login once the button is pressed
    */
    @IBAction func loginPressed(_ sender: Any) {
        // if the user has the App installed, login with that, otherwise, login with Web version
        // This code idea was in Brian Hans' tutorial
        if SPTAuth.supportsApplicationAuthentication(){
            UIApplication.shared.open(appUrl!, options: [:], completionHandler: nil)
        }
        else {
            UIApplication.shared.open(webUrl!, options: [:], completionHandler: nil)
        }
        
    }
    
    /**
     delegate method that calls once the login was successful. Performs a segue to the main controller
    */
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        print("audioStreamingDidLogin")
        self.performSegue(withIdentifier: "loginSuccessful", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // The segue goes into a TabBarController, we know the first view controller after the Tab bar is the SongViewController
        if segue.identifier == "loginSuccessful" {
            let nav = segue.destination as! UINavigationController
            let dvc = nav.viewControllers[0] as! HostHomeViewController
            dvc.spotifySession = self.session
        }
    }
}

