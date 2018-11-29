//
//  SongBuilder.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import Foundation
import FirebaseDatabase

// This file is base-code from Tutorial (https://www.raywenderlich.com/221-recreating-the-apple-music-now-playing-transition)
class SongBuilder: NSObject {
    
    // MARK: - Properties
    private var title: String?
    private var duration: Int = 0
    private var artist: String?
    private var mediaURL: URL?
    private var coverArtURL: URL?
    private var voteCount: Int = 0
    private var ref: DatabaseReference?
    
    func build() -> Song? {
        guard let title = title,
            let artist = artist else {
                return nil
        }
        
        return Song(title: title, duration: duration, artist: artist, mediaURL: mediaURL, coverArtURL: coverArtURL, voteCount: voteCount, ref: ref)
    }
    
    func with(title: String?) -> Self {
        self.title = title
        return self
    }
    
    func with(duration: Int?) -> Self {
        self.duration = duration ?? 0
        return self
    }
    
    func with(artist: String?) -> Self {
        self.artist = artist
        return self
    }
    
    func with(mediaURL url: String?) -> Self {
        guard let urlstring = url else {
            return self
        }
        
        self.mediaURL = URL(string: urlstring)
        return self
    }
    
    func with(coverArtURL url: String?) -> Self {
        guard let urlstring = url else {
            return self
        }
        
        self.coverArtURL = URL(string: urlstring)
        return self
    }
    
    func with(voteCount: Int?) -> Self {
        self.voteCount = voteCount ?? 0
        return self
    }
    
    func with(databaseRef: DatabaseReference?) -> Self {
        guard let songRef = databaseRef else {
            return self
        }
        self.ref = databaseRef
        return self
    }
    
}
