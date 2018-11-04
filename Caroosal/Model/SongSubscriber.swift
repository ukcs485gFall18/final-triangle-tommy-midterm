//
//  SongSubscriber.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import Foundation
// This file is base-code from Tutorial (https://www.raywenderlich.com/221-recreating-the-apple-music-now-playing-transition)
protocol SongSubscriber: class {
    var currentSong: Song? { get set }
    // Added this property
    var player: SPTAudioStreamingController? { get set }
}
