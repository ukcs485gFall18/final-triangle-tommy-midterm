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

    func test(){
        print("test function")
    }
    
    func updateButtons(isPlaying: Bool){
        if isPlaying {
            self.playButton.setImage(UIImage(named: "pause"), for: .normal)
        }
        else {
            self.playButton.setImage(UIImage(named: "play"), for: .normal)
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        // set the playback buttons to the current state on appear
        if let state = self.player?.playbackState {
            updateButtons(isPlaying: state.isPlaying)
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
