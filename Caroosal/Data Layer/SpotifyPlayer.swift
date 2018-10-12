//
//  SpotifyPlayer.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/11/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit

class SpotifyPlayer: NSObject {
    enum currentState {
        case isNil // if a song has not yet been played
        case isPlaying // if a song is currently playing
        case isPaused // if a song is currently paused
    }
    var currentSong: Song?
    var player: SPTAudioStreamingController?
    var currentPlaybackState: currentState?
    var currentPlaylist: [Song]?
    static let shared = SpotifyPlayer()
    
    override init(){
        super.init()
        self.currentPlaybackState = .isNil
        self.currentPlaylist = []
    }
    
    // set the player to the initialized player
    func setPlayer(player: SPTAudioStreamingController){
        self.player = player
    }
    
    // set the player to play the current song
    func startSong(song: Song){
        self.player?.playSpotifyURI(song.mediaURL?.absoluteString, startingWith: 0, startingWithPosition: 0, callback: { error in
            self.currentSong = song
            return
        })
        self.currentPlaybackState = .isPlaying
    }
    
    // resume the song after it was paused
    func resumeSong(){
        self.player?.setIsPlaying(true, callback: nil)
        self.currentPlaybackState = .isPlaying
    }
    
    // set the player to pause the current song
    func pauseSong(){
        self.player?.setIsPlaying(false, callback: nil)
        self.currentPlaybackState = .isPaused
    }
    
    // update the playlist (used because the order will constantly be changing)
    func setPlaylist(newPlaylist: [Song]){
        self.currentPlaylist = newPlaylist
    }
    
    // set the player to skip to the next song in the queue
    // returns the song to be played
    func skipToNextSong() -> Song? {
        // TODO: Use the Reccomendation's API endpoint if the queue becomes empty
        if (self.currentPlaylist?.count)! > 0 {
            let songToPlay = self.currentPlaylist![0]
            self.startSong(song: songToPlay)
            self.currentPlaylist?.removeFirst()
            return songToPlay
        }
        return nil
    }
    
}
