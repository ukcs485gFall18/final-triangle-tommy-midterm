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

class MiniPlayerViewController: UIViewController, SongSubscriber {
    
    // MARK: - Properties
    var currentSong: Song?
    weak var delegate: MiniPlayerDelegate?
    var player: SPTAudioStreamingController?
    
    // MARK: - IBOutlets
    @IBOutlet weak var thumbImage: UIImageView!
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var ffButton: UIButton!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configure(song: nil)
    }
    
    // Refresh the button state when the view reappears
    // Can't call viewDidAppear because the view technically doesn't disappear
    func refreshButtonState() {
        // set the playback buttons to the current state on appear
        if let state = self.player?.playbackState {
            if (state.isPlaying == true) {
                self.playButton.setImage(UIImage(named: "pause"), for: .normal)
            }
            else {
                self.playButton.setImage(UIImage(named: "play"), for: .normal)
            }
        }
    }
    
    // Playing functionality: Rob Cala
    @IBAction func playButtonTapped(_ sender: Any) {
        // if the player is not yet initialized, play the current song
        if self.player?.playbackState == nil {
            self.player?.playSpotifyURI(currentSong?.mediaURL?.absoluteString, startingWith: 0, startingWithPosition: 0, callback: { error in
                self.playButton.setImage(UIImage(named: "pause"), for: .normal)
                return
            })
        }
            // if the user selects a different song, play that one instead: this else if block Added by Thomas
        else if self.player?.metadata.currentTrack?.uri != currentSong?.mediaURL?.absoluteString{
            self.player?.playSpotifyURI(currentSong?.mediaURL?.absoluteString, startingWith: 0, startingWithPosition: 0, callback: { error in
                self.playButton.setImage(UIImage(named: "pause"), for: .normal)
                return
            })
        }
            // if the button is tapped when the song is playing, pause the music and set the image to play button
        else if self.player?.playbackState.isPlaying == true {
            self.playButton.setImage(UIImage(named: "play"), for: .normal)
            self.player?.setIsPlaying(false, callback: nil)
            return
        }
            // if the button is tapped when the song is paused, resume the music and set the image to pause button
        else if self.player?.playbackState.isPlaying == false {
            self.playButton.setImage(UIImage(named: "pause"), for: .normal)
            self.player?.setIsPlaying(true, callback: nil)
            return
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
