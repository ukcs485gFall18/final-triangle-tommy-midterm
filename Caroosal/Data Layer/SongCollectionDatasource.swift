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
    var isAddingToQueue = false
    
    // MARK: - Initializers
    init(collectionView: UICollectionView) {
        self.dataStack = DataStack()
        self.managedCollection = collectionView
        self.ref = Database.database().reference()
        super.init()
        self.managedCollection.dataSource = self
        collectionView.allowsMultipleSelection = true
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
        cell.checkMark.style = .grayedOut
        cell.checkMark.setNeedsDisplay()
        
        if self.isAddingToQueue {
            cell.checkMark.checked = SpotifyPlayer.shared.containsSong(song: isong)
            cell.checkMark.isHidden = false
        }
        else {
            cell.checkMark.isHidden = true
        }
        
        return cell
    }
}
