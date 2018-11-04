//
//  AppDelegate.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var auth = SPTAuth()
    // AppDelegate code added by Thomas Deeter: SpotifyLogin Functionality
    // AppDelegate code partially referenced from Elon Rubin's Tutorial on Spotify login
    // URL: https://medium.com/@elonrubin/ios-spotify-sdk-swift-3-0-tutorial-b629af4b889d
    // All this file is new functionality added
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Add Spotify auth and Firebase config details
        auth.redirectURL = URL(string: "tdeets.razeware.RazePlayer://")
        auth.sessionUserDefaultsKey = "current session"
        FirebaseApp.configure()
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        // Check if app can handle the URL
        if auth.canHandle(auth.redirectURL) {
            auth.handleAuthCallback(withTriggeredAuthURL: url, callback: { (error, session) in
                // handle error
                if error != nil {
                    print("error!")
                }
                // Add session to User Defaults
                let userDefaults = UserDefaults.standard
                let sessionData = NSKeyedArchiver.archivedData(withRootObject: session)
                userDefaults.set(sessionData, forKey: "SpotifySession")
                userDefaults.synchronize()
                // Tell notification center login is successful
                NotificationCenter.default.post(name: Notification.Name(rawValue: "loginSuccessful"), object: nil)
            })
            return true
        }
        return false
        
    }
}
