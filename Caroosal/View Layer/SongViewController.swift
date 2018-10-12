//
//  SongViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit

//Portions of this involving search bar created by Steven Gripshover
class SongViewController: UIViewController, SongSubscriber, UISearchBarDelegate {
    
    // MARK: - Properties
    var datasource:SongCollectionDatasource!
    var miniPlayer:MiniPlayerViewController?
    var currentSong: Song?
    var accessToken: String?
    var spotifySession: SPTSession?
    var player: SPTAudioStreamingController?
    var auth = SPTAuth.defaultInstance()!
    var currentMaxiCard:MaxiSongCardViewController?
    var playlistVC: PlaylistViewController?
    
    // MARK: - IBOutlets
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var searchBar: UISearchBar!
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        datasource = SongCollectionDatasource(collectionView: collectionView)
        collectionView.delegate = self
        searchBar.delegate = self
        self.accessToken = self.spotifySession?.accessToken
        initializePlayer(authSession: self.spotifySession!)
        if let token = self.accessToken {
            print(token)
            let queryURL = "search?q=Drake&type=track&market=US&limit=15&offset=0"
            // loads user's top songs as a default on load
            
//            Code to grab the current user's UID
//            SPTUser.requestCurrentUser(withAccessToken: token, callback: { (error, metadata) in
//
//            })
            
            SpotifyAPIController.shared.sendAPIRequest(apiURL: queryURL, accessToken: token, completionHandler: { data in
                if data == nil { // if the query is unsuccessful, load the canned songs from tutorial
                    print("Spotify Query nil, loading canned data")
                    //self.datasource.load()
                    return
                }
                let dict: [[String: Any]] = self.datasource.parseSpotifySearch(songs: data)
                self.datasource.loadSpotify(dict: dict)
            })
        }
        self.miniPlayer!.player = self.player
        print(self.playlistVC?.songs)
    }
    
    // Initialize the Spotify streaming controller
    // Code modeled off of Elon Rubin's tutorial
    func initializePlayer(authSession:SPTSession){
        // if the player has yet to be initialized, set initialize it w/ access token & set delegate
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player!.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken)
            print("Player was initialized")
            SpotifyPlayer.shared.setPlayer(player: self.player!)
        }
        else {
            print("Error Initializing Player")
        }
    }
    
    //Created by Steven Gripshover, allowing the user to see a search bar and for it to modify the URL given to the spotify API
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if let token = self.accessToken {
            let modifiedText = searchText.replacingOccurrences(of: " ", with: "%20")
            //Here is where the link is changed
            let queryURL = "search?q=\(modifiedText)&type=track&market=US&limit=15&offset=0"
            // loads user's top songs as a default
            SpotifyAPIController.shared.sendAPIRequest(apiURL: queryURL, accessToken: token, completionHandler: { data in
                let dict: [[String: Any]] = self.datasource.parseSpotifySearch(songs: data)
                print(dict)
                self.datasource.loadSpotify(dict: dict)
            })
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
        self.playlistVC?.songs.append((currentSong)!)
        SpotifyPlayer.shared.setPlaylist(newPlaylist: (self.playlistVC?.songs)!)
        self.playlistVC?.tableView.reloadData()
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
        print(self.currentMaxiCard!)
        //2. Take snapshot of current view
        maxiCard.backingImage = view.makeSnapshot()
        //3. Set current song in the Maxi Player
        maxiCard.currentSong = song
        //4. Set the source view
        maxiCard.sourceView = miniPlayer
        //5. Set the MaxiCard's player to the current SPT player
        maxiCard.player = self.player
        // 6. Present the Maxi Player
        present(maxiCard, animated: false)
    }
}

extension SongViewController: SPTAudioStreamingDelegate {
    // delegate method that calls once the login was successful. Performs a segue to the main controller
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        print("audioStreamingDidLogin")
    }
}

extension SongViewController: SPTAudioStreamingPlaybackDelegate {
    func audioStreamingDidLogout(_ audioStreaming: SPTAudioStreamingController!) {
        print("Logged Out")
    }
    func audioStreamingDidSkip(toNextTrack audioStreaming: SPTAudioStreamingController!) {
        print("Skipped To Next Track")
    }
    func audioStreamingDidSkip(toPreviousTrack audioStreaming: SPTAudioStreamingController!) {
        print("Skipped To Previous Track")
    }
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        print("Stopped Playing Track")
    }
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: String!) {
        print("Started Playing Track")
        print(trackUri)
        if let maxi = self.currentMaxiCard {
            let coverImageData = NSData(contentsOf: (SpotifyPlayer.shared.currentSong?.coverArtURL)!)
            maxi.backingImage = UIImage(data: coverImageData! as Data)
            
            if let songPlayer = maxi.songPlayerVC {
                songPlayer.currentSong = SpotifyPlayer.shared.currentSong
                songPlayer.configureFields()
            }
            
        }
    }
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didSeekToPosition position: TimeInterval) {
        print("Seeked to Position")
    }
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        self.miniPlayer?.refreshButtonState()
        print("Changed Playback Status")
        if let maxi = self.currentMaxiCard {
            print(maxi)
            if let songPlayer = maxi.songPlayerVC {
                songPlayer.updateButtons(isPlaying: isPlaying)
            }
        }
    }
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChange metadata: SPTPlaybackMetadata!) {
        print("Did Change")
        print(metadata.currentTrack?.artistName)
    }
}


