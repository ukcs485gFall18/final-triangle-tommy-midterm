//
//  SpotifyAPIController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

// New file added: API Querying Code written by Thomas Deeter
class SpotifyAPIController: NSObject {
    
    static let shared = SpotifyAPIController() // static reference to the class
    let baseSpotifyUrl = "https://api.spotify.com/v1/" // URL of the Spotify API endpoint
    
    /**
     Code to send an API request to the Spotify API, and parse through the returned JSON
     - parameter apiURL: The base URL of the API endpoint
     - parameter accessToken: The Spotify access token needed to query API
     - parameter completionHandler: Code that executes upon completion of API request
     */
    func sendAPIRequest(apiURL: String, accessToken: String, completionHandler: @escaping (JSON) ->Void){
        // set access token in the HTTP Request
        let token = "Bearer \(accessToken)"
        let headers = ["Accept":"application/json", "Authorization": token]
        let queryURL = baseSpotifyUrl + apiURL
        // send GET request and do completion handler on response JSON
        Alamofire.request(queryURL, method: .get, parameters: nil, headers: headers).responseJSON(completionHandler: {
            response in
            if response.data != nil {
                let jsonData = JSON(response.data!)
                completionHandler(jsonData)
            }
        })
    }
    
}
