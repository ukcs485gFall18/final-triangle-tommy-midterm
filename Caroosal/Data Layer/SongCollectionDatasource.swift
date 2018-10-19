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

// This file is base-code from Tutorial, plus our modifications
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
    }
    
    func song(at index: Int) -> Song {
        let realindex = index % dataStack.allSongs.count
        return dataStack.allSongs[realindex]
    }
    // old load() function from tutorial
    func load() {
        guard let file = Bundle.main.path(forResource: "CannedSongs", ofType: "plist") else {
            assertionFailure("bundle failure - couldnt load CannedSongs.plist - check it's added to target")
            return
        }
        if let dictionary = NSDictionary(contentsOfFile: file) as? [String: Any] {
            print(dictionary)
            dataStack.load(dictionary: dictionary) { [weak self] success in
                self?.managedCollection.reloadData()
            }
        }
    }
    
    //Load Spotify Function - Coded By Zachary Moore
    /*Takes a dictionary with the songs and their attributes and formats another dictionary for feeding into the dataStack load function.
     */
    func loadSpotify(dict: [[String: Any]]) {
        var dictionaryTest:[String: Any] = [:]
        dictionaryTest["Songs"] = dict
        dataStack.load(dictionary: dictionaryTest) { [weak self] success in
            self?.managedCollection.reloadData()
            print("reloaded data")
        }
    }
    
    //parsetSpotifyTracks function - Coded By Zachary Moore
    /* Takes the JSON provided by the Spotify API and creates an array of dictionaries for the songs. Grabs each song attribute from the API "items" array for allocation into the song dictionaries */
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
            songDict["databaseRef"] = self.ref.child("playlist").childByAutoId()
            songArr.append(songDict)
        }
        return songArr
    }
    
    //Created by Steven Gripshover
    //This function modified the spotify track search to get what songs were being searched in the search bar.
    func parseSpotifySearch(songs: JSON) -> [[String: Any]] {
        var songArr = [[String: Any]]()
        for i in 0..<songs["tracks"]["items"].count {
            var songDict: [String: Any] = [:]
            var song = songs["tracks"]["items"][i]
            print(song)
            songDict["title"] = song["name"].string
            songDict["artist"] = song["artists"][0]["name"].string
            songDict["duration"] = song["duration_ms"].string
            songDict["coverArtURL"] = song["album"]["images"][0]["url"].string
            songDict["mediaURL"] = song["uri"].string
            songDict["databaseRef"] = self.ref.child("playlist").childByAutoId()
            print(songDict)
            songArr.append(songDict)
        }
        return songArr
    }
    
}

// MARK: - UICollectionViewDataSource
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
