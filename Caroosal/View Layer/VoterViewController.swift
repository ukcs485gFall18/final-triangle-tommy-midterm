//
//  VoterViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/19/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import FirebaseDatabase
import EmptyDataSet_Swift


// Created by: Thomas Deeter
// VoterViewController: Non authenticated users can vote on the current queue

class VoterViewController: UITableViewController, EmptyDataSetSource, EmptyDataSetDelegate {

    // MARK: Properties
    var ref: DatabaseReference? // Reference to database
    var votedOnArray = [[String: String]]() // Array of currently voted on songs
    var currentPlaylist: [Song]? // Current party playlist
    var songHistory: [Song] = [] // songs played since user joined party
    var currentSong: Song? // Currently playing song
    var currentParty: Party? // current party object
    
    // enum to keep track of song vote states
    enum voteState {
        case upVoted
        case downVoted
        case notVoted
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        // set the navigation title to the current party name
        self.navigationItem.title = self.currentParty?.name ?? "Queue"
        
        // add a logout button
        let logoutButton = UIBarButtonItem(title: "Home", style: .plain, target: self, action: #selector(homePressed))
        self.navigationItem.leftItemsSupplementBackButton = true
        self.navigationItem.leftBarButtonItem = logoutButton
        
        // send a welcome alert
        let alert = UIAlertController(title: "Welcome to Caroosal!", message: "Tap on either the upvote or downvote buttons to have your say in what songs to play!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
        self.present(alert, animated: true)
    }

    override func viewDidAppear(_ animated: Bool) {
        self.songHistory.removeAll()
        self.tableView.reloadData()
        // listen to the current playing song being updated
        let currentPartyRef = self.ref!.child("parties").child((self.currentParty?.host)!)
        currentPartyRef.observe(DataEventType.value, with: {(snapshot) in
            let party = FirebaseController.shared.buildPartyFromSnapshot(snapshot: snapshot)
            if party == nil {
                // send an alert when the party is ended & redirect to home screen
                let alert = UIAlertController(title: "Party Ended!", message: "The host has deleted the party. You will be redirected to the home screen.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: {action in
                    self.dismiss(animated: true, completion: {})
                }))
                self.present(alert, animated: true)
            }
        })
    }
    
    /**
     Return the user to the home page
     */
    @objc func homePressed(){
        self.dismiss(animated: true, completion: {})
    }

    /**
     Sets a listener to the firebase database for queue updates
     */
    func setPlaylistListener(){
        // listen for updates to vote counts and songs being added to the playlist
        let songsRef = self.ref!.child("songs").child("queue").child((self.currentParty?.host)!)
        songsRef.queryOrdered(byChild: "VoteCount").observe(DataEventType.value, with: { (snapshot) in
            self.currentPlaylist = FirebaseController.shared.parseQueueSnapshot(snapshot: snapshot)
            self.updatePlaylist()
        })
        // listen for songs being removed from the playlist
        songsRef.observe(DataEventType.childRemoved, with: { (snapshot) in
            songsRef.observeSingleEvent(of: .value, with: {(snapshot) in
                self.currentPlaylist = FirebaseController.shared.parseQueueSnapshot(snapshot: snapshot)
                self.updatePlaylist()
            })
        })
        // listen to the current playing song being updated
        let currentSongRef = self.ref!.child("songs").child("currentSong").child((self.currentParty?.host)!)
        currentSongRef.observe(DataEventType.value, with: {(snapshot) in
            if self.currentSong != nil {
                self.songHistory.append(self.currentSong!)
            }
            self.currentSong = FirebaseController.shared.buildSongFromSnapshot(snapshot: snapshot)
            self.tableView.reloadData()
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // 1 row in the first section (the currently playing song)
        // Length of the queue num rows in the second section
        // Length of song history in third section
        switch section {
        case 0: // Current Song
            if self.currentSong == nil {
                return 0
            } else {
                return 1
            }
        case 1: // Party Queue
            if self.currentPlaylist == nil {
                return 0
            }
            return self.currentPlaylist!.count
        case 2: // Party History
            return self.songHistory.count
        default:
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath) as! SongTableCell
        var currSong: Song?
        
        // grab the current song & hide any necessary labels
        switch indexPath.section {
        case 0: // Current Song
            if self.currentSong != nil {
                currSong = self.currentSong!
                cell.upvoteButton.isHidden = true
                cell.downvoteButton.isHidden = true
                cell.voteCounterLabel.isHidden = true
            }
            else {
                return cell
            }
        case 1: // Party Queue
            currSong = self.currentPlaylist![indexPath.row]
            cell.upvoteButton.isHidden = false
            cell.downvoteButton.isHidden = false
            cell.voteCounterLabel.isHidden = false
            
            // get the vote status if necessary
            let songVote = self.getSongVoteStatus(song: currSong!)
            switch songVote {
            case .upVoted:
                cell.upvoteButton.setImage(UIImage(named: "upvoteselected.png"), for: .normal)
                cell.downvoteButton.setImage(UIImage(named: "downvote.png"), for: .normal)
            case .downVoted:
                cell.upvoteButton.setImage(UIImage(named: "upvote.png"), for: .normal)
                cell.downvoteButton.setImage(UIImage(named: "downvoteselected.png"), for: .normal)
            case .notVoted:
                cell.upvoteButton.setImage(UIImage(named: "upvote.png"), for: .normal)
                cell.downvoteButton.setImage(UIImage(named: "downvote.png"), for: .normal)
            }
            
        case 2: // Party History
            currSong = self.songHistory[indexPath.row]
            cell.upvoteButton.isHidden = true
            cell.downvoteButton.isHidden = true
            cell.voteCounterLabel.isHidden = true
        default:
            return cell
        }
        
        cell.voteCounterLabel.text = "\(currSong!.voteCount!)"
        cell.songTitleLabel.text = currSong!.title
        cell.artistLabel.text = currSong!.artist
        currSong!.loadSongImage(completion: { image in
            cell.albumCover.image = image
        })
        return cell
    }
    
    // MARK: - Table view delegate methods
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25.0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: // Current Song
            return "Currently Playing"
        case 1: // Party Queue
            return "Party Queue"
        case 2: // Party History
            return "Current Session History"
        default:
            return "Empty"
        }
    }
    
    
    /**
     Check whether or not the user up/down voted on the particular song
     - parameter song: the song to check vote status
     */
    func getSongVoteStatus(song: Song) -> voteState {
        for voteDict in self.votedOnArray {
            if voteDict["songKey"] == song.ref?.key { // found the right song
                switch voteDict["voteType"] {
                case "upvote":
                    return .upVoted
                case "downvote":
                    return .downVoted
                default:
                    return .notVoted
                }
            }
        }
        return .notVoted
    }

    /**
     when the user hits either the upvote / downvote button, update the playlist
    */
    func updateSongVoteCount(modifier: Int, row: Int){
        // get the song at the given row
        let currSong = self.currentPlaylist![row]
        let newVoteCount = currSong.voteCount! + modifier
        // remove the song if the vote count hits -5
        if newVoteCount == -5 {
            self.currentPlaylist!.remove(at: row)
            currSong.ref?.removeValue()
            self.tableView.reloadData()
            return
        }
        let childUpdates = ["VoteCount": newVoteCount]
        currSong.ref!.updateChildValues(childUpdates)
        self.tableView.reloadData()
    }

    /**
     Upvote code: Votes +1 on song if not voted before, +2 if previously downvoted -1 if already voted
     */
    @IBAction func upvoteTouched(_ sender: Any) {
        // code for finding current cell in row was found at https://stackoverflow.com/questions/39585638/get-indexpath-of-uitableviewcell-on-click-of-button-from-cell
        let buttonPostion = (sender as AnyObject).convert((sender as AnyObject).bounds.origin, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: buttonPostion) {
            var modifier = 1
            var indexOfVoted = 0
            let votedSong = self.currentPlaylist![indexPath.row]
            for songObj in self.votedOnArray
            {
                // if the user clicks on the row with a song they've already voted on
                if(votedSong.ref!.key == (songObj["songKey"])){
                    if(songObj["voteType"] == "upvote"){
                        // user cannot upvote on song twice, reset their vote
                        self.votedOnArray.remove(at: indexOfVoted)
                        modifier = -1
                        updateSongVoteCount(modifier: modifier, row: indexPath.row)
                        return
                    }
                    else { // user decides to upvote on a song they previously downvoted on, so add 2
                        self.votedOnArray.remove(at: indexOfVoted)
                        modifier = 2
                        break
                    }
                }
                indexOfVoted = indexOfVoted + 1
            }
            let songData = ["songKey": votedSong.ref!.key!, "voteType": "upvote"]
            votedOnArray.append(songData)
            updateSongVoteCount(modifier: modifier, row: indexPath.row)
        }
    }

    /**
     Downvote code: Votes -1 on song if not voted before, -2 if previously upvoted +1 if already voted
     */
    @IBAction func downvoteTouched(_ sender: Any) {
        // code for finding current cell in row was found at https://stackoverflow.com/questions/39585638/get-indexpath-of-uitableviewcell-on-click-of-button-from-cell
        let buttonPostion = (sender as AnyObject).convert((sender as AnyObject).bounds.origin, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: buttonPostion) {
            var modifier = -1
            var indexOfVoted = 0
            let votedSong = self.currentPlaylist![indexPath.row]
            for songObj in self.votedOnArray
            {
                // if the user clicks on the row with a song they've already voted on
                if(votedSong.ref!.key == (songObj["songKey"])){
                    if(songObj["voteType"] == "downvote"){
                        // user cannot downvote on song twice, reset their vote
                        self.votedOnArray.remove(at: indexOfVoted)
                        modifier = 1
                        updateSongVoteCount(modifier: modifier, row: indexPath.row)
                        return
                    }
                    else { // user decides to downvote on a song they previously upvoted on, so subtract 2
                        self.votedOnArray.remove(at: indexOfVoted)
                        modifier = -2
                        break
                    }
                }
                indexOfVoted = indexOfVoted + 1
                
            }
            let songData = ["songKey": votedSong.ref!.key!, "voteType": "downvote"]
            votedOnArray.append(songData)
            updateSongVoteCount(modifier: modifier, row: indexPath.row)
        }
    }

    // sort the playlist in descending order, set it in the player, and reload the tableView
    func updatePlaylist() {
        self.currentPlaylist = self.currentPlaylist!.sorted(by: { $0.voteCount! > $1.voteCount!})
        self.tableView.reloadData()
    }
    
    // MARK: - Empty DataSource Delegates
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "No Songs in the Queue"
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline), NSAttributedStringKey.foregroundColor: UIColor.white]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Check here once the party host adds songs to the queue!"
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline), NSAttributedStringKey.foregroundColor: UIColor.white]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "song")
    }
    
}
