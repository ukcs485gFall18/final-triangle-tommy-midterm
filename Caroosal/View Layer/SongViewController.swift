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
import EmptyDataSet_Swift
import CFNotify

//Portions of this involving search bar created by Steven Gripshover
class SongViewController: UIViewController, SongSubscriber, UISearchBarDelegate {
    
    // MARK: - Properties
    var datasource:SongCollectionDatasource!
    var miniPlayer:MiniPlayerViewController?
    var currentSong: Song?
    var accessToken: String?
    var currentMaxiCard:MaxiSongCardViewController?
    var playlistVC: PlaylistViewController?
    var searchTimer: Timer?
    var isAddingToQueue = false // Bool to keep track if adding songs to queue
    var songsToAdd: [Song] = []
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var songSegment: UISegmentedControl!
    @IBOutlet weak var addButton: UIButton!
    
    
    @IBAction func songSegmentChanged(_ sender: Any) {
        switch songSegment.selectedSegmentIndex {
        case 0: // Search
            self.searchBar.isUserInteractionEnabled = true
            // perform a search w/ the contents of the search bar
            if let token = self.accessToken {
                var queryURL: String?
                let searchText = self.searchBar.text
                let modifiedText = searchText!.replacingOccurrences(of: " ", with: "%20")
                queryURL = "search?q=\(modifiedText)&type=track&market=US&limit=50&offset=0"
                self.performSpotifyQuery(queryURL: queryURL!)
            }
            
        case 1: // Recommendations
            self.searchBar.isUserInteractionEnabled = false
            SpotifyAPIController.shared.sendRecommendationsRequest(accessToken: self.accessToken!, completionHandler: { data in
                let dict: [[String: Any]] = SpotifyAPIController.shared.parseSpotifyRecommendations(songs: data)
                self.datasource.loadSpotify(dict: dict)
            })
        default:
            self.searchBar.isUserInteractionEnabled = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        datasource = SongCollectionDatasource(collectionView: collectionView)
        collectionView.delegate = self
        searchBar.delegate = self
        collectionView.emptyDataSetSource = self
        collectionView.emptyDataSetDelegate = self
        
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
    
    override func viewDidAppear(_ animated: Bool) {
        self.collectionView.reloadData()
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
            let dict: [[String: Any]] = SpotifyAPIController.shared.parseSpotifySearch(songs: data)
            self.datasource.loadSpotify(dict: dict)
        })
    }
    
    @IBAction func addButtonPressed(_ sender: Any) {
        if isAddingToQueue { // Hits the button when user is done adding songs
            
            if self.songsToAdd.count > 0 {
                for song in self.songsToAdd {
                    self.addToPlaylist(song: song)
                }
                
                // Add a success message
                var bodyStr: String?
                if self.songsToAdd.count == 1 {
                    bodyStr = "Successfully added 1 Song to the Queue!"
                }
                else {
                    bodyStr = "Successfully added \(self.songsToAdd.count) Songs to the Queue!"
                }
                var alertConfig = CFNotify.Config()
                alertConfig.hideTime = .custom(seconds: 1)
                let addedView = CFNotifyView.cyberWith(title: "Added to Queue",
                                                       body: bodyStr!,
                                                       theme: .success(.light))
                CFNotify.present(config: alertConfig, view: addedView)
            }
            
            // reset parameters
            self.songsToAdd.removeAll()
            self.datasource.isAddingToQueue = false
            addButton.setTitle("Add", for: .normal)
            self.isAddingToQueue = false
            self.collectionView.reloadData()
        }
        else { // User wants to add songs to queue
            addButton.setTitle("Done", for: .normal)
            self.datasource.isAddingToQueue = true
            self.isAddingToQueue = true
            self.collectionView.reloadData()
        }
    }
    
    //Created by Steven Gripshover, allowing the user to see a search bar and for it to modify the URL given to the spotify API
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTimer?.invalidate()
        
        // Timer code referenced from Andre: https://stackoverflow.com/questions/43327991/delayed-search-in-swift-ios-app
        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: false, block: { (timer) in
            if let token = self.accessToken {
                var queryURL: String?
                let modifiedText = searchText.replacingOccurrences(of: " ", with: "%20")
                queryURL = "search?q=\(modifiedText)&type=track&market=US&limit=50&offset=0"
                self.performSpotifyQuery(queryURL: queryURL!)
            }
        })
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
                let bodyStr = "Successfully added \"\(self.currentSong!.title)\" to the Queue!"
                var alertConfig = CFNotify.Config()
                alertConfig.hideTime = .custom(seconds: 1)
                let addedView = CFNotifyView.cyberWith(title: "Added to Queue",
                                                       body: bodyStr,
                                                       theme: .success(.light))
                CFNotify.present(config: alertConfig, view: addedView)
                self.addToPlaylist(song: self.currentSong!)
                self.collectionView.reloadData()
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
        var cell = collectionView.cellForItem(at: indexPath) as! SongCell
        if self.isAddingToQueue {
            print(self.songsToAdd)
            // user is undoing their choice to add the song
            for i in 0..<self.songsToAdd.count {
                let song = self.songsToAdd[i]
                if song.mediaURL?.absoluteString == currentSong!.mediaURL?.absoluteString {
                    self.songsToAdd.remove(at: i)
                    cell.checkMark.checked = false
                    return
                }
            }
            
            self.songsToAdd.append(currentSong!)
            cell.checkMark.checked = true
        }
        else {
            miniPlayer?.configure(song: currentSong)
            SpotifyPlayer.shared.startSong(song: currentSong!)
        }
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

// MARK: - EmptyDataSetSource & EmptyDataSetDelegate
// Set the view to display message if there are no songs in the search query
extension SongViewController: EmptyDataSetSource, EmptyDataSetDelegate {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        var str: String?
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        
        switch songSegment.selectedSegmentIndex {
        case 0: // Search
            str = "No Search Results Found"
        case 1: // Recommendations
            str = "No Recommendations"
        default:
            str = "No Search Results Found"
        }
        
        return NSAttributedString(string: str!, attributes: attrs)
        
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        var str: String?
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        
        switch songSegment.selectedSegmentIndex {
        case 0: // Search
            str = "Please make sure your words are spelled correctly, or use a different search query."
        case 1: // Recommendations
            str = "Begin to play some songs and we'll reccomend songs to play!"
        default:
            str = "Please make sure your words are spelled correctly, or use a different search query."
        }
        
        return NSAttributedString(string: str!, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "search")
    }
}
