//
//  DataStack.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import CoreData

enum DataStackState {
    case unloaded
    case loaded
}

// This file is base-code from Tutorial
class DataStack: NSObject {
    
    // MARK: - Properties
    private(set) var allSongs: [Song] = []
    
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



