//
//  FirebaseController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/23/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import FirebaseDatabase

class FirebaseController: NSObject {
    static let shared = FirebaseController()
    
    override init(){
        super.init()
        self.ref = Database.database().reference()
    }
    var ref: DatabaseReference!
    
    // Parse the data snapshot for the song queue changes
    func parseQueueSnapshot(snapshot: DataSnapshot) -> [Song]{
        var dataStack = DataStack()
        let playlistDict = snapshot.value as? [String: Any]
        if let songDict = playlistDict {
            var songArr = [[String: Any]]()
            for item in songDict {
                let newRef = self.ref!.child("songs").child("queue").child(item.key)
                var songVals = item.value as! [String: Any]
                let artist = songVals["Artist"] as! String
                let coverURL = songVals["CoverURL"] as! String
                let duration = 0
                let mediaURL = songVals["MediaURL"] as! String
                let title = songVals["Title"] as! String
                let voteCount = songVals["VoteCount"] as! Int
                let newDict: [String: Any] = ["title": title, "artist": artist, "coverArtURL": coverURL, "duration": duration, "mediaURL": mediaURL, "voteCount": voteCount, "databaseRef": newRef]
                songArr.append(newDict)
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
    
    // builds the current song from a data snapshot
    func buildSongFromSnapshot(snapshot: DataSnapshot) -> Song? {
        let songVals = snapshot.value as? [String: Any]
        let newRef = self.ref!.child("songs").child("currentSong")
        let artist = songVals!["Artist"] as! String
        let coverURL = songVals!["CoverURL"] as! String
        let duration = 0
        let mediaURL = songVals!["MediaURL"] as! String
        let title = songVals!["Title"] as! String
        let voteCount = songVals!["VoteCount"] as! Int
        
        let song = Song(title: title, duration: TimeInterval(duration), artist: artist, mediaURL: URL(string: mediaURL), coverArtURL: URL(string: coverURL), voteCount: voteCount, ref: newRef)
        return song
    }
    
    
}
