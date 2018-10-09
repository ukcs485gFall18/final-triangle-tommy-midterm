//
//  LoginViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit

// LoginViewController
// Login with Spotify, and upon successful login, go to the main SongViewController scene
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
    
    
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupAuth()
        // Define identifier
        let notificationName = Notification.Name("loginSuccessful")
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateAfterFirstLogin), name: notificationName, object: nil)
        loginButton.layer.cornerRadius = 5
    }
    
    // Function that configures the authentication parameters
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
    
    // Upon first login, initialize certain session objects
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

    // Handle the login once the button is pressed
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
    
    // delegate method that calls once the login was successful. Performs a segue to the main controller
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        print("audioStreamingDidLogin")
        self.performSegue(withIdentifier: "loginSuccessful", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // The segue goes into a TabBarController, we know the first view controller after the Tab bar is the SongViewController
        let tabVc = segue.destination as! UITabBarController
        let dvc = tabVc.viewControllers![0] as! SongViewController
        let playlistVC = tabVc.viewControllers![1] as! PlaylistViewController
        
        // send the access token and player over to the SongViewController
        dvc.spotifySession = self.session
        dvc.playlistVC = playlistVC
    }
}

