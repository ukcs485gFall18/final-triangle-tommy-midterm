//
//  SongPlayControlViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit

// This file is base-code from Tutorial (https://www.raywenderlich.com/221-recreating-the-apple-music-now-playing-transition)
// Plus our modifications
class SongPlayControlViewController: UIViewController, SongSubscriber {
    
    var player: SPTAudioStreamingController?
    
    // MARK: - IBOutlets
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var songArtist: UILabel!
    @IBOutlet weak var songDuration: UILabel!
    @IBOutlet weak var playButton: UIButton!
    
    // MARK: - Properties
    var currentSong: Song? {
        didSet {
            configureFields()
        }
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configureFields()
        let stoppedNotification = Notification.Name("songStoppedPlaying")
        let startedNotification = Notification.Name("songStartedPlaying")
        let changedPlaybackName = Notification.Name("changedPlaybackStatus")
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateButtons), name: stoppedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.configureFields), name: startedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateButtons), name: changedPlaybackName, object: nil)
    }

    /**
        Update the buttons depending on the current playback status of the song
    */
    @objc func updateButtons(){
        switch SpotifyPlayer.shared.currentPlaybackState {
        case .isNil?:
            print("shouldn't happen")
        case .isPlaying?: // if the player is currently playing, pause the current song
            self.playButton.setImage(UIImage(named: "pause"), for: .normal)
        case .isPaused?: // if the player is currently paused, resume the song
            self.playButton.setImage(UIImage(named: "play"), for: .normal)
        case .none:
            print("shouldn't happen")
        }
    }
    
    @objc func changeCoverImage(){
        self.currentSong = SpotifyPlayer.shared.currentSong
        self.configureFields()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateButtons()
    }
    
    /**
     User hits the play button, and the player status is refreshed
     */
    @IBAction func playButtonTapped(_ sender: Any) {
        switch SpotifyPlayer.shared.currentPlaybackState {
            case .isNil?: // if the player is not yet initialized, play the current song
                SpotifyPlayer.shared.startSong(song: currentSong!)
                self.playButton.setImage(UIImage(named: "pause"), for: .normal)
            case .isPlaying?: // if the player is currently playing, pause the current song
                self.playButton.setImage(UIImage(named: "play"), for: .normal)
                SpotifyPlayer.shared.pauseSong()
            case .isPaused?: // if the player is currently paused, resume the song
                self.playButton.setImage(UIImage(named: "pause"), for: .normal)
                SpotifyPlayer.shared.resumeSong()
            case .none:
                print("shouldn't happen")
        }
    }
    
    /**
     User hits the next button, and the player status is refreshed
     */
    @IBAction func nextTapped(_ sender: Any) {
        if (SpotifyPlayer.shared.currentPlaylist?.isEmpty)! { // Playlist is empty
            let alert = UIAlertController(title: "No Songs in Queue", message: "You can't skip if the queue is empty.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else {
            var newSong = SpotifyPlayer.shared.skipToNextSong()
        }
    }
    
}

// MARK: - Internal
extension SongPlayControlViewController {
    
    @objc func configureFields() {
        print("configuring fields!!!!!!!!")
        guard songTitle != nil else {
            return
        }
        songTitle.text = currentSong?.title
        songArtist.text = currentSong?.artist
        songDuration.text = "Duration \(currentSong?.presentationTime ?? "")"
    }
}

// MARK: - Song Extension
extension Song {
    
    var presentationTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        let date = Date(timeIntervalSince1970: duration)
        return formatter.string(from: date)
    }
}
