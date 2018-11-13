//
//  MiniPlayerViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit

protocol MiniPlayerDelegate: class {
    func expandSong(song: Song)
}

// This file is base-code from Tutorial (https://www.raywenderlich.com/221-recreating-the-apple-music-now-playing-transition)
// Plus our modifications
class MiniPlayerViewController: UIViewController, SongSubscriber {
    
    // MARK: - Properties
    var currentSong: Song?
    weak var delegate: MiniPlayerDelegate?
    
    @IBOutlet weak var thumbImage: UIImageView!
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var ffButton: UIButton!
    @IBOutlet weak var plusButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure(song: nil)
        let startedName = Notification.Name("songStoppedPlaying")
        let changedPlaybackName = Notification.Name("changedPlaybackStatus")
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshButtonState), name: startedName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshButtonState), name: changedPlaybackName, object: nil)
    }
    
    /**
     Refresh the button state when the view reappears
     Can't call viewDidAppear because the view technically doesn't disappear
    */
    @objc func refreshButtonState() {
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
        self.configure(song: SpotifyPlayer.shared.currentSong)
    }
    
    /**
     User hits the play button
     Either begins a new song, or resumes the current song
     */
    @IBAction func playButtonTapped(_ sender: Any) {
        switch SpotifyPlayer.shared.currentPlaybackState {
        case .isNil?: // if the player is not yet initialized, play the current song
            // if there is no song selected and the playlist is not empty
            if currentSong == nil {
                if (SpotifyPlayer.shared.currentPlaylist?.isEmpty)! {
                    let alert = UIAlertController(title: "Playlist is Empty", message: "Please select a song or add one to the playlist", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
                    self.present(alert, animated: true)
                }
                else {
                    currentSong = SpotifyPlayer.shared.skipToNextSong()
                    self.configure(song: currentSong)
                    self.playButton.setImage(UIImage(named: "pause"), for: .normal)
                }
            }
            else {
                SpotifyPlayer.shared.startSong(song: currentSong!)
                self.playButton.setImage(UIImage(named: "pause"), for: .normal)
            }
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
     User hits the next button
     Either begins a new song, or show alert that the queue is empty
     */
    @IBAction func nextButtonTapped(_ sender: Any) {
        if (SpotifyPlayer.shared.currentPlaylist?.isEmpty)! { // alert user that queue is empty
            let alert = UIAlertController(title: "No Songs in Queue", message: "You can't skip if the queue is empty.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
        else {
            var newSong = SpotifyPlayer.shared.skipToNextSong()
            self.configure(song: newSong)
        }
    }
    
    /**
     Adds the song tapped to the currentl playlist
    */
    @IBAction func plusButtonTapped(_ sender: Any) {
        // check to make sure the song is not nil
        var alertTitle: String?
        var alertMessage: String?
        if let currSong = SpotifyPlayer.shared.currentSong {
            SpotifyPlayer.shared.addToPlaylist(song: currSong, isCurrent: true)
            alertTitle = "Added to Playlist!"
            alertMessage = "Successfully added \"\(currSong.title)\" to the playlist"
            let alert = UIAlertController(title: alertTitle!, message: alertMessage!, preferredStyle: .alert)
            self.present(alert, animated: true)
            // code for auto dismissal referenced from
            // https://stackoverflow.com/questions/27613926/dismiss-uialertview-after-5-seconds-swift
            let when = DispatchTime.now() + 1
            DispatchQueue.main.asyncAfter(deadline: when){
                // your code with delay
                alert.dismiss(animated: true, completion: nil)
            }
        }
        else {
            alertTitle = "No Song Selected"
            alertMessage = "Please select a song to add to the playlist."
            let alert = UIAlertController(title: alertTitle!, message: alertMessage!, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - Internal
extension MiniPlayerViewController {
    
    func configure(song: Song?) {
        if let song = song {
            songTitle.text = song.title
            song.loadSongImage { [weak self] image in
                self?.thumbImage.image = image
            }
        } else {
            songTitle.text = nil
            thumbImage.image = nil
        }
        currentSong = song
    }
}

// MARK: - IBActions
extension MiniPlayerViewController {
    
    @IBAction func tapGesture(_ sender: Any) {
        guard let song = currentSong else {
            return
        }
        
        delegate?.expandSong(song: song)
    }
}

extension MiniPlayerViewController: MaxiPlayerSourceProtocol {
    var originatingFrameInWindow: CGRect {
        let windowRect = view.convert(view.frame, to: nil)
        return windowRect
    }
    
    var originatingCoverImageView: UIImageView {
        return thumbImage
    }
}
