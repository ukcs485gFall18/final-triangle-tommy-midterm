//
//  SongSubscriber.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import Foundation
// This file is base-code from Tutorial
protocol SongSubscriber: class {
    var currentSong: Song? { get set }
    var player: SPTAudioStreamingController? { get set }
}
