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
    
    @IBOutlet weak var songProgressSlider: UISlider!
    @IBOutlet weak var songProgressLabel: UILabel! // label that shows current song progress
    @IBOutlet weak var sliderDurationLabel: UILabel! // slider label that shows total song duration
    
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
        let updatedSongProgress = Notification.Name("updatedSongProgress")
        
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateButtons), name: stoppedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeCoverImage), name: startedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateButtons), name: changedPlaybackName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateProgressSlider(_:)), name: updatedSongProgress, object: nil)
        
        // prevent the user from moving the slider
        self.songProgressSlider.isUserInteractionEnabled = false
    }
    
    // update the buttons on appear
    override func viewDidAppear(_ animated: Bool) {
        updateButtons()
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
    
    /**
     Changes the cover image
     */
    @objc func changeCoverImage(){
        self.currentSong = SpotifyPlayer.shared.currentSong
        self.configureFields()
    }
    
    /**
     Updates the song progress slider every time the player receives a notification that the progress was changed
     */
    @objc func updateProgressSlider(_ notification: Notification){
        if let data = notification.userInfo as? [String: Any] {
            // update the progress slider
            if let progress = data["progress"] as? Double {
                self.songProgressSlider.setValue(Float(progress), animated: true)
            }
            // set the song label to indicate elapsed progress
            if let elapsedTime = data["elapsedTime"] as? TimeInterval {
                let formatter = DateFormatter()
                formatter.dateFormat = "mm:ss"
                let date = Date(timeIntervalSince1970: elapsedTime / 1000.0)
                self.songProgressLabel.text = formatter.string(from: date)
            }
        }
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
        SpotifyPlayer.shared.addHistory()
        if (SpotifyPlayer.shared.currentPlaylist?.isEmpty)! { // playlist is empty
            SpotifyPlayer.shared.startRecommendedSong(completion: { songs in
                if(songs.count > 0){
                    self.currentSong = songs[0]
                    self.playButton.setImage(UIImage(named: "pause"), for: .normal)
                    SpotifyPlayer.shared.startSong(song: songs[0])
                }
                else {
                    let alert = UIAlertController(title: "No Recommended Songs", message: "Please play songs and recommendations will appear", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
            })
        }
        else {
            let _ = SpotifyPlayer.shared.skipToNextSong()
        }
    }
}

// MARK: - Internal
extension SongPlayControlViewController {
    
    @objc func configureFields() {
        guard songTitle != nil else {
            return
        }
        songTitle.text = currentSong?.title
        songArtist.text = currentSong?.artist
        songDuration.text = "Duration \(currentSong?.presentationTime ?? "")"
        sliderDurationLabel.text = currentSong?.presentationTime ?? ""
    }
}

// MARK: - Song Extension
extension Song {
    
    var presentationTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm:ss"
        let date = Date(timeIntervalSince1970: Double(duration) / 1000.0)
        return formatter.string(from: date)
    }
}
