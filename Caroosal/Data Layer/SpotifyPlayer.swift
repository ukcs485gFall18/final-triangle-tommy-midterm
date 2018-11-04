//
//  SpotifyPlayer.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/11/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import FirebaseDatabase
import SwiftSpinner

// Created by Thomas Deeter
// SpotifyPlayer: Singleton class that controls the host's party playlist
class SpotifyPlayer: NSObject {
    enum currentState {
        case isNil // if a song has not yet been played
        case isPlaying // if a song is currently playing
        case isPaused // if a song is currently paused
    }
    var currentSong: Song? // reference to the song currently playing
    var player: SPTAudioStreamingController? // the player class that controls audio playback
    var currentPlaybackState: currentState? // current state of the player
    var currentPlaylist: [Song]? // the playlist (queue)
    static let shared = SpotifyPlayer() // static reference to class
    var ref: DatabaseReference! // Firebase database reference
    
    override init(){
        super.init()
        self.currentPlaybackState = .isNil
        self.currentPlaylist = []
        self.ref = Database.database().reference()
    }
    
    /**
     Set the player to the initialized player
     - parameter player: The SPTAudioStreamingController object that the class controls
     */
    func setPlayer(player: SPTAudioStreamingController){
        self.player = player
    }
    
    /**
     Sets the player to play the current song
     - parameter song: The song to begin playing
     */
    func startSong(song: Song){
        self.player?.playSpotifyURI(song.mediaURL?.absoluteString, startingWith: 0, startingWithPosition: 0, callback: { error in
            self.currentSong = song
            self.currentSong!.ref!.ref.removeValue()
            // set as the current song in the firebase database
            self.currentSong!.ref! = self.ref.child("songs").child("currentSong")
            self.writeSongToFirebase(song: self.currentSong!, isCurrent: false)
            SwiftSpinner.show("Loading Track")
            return
        })
        self.currentPlaybackState = .isPlaying
    }
    
    /**
     Resume the playback status of the player after it was paused
     */
    func resumeSong(){
        self.player?.setIsPlaying(true, callback: nil)
        self.currentPlaybackState = .isPlaying
    }
    
    /**
     Pause the currently playing song
     */
    func pauseSong(){
        self.player?.setIsPlaying(false, callback: nil)
        self.currentPlaybackState = .isPaused
    }
    
    /**
     Update the playlist (used because the order will constantly be changing)
     - parameter newPlaylist: An array of Song objects
     */
    func setPlaylist(newPlaylist: [Song]){
        self.currentPlaylist = newPlaylist
    }
    
    /**
     Add the song to the playlist
     - parameter song: The song to add to the playlist
     - parameter isCurrent: A Boolean that is True if the song will immediately play, False otherwise
     */
    func addToPlaylist(song: Song, isCurrent: Bool){
        self.currentPlaylist?.append(song)
        self.writeSongToFirebase(song: song, isCurrent: isCurrent)
    }
    
    /**
     set the player to skip to the next song in the queue
     - Returns: The song to be played
     */
    func skipToNextSong() -> Song? {
        // TODO: Use the Reccomendation's API endpoint if the queue becomes empty
        if (self.currentPlaylist?.count)! > 0 {
            if self.currentSong != nil {
                let songToPlay = self.currentPlaylist![0]
                self.startSong(song: songToPlay)
                self.currentPlaylist?.removeFirst()
                return songToPlay
            }
            else {
                let songToPlay = self.currentPlaylist![0]
                self.startSong(song: songToPlay)
                self.currentPlaylist?.removeFirst()
                return songToPlay
            }
        }
        return nil
    }
    
    /**
     Add the song to the Firebase database
     - parameter song: Song to write to databaset
     - parameter isCurrent: A Boolean that is True if the song will immediately play, False otherwise
     */
    func writeSongToFirebase(song: Song, isCurrent: Bool){
        if isCurrent{
            let newSongRef = self.ref.child("songs").child("queue").childByAutoId()
            newSongRef.setValue(song.toDict())
        }
        else {
            if song.ref != nil {
                song.ref!.setValue(song.toDict())
            }
        }
    }
}
