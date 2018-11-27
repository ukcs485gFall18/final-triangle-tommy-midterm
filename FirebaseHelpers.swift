//
//  FirebaseHelpers.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/16/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import FirebaseDatabase

extension Song {
    // returns the object as a dict so we can write it to firebase
    func toDict() -> [String: Any] {
        let anyDict: [String: Any] = ["Title": self.title,
                                      "Duration": self.duration,
                                      "Artist": self.artist,
                                      "MediaURL": self.mediaURL?.absoluteString,
                                      "CoverURL": self.coverArtURL?.absoluteString,
                                      "VoteCount": self.voteCount]
        return anyDict
    }
    
    mutating func setRef(newRef: DatabaseReference){
        self.ref = newRef
    }
}

extension Party {
    // deletes the party related firebase data
    func endParty() {
        self.ref.removeValue()
        let baseRef = Database.database().reference()
        let currentRef = baseRef.child("songs/currentSong").child(self.host)
        let queueRef = baseRef.child("songs/queue").child(self.host)
        queueRef.removeValue()
        currentRef.removeValue()
    }
}

