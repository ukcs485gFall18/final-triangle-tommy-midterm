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
        let playlistDict = snapshot.value as? [String: Any]
        var songsToReturn = [Song]()
        if let songDict = playlistDict {
            // Iterate through each item in the snapshot and grab their metadata & parse into Song object
            for item in songDict {
                let newRef = self.ref.child("songs/queue").child(SpotifyPlayer.shared.currentParty!.host).child(item.key)
                var songVals = item.value as? [String: Any]
                if songVals != nil {
                    let builder = SongBuilder()
                        .with(title: songVals!["Title"] as? String)
                        .with(artist: songVals!["Artist"] as? String)
                        .with(duration: songVals!["Duration"] as? Int)
                        .with(mediaURL: songVals!["MediaURL"] as? String)
                        .with(coverArtURL: songVals!["CoverURL"] as? String)
                        .with(voteCount: songVals!["VoteCount"] as? Int)
                        .with(databaseRef: newRef)
                    
                    if let song = builder.build() {
                        songsToReturn.append(song)
                    }
                }
            }
        }
        return songsToReturn
    }
    
    /**
     Builds a single song from a data snapshot
     - parameter snapshot: firebase data snapshot of song data
     - Returns: a song constructed from the data snapshot
     */
    func buildSongFromSnapshot(snapshot: DataSnapshot) -> Song? {
        let songVals = snapshot.value as? [String: Any]
        if SpotifyPlayer.shared.currentParty != nil {
            let newRef = self.ref.child("songs/currentSong").child(SpotifyPlayer.shared.currentParty!.host)
            if songVals != nil {
                let builder = SongBuilder()
                    .with(title: songVals!["Title"] as? String)
                    .with(artist: songVals!["Artist"] as? String)
                    .with(duration: songVals!["Duration"] as? Int)
                    .with(mediaURL: songVals!["MediaURL"] as? String)
                    .with(coverArtURL: songVals!["CoverURL"] as? String)
                    .with(voteCount: songVals!["VoteCount"] as? Int)
                    .with(databaseRef: newRef)
            
                if let song = builder.build() {
                    return song
                }
            }
        }
        return nil
    }
    
    /**
     Builds a single party from a data snapshot
     - parameter snapshot: firebase data snapshot of individual party data
     - Returns: a party constructed from the data snapshot
     */
    func buildPartyFromSnapshot(snapshot: DataSnapshot) -> Party? {
        let partyVals = snapshot.value as? [String: Any]
        if partyVals != nil {
            let builder = PartyBuilder()
                .with(name: partyVals!["Name"] as? String)
                .with(password: partyVals!["Password"] as? String)
                .with(host: snapshot.key)
                .with(databaseRef: snapshot.ref)
            if let party = builder.build() {
                return party
            }
        }
        return nil
    }
    
    /**
     Gets all the parties from the database
     - parameter snapshot: firebase data snapshot of all party data
     - Returns: a party constructed from the data snapshot
     */
    func getAllParties(snapshot: DataSnapshot) -> [Party] {
        var allParties = [Party]()
        var allChildren = snapshot.children.allObjects
        var currentChild: DataSnapshot?
        for i in 0..<allChildren.count {
            currentChild = allChildren[i] as? DataSnapshot
            if currentChild != nil {
                let newParty = self.buildPartyFromSnapshot(snapshot: currentChild!)
                if newParty != nil {
                    allParties.append(newParty!)
                }
            }
        }
        return allParties
    }
    
    
}
