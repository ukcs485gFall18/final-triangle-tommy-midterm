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
    var currentSongProgress: Float = 0.0
    var songTimer = Timer()
    var startTime: Date?
    
    @IBOutlet weak var thumbImage: UIImageView!
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var ffButton: UIButton!
    @IBOutlet weak var songProgressBar: UIProgressView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure(song: nil)
        let startedName = Notification.Name("songStartedPlaying")
        let stoppedName = Notification.Name("songStoppedPlaying")
        let changedPlaybackName = Notification.Name("changedPlaybackStatus")
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.startSongTimer), name: startedName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshButtonState), name: startedName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshButtonState), name: stoppedName, object: nil)
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
            self.resumeSongTimer()
        case .isPaused?: // if the player is currently paused, resume the song
            self.playButton.setImage(UIImage(named: "play"), for: .normal)
            self.pauseSongTimer()
        case .none:
            print("shouldn't happen")
        }
        self.configure(song: SpotifyPlayer.shared.currentSong)
    }
    
    @objc func startSongTimer(){
        self.resetSongTimer()
        self.songTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.fireTimer), userInfo: nil, repeats: true)
    }
    
    @objc func fireTimer(){
        // workaround because pausing timer isn't working
        if SpotifyPlayer.shared.currentPlaybackState == .isPlaying {
            let nowTime = Date()
            let elapsedTime = nowTime.timeIntervalSince(startTime!)
            print(elapsedTime)
            let percentDone = (elapsedTime * 1000.0) / Double((self.currentSong?.duration)!)
            self.songProgressBar.setProgress(Float(percentDone), animated: true)
        }
    }
    
    // pauses the song timer
    func pauseSongTimer(){
        self.songTimer.invalidate()
    }
    
    // resumes the song timer
    func resumeSongTimer(){
        startTime = Date()
        self.songTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(self.fireTimer), userInfo: nil, repeats: true)
    }
    
    // resets the song timer
    func resetSongTimer(){
        startTime = Date()
        self.currentSongProgress = 0
        self.songProgressBar.setProgress(0.0, animated: true)
        self.songTimer.invalidate()
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
                    SpotifyPlayer.shared.startRecommendedSong(completion: { songs in
                        if(songs.count > 0){
                            self.currentSong = songs[0]
                            self.configure(song: self.currentSong)
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
            SpotifyPlayer.shared.startRecommendedSong(completion: { songs in
                if(songs.count > 0){
                    self.currentSong = songs[0]
                    self.configure(song: self.currentSong)
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
            var newSong = SpotifyPlayer.shared.skipToNextSong()
            self.configure(song: newSong)
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
