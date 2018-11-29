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
import FirebaseDatabase

// New file added: API Querying Code written by Thomas Deeter
class SpotifyAPIController: NSObject {
    
    static let shared = SpotifyAPIController() // static reference to the class
    let baseSpotifyUrl = "https://api.spotify.com/v1/" // URL of the Spotify API endpoint
    var ref: DatabaseReference
    
    override init(){
        self.ref = Database.database().reference()
        super.init()
    }
    
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
    
    // grab up to 5 random tracks that you've played so far, and display them
    func sendRecommendationsRequest(accessToken: String, completionHandler: @escaping (JSON) ->Void){
        var seedTracks = ""
        let playedTracks = SpotifyPlayer.shared.previousPlayedURI?.shuffled()
        if playedTracks!.isEmpty {
            print("Spotify Query nil")
            completionHandler(nil)
            return
        }
        var i=0
        // iterate through the length of played tracks, or the first 5
        while i < 5 || i < playedTracks!.count {
            seedTracks = seedTracks + playedTracks![i]
            i = i + 1
            if i == 5 || i == playedTracks!.count {
                break
            }
            // add comma in between
            seedTracks = seedTracks + ","
        }
        
        let queryURL = "recommendations?limit=25&market=US&seed_tracks=\(seedTracks)"
        sendAPIRequest(apiURL: queryURL, accessToken: accessToken, completionHandler: { data in
            print("querying recommendations!")
            if data == nil { // if the query is unsuccessful, load the canned songs from tutorial
                completionHandler(nil)
                return
            }
            completionHandler(data)
        })
    }
    
    /**
     Parse Spotify Tracks Function - Coded By Zachary Moore
     Takes the JSON provided by the Spotify API and creates an array of dictionaries for the songs.
     Grabs each song attribute from the API "items" array for allocation into the song dictionaries
     - parameter songs: JSON of song metadata from API query response
     - Returns: Dictionary constructed from that data
     */
    func parseSpotifyTracks(songs: JSON) -> [[String: Any]] {
        var songArr = [[String: Any]]() //create return array
        for i in 0..<songs["items"].count { //Loop through the API array for each song
            var songDict: [String: Any] = [:]
            //Assign the necessary attributes
            var song = songs["items"][i]
            songDict["title"] = song["name"].string
            songDict["artist"] = song["artists"][0]["name"].string
            songDict["duration"] = song["duration_ms"].int
            songDict["coverArtURL"] = song["album"]["images"][0]["url"].string
            songDict["mediaURL"] = song["uri"].string
            let newRef = self.ref.child("songs/queue").child(SpotifyPlayer.shared.currentParty!.host).childByAutoId()
            songDict["databaseRef"] = newRef
            songArr.append(songDict)
        }
        return songArr
    }
    
    
    /**
     Parse Spotify Tracks Function - Created by Steven Gripshover
     Similar to the function parseSpotifyTracks() above, just with slightly different API response structure
     - parameter songs: JSON of song metadata from API query response
     - Returns: Dictionary constructed from that data
     */
    func parseSpotifySearch(songs: JSON) -> [[String: Any]] {
        var songArr = [[String: Any]]()
        for i in 0..<songs["tracks"]["items"].count {
            var songDict: [String: Any] = [:]
            var song = songs["tracks"]["items"][i]
            songDict["title"] = song["name"].string
            songDict["artist"] = song["artists"][0]["name"].string
            songDict["duration"] = song["duration_ms"].int
            songDict["coverArtURL"] = song["album"]["images"][0]["url"].string
            songDict["mediaURL"] = song["uri"].string
            let newRef = self.ref.child("songs/queue").child(SpotifyPlayer.shared.currentParty!.host).childByAutoId()
            songDict["databaseRef"] = newRef
            songArr.append(songDict)
        }
        return songArr
    }
    
    
    /**
     Parse Spotify Tracks Function - Created by Thomas Deeter
     Similar to the function parseSpotifyTracks() above, just with slightly different API response structure for Recomendations
     - parameter songs: JSON of song metadata from API query response
     - Returns: Dictionary constructed from that data
     */
    func parseSpotifyRecommendations(songs: JSON) -> [[String: Any]] {
        var songArr = [[String: Any]]()
        for i in 0..<songs["tracks"].count {
            var songDict: [String: Any] = [:]
            var song = songs["tracks"][i]
            songDict["title"] = song["name"].string
            songDict["artist"] = song["artists"][0]["name"].string
            songDict["duration"] = song["duration_ms"].int
            songDict["coverArtURL"] = song["album"]["images"][0]["url"].string
            songDict["mediaURL"] = song["uri"].string
            let newRef = self.ref.child("songs/queue").child(SpotifyPlayer.shared.currentParty!.host).childByAutoId()
            songDict["databaseRef"] = newRef
            songArr.append(songDict)
        }
        return songArr
    }
}
