//
//  SongTableCell.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/19/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit

// Define the song cells in the table view
class SongTableCell: UITableViewCell {
    @IBOutlet weak var voteCounterLabel: UILabel!
    @IBOutlet weak var albumCover: UIImageView!
    @IBOutlet weak var songTitleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    @IBOutlet weak var upvoteButton: UIButton!
    @IBOutlet weak var downvoteButton: UIButton!
    
    
}
