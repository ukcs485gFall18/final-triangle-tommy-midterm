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
    var songHistory: [Song]?
    static let shared = SpotifyPlayer() // static reference to class
    var ref: DatabaseReference! // Firebase database reference
    var currentParty: Party?
    var previousPlayedURI: [String]?
    var accessToken: String?
    var dataStack: DataStack
    
    override init(){
        self.currentPlaybackState = .isNil
        self.currentPlaylist = []
        self.previousPlayedURI = []
        self.songHistory = []
        self.ref = Database.database().reference()
        self.dataStack = DataStack()
        super.init()
    }
    
    /**
     Set the player to the initialized player
     - parameter player: The SPTAudioStreamingController object that the class controls
     */
    func setPlayer(player: SPTAudioStreamingController){
        self.player = player
    }
    
    /**
     Set the party to the current party
     - parameter player: The SPTAudioStreamingController object that the class controls
     */
    func setCurrentParty(party: Party){
        self.currentParty = party
    }
    
    func addHistory(){
        
        if self.currentSong != nil{
            self.songHistory!.append(self.currentSong!)
        }
        
    }
    
    /**
     Ends the current party and pauses the player
     */
    func endCurrentParty(){
        if self.currentParty != nil {
            pauseSong()
            self.currentParty!.endParty()
            self.currentParty = nil
        }
    }
    
    /**
     Set the access token to the token provided
     - parameter token: A Spotify access token
     */
    func setAccessToken(token: String){
        self.accessToken = token
    }
    
    
    /**
     Checks to see if the queue contains the inputted song
     - parameter song: a song object
     */
    func containsSong(song: Song) -> Bool{
        // check to see the spotify URI is in the queue
        for cSong in self.currentPlaylist! {
            if cSong.mediaURL?.absoluteString == song.mediaURL?.absoluteString {
                return true
            }
        }
        return false
    }
    
    // Returns just the track ID from the MediaURL of the track:
    // i.e. Is stored in database like: "spotify:track:5mCPDVBb16L4XQwDdbRUpz"
    // we just want the "5mCPDVBb16L4XQwDdbRUpz" for song recommendations
    func getTrackIDfromURI(uri: String) -> String{
        let split = uri.components(separatedBy: ":")
        return split[2]
    }
    
    /**
     Sets the player to play the current song
     - parameter song: The song to begin playing
     */
    func startSong(song: Song){
        self.player?.playSpotifyURI(song.mediaURL?.absoluteString, startingWith: 0, startingWithPosition: 0, callback: { error in
            self.currentSong = song
            self.previousPlayedURI!.append(self.getTrackIDfromURI(uri: (song.mediaURL?.absoluteString)!))
            self.currentSong!.ref!.ref.removeValue()
            // set as the current song in the firebase database
            self.currentSong!.ref! = self.ref.child("songs/currentSong").child(self.currentParty!.host)
            self.writeSongToFirebase(song: self.currentSong!, isCurrent: false)
            SwiftSpinner.show("Loading Track")
            return
        })
        self.currentPlaybackState = .isPlaying
    }
    
    /**
     Pull from the party recommended songs and begin playing a track
     */
    func startRecommendedSong(completion: @escaping ([Song]) ->Void){
        SpotifyAPIController.shared.sendRecommendationsRequest(accessToken: self.accessToken!, completionHandler: { data in
            let dict: [[String: Any]] = SpotifyAPIController.shared.parseSpotifyRecommendations(songs: data)
            var dictionaryTest:[String: Any] = [:]
            dictionaryTest["Songs"] = dict
            self.dataStack.load(dictionary: dictionaryTest) { [weak self] success in
                completion((self?.dataStack.allSongs)!)
            }
        })
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
            let newSongRef = self.ref.child("songs/currentSong").child(self.currentParty!.host)
            newSongRef.setValue(song.toDict())
        }
        else {
            if song.ref != nil {
                song.ref!.setValue(song.toDict())
            }
        }
    }
    
    func logoutPlayer(){
        if self.player != nil {
         self.player!.logout()
        }
    }
}
