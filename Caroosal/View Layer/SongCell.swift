//
//  SongCell.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//
import UIKit
import CheckMarkView

// This file is base-code from Tutorial (https://www.raywenderlich.com/221-recreating-the-apple-music-now-playing-transition)
// SongCell refers to the songs in the collection view
class SongCell: UICollectionViewCell {
    
    // MARK: - IBOutlets
    @IBOutlet weak var coverArt: UIImageView!
    @IBOutlet weak var songTitle: UILabel!
    @IBOutlet weak var artistName: UILabel!
    @IBOutlet weak var checkMark: CheckMarkView!
    
}
