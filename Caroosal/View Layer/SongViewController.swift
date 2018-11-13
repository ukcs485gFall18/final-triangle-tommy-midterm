//
//  SongViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import AVKit
import SwiftSpinner

//Portions of this involving search bar created by Steven Gripshover
class SongViewController: UIViewController, SongSubscriber, UISearchBarDelegate {
    
    // MARK: - Properties
    var datasource:SongCollectionDatasource!
    var miniPlayer:MiniPlayerViewController?
    var currentSong: Song?
    var accessToken: String?
    var currentMaxiCard:MaxiSongCardViewController?
    var playlistVC: PlaylistViewController?
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datasource = SongCollectionDatasource(collectionView: collectionView)
        collectionView.delegate = self
        searchBar.delegate = self
        
        // Long Press gesture code referenced from
        // https://stackoverflow.com/questions/18848725/long-press-gesture-on-uicollectionviewcell
        let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gestureReconizer:)))
        lpgr.minimumPressDuration = 0.5
        lpgr.delaysTouchesBegan = true
        self.collectionView.addGestureRecognizer(lpgr)
        
        if let _ = self.accessToken {
            // runs a query for Drake songs on load
            let queryURL = "search?q=Drake&type=track&market=US&limit=15&offset=0"
            self.performSpotifyQuery(queryURL: queryURL)
        }
    }
    
    /**
     Perform a Spotify API Query
     - parameter queryURL: endpoint of url to query
     */
    func performSpotifyQuery(queryURL: String){
        SpotifyAPIController.shared.sendAPIRequest(apiURL: queryURL, accessToken: self.accessToken!, completionHandler: { data in
            if data == nil { // if the query is unsuccessful, load the canned songs from tutorial
                print("Spotify Query nil")
                return
            }
            let dict: [[String: Any]] = self.datasource.parseSpotifySearch(songs: data)
            self.datasource.loadSpotify(dict: dict)
        })
    }
    
    //Created by Steven Gripshover, allowing the user to see a search bar and for it to modify the URL given to the spotify API
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let token = self.accessToken {
            var queryURL: String?
            if searchText.isEmpty {
                queryURL = "search?q=Drake&type=track&market=US&limit=50&offset=0"
            }
            else {
                let modifiedText = searchText.replacingOccurrences(of: " ", with: "%20")
                queryURL = "search?q=\(modifiedText)&type=track&market=US&limit=50&offset=0"
            }
            self.performSpotifyQuery(queryURL: queryURL!)
        }
    }
    
    /**
     Add a song to the shared Spotify controller object playlist
     - parameter song: the song to add to the playlist
     */
    func addToPlaylist(song: Song){
        SpotifyPlayer.shared.addToPlaylist(song: song, isCurrent: false)
        self.playlistVC?.tableView.reloadData()
    }
    
    /**
     Handler for long press gestures
     - parameter gestureRecognizer: the recognizer that will execute this code
     */
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizerState.ended {
            return
        }
        // Grab the location of the touch in the collection view
        let p = gestureReconizer.location(in: self.collectionView)
        // construct the index path of the item
        let indexPath = self.collectionView.indexPathForItem(at: p)
        if let index = indexPath {
            currentSong = datasource.song(at: index.row)
            // Present alert asking if they want to add the song to the playlist
            let alert = UIAlertController(title: "Add to Playlist", message: "Would you like to add \"\(currentSong!.title)\" to the playlist?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: {(action) in
                self.addToPlaylist(song: self.currentSong!)
            }))
            self.present(alert, animated: true)
        } else {
            print("Unable to find index path")
        }
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? MiniPlayerViewController {
            miniPlayer = destination
            miniPlayer?.delegate = self
        }
    }
}

// MARK: - UICollectionViewDelegate
extension SongViewController: UICollectionViewDelegate {
    // set the current song when an item is tapped in the CollectionView
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        currentSong = datasource.song(at: indexPath.row)
        miniPlayer?.configure(song: currentSong)
        SpotifyPlayer.shared.startSong(song: currentSong!)
    }
}

extension SongViewController: MiniPlayerDelegate {
    func expandSong(song: Song) {
        //1. Instantiate the MaxiSongCardViewController to display close-up of song
        guard let maxiCard = storyboard?.instantiateViewController(
            withIdentifier: "MaxiSongCardViewController")
            as? MaxiSongCardViewController else {
                assertionFailure("No view controller ID MaxiSongCardViewController in storyboard")
                return
        }
        self.currentMaxiCard = maxiCard
        //2. Take snapshot of current view
        maxiCard.backingImage = view.makeSnapshot()
        //3. Set current song in the Maxi Player
        maxiCard.currentSong = song
        //4. Set the source view
        maxiCard.sourceView = miniPlayer
        //5. Set the MaxiCard's player to the current SPT player
//        maxiCard.player = self.player
        // 6. Present the Maxi Player
        present(maxiCard, animated: false)
    }
}
