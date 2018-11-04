//
//  DataStack.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import CoreData
import FirebaseDatabase

// This file is base-code from Tutorial (https://www.raywenderlich.com/221-recreating-the-apple-music-now-playing-transition)
enum DataStackState {
    case unloaded
    case loaded
}

class DataStack: NSObject {
    
    // MARK: - Properties
    private(set) var allSongs: [Song] = []
    
    /**
     Loads an array of song metadata and constructs an array of Songs from it
     - parameter dictionary: The song metadata to parse
     - parameter completion: Code that executes upon completion of API request
     */
    func load(dictionary: [String: Any], completion: (Bool) -> Void) {
        allSongs.removeAll()
        if let songs = dictionary["Songs"] as? [[String: Any]] {
            for songDictionary in songs {
                let builder = SongBuilder()
                    .with(title: (songDictionary["title"] as? String))
                    .with(artist: songDictionary["artist"] as? String)
                    .with(duration: songDictionary["duration"] as? TimeInterval)
                    .with(mediaURL: songDictionary["mediaURL"] as? String)
                    .with(coverArtURL: songDictionary["coverArtURL"] as? String)
                    .with(voteCount: songDictionary["voteCount"] as? Int)
                    .with(databaseRef: songDictionary["databaseRef"] as? DatabaseReference)
                
                if let song = builder.build() {
                    allSongs.append(song)
                }
            }
            completion(true)
        } else {
            completion(false)
        }
    }
}



