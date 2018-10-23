//
//  Song.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import FirebaseDatabase
// This file is base-code from Tutorial
struct Song {
    
    // MARK: - Properties
    let title: String
    var duration: TimeInterval = 0
    let artist: String
    var mediaURL: URL?
    var coverArtURL: URL?
    var voteCount: Int?
    var ref: DatabaseReference?
}
