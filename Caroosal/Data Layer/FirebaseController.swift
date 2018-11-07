//
//  FirebaseController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/23/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import FirebaseDatabase

// Singleton Firebase controller class to control Firebase CRUD operations
// Created by Tommy Deeter
class FirebaseController: NSObject {
    static let shared = FirebaseController() // static instance that is accessed throughout app
    
    override init(){
        super.init()
        self.ref = Database.database().reference()
    }
    var ref: DatabaseReference! // reference to database
    
    /**
     Parse Spotify Tracks Function - Coded By Thomas Deeter
     Parse the data snapshot for the song queue changes
     - parameter snapshot: firebase data snapshot of song data
     - Returns: Array of songs constructed from the snapshot
     */
    func parseQueueSnapshot(snapshot: DataSnapshot) -> [Song]{
        var dataStack = DataStack()
        let playlistDict = snapshot.value as? [String: Any]
        if let songDict = playlistDict {
            var songArr = [[String: Any]]()
            // Iterate through each item in the snapshot and grab their metadata & parse into Song object
            for item in songDict {
                let newRef = self.ref.child("songs/queue").child(SpotifyPlayer.shared.currentParty!.host).child(item.key)
                var songVals = item.value as! [String: Any]
                if songVals != nil {
                    print(songVals)
                    let artist = songVals["Artist"] as! String
                    print(artist)
                    let coverURL = songVals["CoverURL"] as! String
                    let duration = 0
                    let mediaURL = songVals["MediaURL"] as! String
                    let title = songVals["Title"] as! String
                    let voteCount = songVals["VoteCount"] as! Int
                    let newDict: [String: Any] = ["title": title, "artist": artist, "coverArtURL": coverURL, "duration": duration, "mediaURL": mediaURL, "voteCount": voteCount, "databaseRef": newRef]
                    songArr.append(newDict)
                }
                else {
                    print("nil song vals!!!!")
                }
            }
            var dictionaryTest:[String: Any] = [:]
            dictionaryTest["Songs"] = songArr
            dataStack.load(dictionary: dictionaryTest) { [weak self] success in
                print(dataStack.allSongs)
            }
            return dataStack.allSongs
        }
        return []
    }
    
    /**
     Builds a single song from a data snapshot
     - parameter snapshot: firebase data snapshot of song data
     - Returns: a song constructed from the data snapshot
     */
    func buildSongFromSnapshot(snapshot: DataSnapshot) -> Song? {
        let songVals = snapshot.value as? [String: Any]
        let newRef = self.ref.child("songs/currentSong").child(SpotifyPlayer.shared.currentParty!.host)
        let artist = songVals!["Artist"] as! String
        let coverURL = songVals!["CoverURL"] as! String
        let duration = 0
        let mediaURL = songVals!["MediaURL"] as! String
        let title = songVals!["Title"] as! String
        let voteCount = songVals!["VoteCount"] as! Int
        
        let song = Song(title: title, duration: TimeInterval(duration), artist: artist, mediaURL: URL(string: mediaURL), coverArtURL: URL(string: coverURL), voteCount: voteCount, ref: newRef)
        return song
    }
    
    /**
     Builds a single party from a data snapshot
     - parameter snapshot: firebase data snapshot of party data
     - Returns: a party constructed from the data snapshot
     */
    func buildPartyFromSnapshot(snapshot: DataSnapshot) -> Party? {
        let partyVals = snapshot.value as? [String: Any]
        if partyVals != nil {
            let name = partyVals!["Name"] as! String
            let password = partyVals!["Password"] as! String
            let host = snapshot.key
            let party = Party(name: name, password: password, host: host)
            return party
        }
        return nil
    }
    
}
