//
//  SongCollectionDatasource.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import SwiftyJSON
import FirebaseDatabase
import EmptyDataSet_Swift

// This file is base-code from Tutorial (https://www.raywenderlich.com/221-recreating-the-apple-music-now-playing-transition)
// Plus our modifications
class SongCollectionDatasource: NSObject {
    
    // MARK: - Properties
    var dataStack: DataStack
    var managedCollection: UICollectionView
    var ref: DatabaseReference
    
    // MARK: - Initializers
    init(collectionView: UICollectionView) {
        self.dataStack = DataStack()
        self.managedCollection = collectionView
        self.ref = Database.database().reference()
        super.init()
        self.managedCollection.dataSource = self
        self.managedCollection.emptyDataSetSource = self
        self.managedCollection.emptyDataSetDelegate = self
    }
    
    /**
     returns the song at the given index in the datastack
     - parameter at index: Index to search
     - Returns: The song at the given index
     */
    func song(at index: Int) -> Song {
        let realindex = index % dataStack.allSongs.count
        return dataStack.allSongs[realindex]
    }

    /**
     Load Spotify Function - Coded By Zachary Moore
     Takes a dictionary with the songs and their attributes and formats another dictionary for feeding into the dataStack load function.
     - parameter dict: dictionary of song metadata
     */
    func loadSpotify(dict: [[String: Any]]) {
        var dictionaryTest:[String: Any] = [:]
        dictionaryTest["Songs"] = dict
        dataStack.load(dictionary: dictionaryTest) { [weak self] success in
            self?.managedCollection.reloadData()
        }
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
            songDict["duration"] = song["duration_ms"].string
            songDict["coverArtURL"] = song["album"]["images"][0]["url"].string
            songDict["mediaURL"] = song["uri"].string
            songDict["databaseRef"] = self.ref.child("songs").child("queue").childByAutoId()
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
            songDict["duration"] = song["duration_ms"].string
            songDict["coverArtURL"] = song["album"]["images"][0]["url"].string
            songDict["mediaURL"] = song["uri"].string
            songDict["databaseRef"] = self.ref.child("songs").child("queue").childByAutoId()
            songArr.append(songDict)
        }
        return songArr
    }
    
}

// MARK: - UICollectionViewDataSource
// Set the cells within the collection view to represent songs in the datastack
extension SongCollectionDatasource: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataStack.allSongs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SongCell", for: indexPath) as? SongCell else {
            assertionFailure("Should have dequeued SongCell here")
            return UICollectionViewCell()
        }
        return configured(cell, at: indexPath)
    }
    
    func configured(_ cell: SongCell, at indexPath: IndexPath) -> SongCell {
        let isong = song(at: indexPath.row)
        cell.songTitle.text = isong.title
        cell.artistName.text = isong.artist
        isong.loadSongImage { image in
            cell.coverArt.image = image
        }
        return cell
    }
}

// MARK: - EmptyDataSetSource & EmptyDataSetDelegate
// Set the view to display message if there are no songs in the search query
extension SongCollectionDatasource: EmptyDataSetSource, EmptyDataSetDelegate {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "No results found"
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Please make sure your words are spelled correctly, or use a different search query."
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "search")
    }
}
