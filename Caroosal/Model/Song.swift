//
//  Song.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import FirebaseDatabase

// Song struct that stores metadata about a song object
// Originally from our midterm tutorial: https://www.raywenderlich.com/221-recreating-the-apple-music-now-playing-transition
struct Song {
    
    // MARK: - Properties
    let title: String
    var duration: Int = 0
    let artist: String
    var mediaURL: URL?
    var coverArtURL: URL?
    // Added the two properties below
    var voteCount: Int?
    var ref: DatabaseReference?
}
