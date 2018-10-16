//
//  SongPlayControlViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit

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
    }

    func updateButtons(){
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
    override func viewDidAppear(_ animated: Bool) {
        updateButtons()
    }
    
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
    
    @IBAction func nextTapped(_ sender: Any) {
        if (SpotifyPlayer.shared.currentPlaylist?.isEmpty)! {
            let alert = UIAlertController(title: "No Songs in Queue", message: "You can't skip if the queue is empty.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else {
            var newSong = SpotifyPlayer.shared.skipToNextSong()
        }
    }
    
    //Plus button that adds the song to the play list in the big player
    @IBAction func plusButton(_ sender: Any) {
        
         SpotifyPlayer.shared.addToPlaylist(song: SpotifyPlayer.shared.currentSong!)
    }
    
}

// MARK: - Internal
extension SongPlayControlViewController {
    
    func configureFields() {
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
