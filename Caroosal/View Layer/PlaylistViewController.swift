//
//  PlaylistViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/4/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import FirebaseDatabase
import EmptyDataSet_Swift

// Created by: Zach Moore
// PlaylistViewController: Controls the Host playlist, where the host can add/delete songs to queue

class PlaylistViewController: UITableViewController, EmptyDataSetSource, EmptyDataSetDelegate {
    
    // MARK: Properties
    var ref: DatabaseReference? // Firebase database reference
    var votedOnArray = [[String: String]]() // Array that contains voted on song keys
    var currentParty: Party?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set the delegates and navigation item details
        self.navigationItem.rightBarButtonItem = self.editButtonItem
        self.navigationItem.title = "Queue"
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
    }

    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    /**
     Sets a listener to the firebase database for queue updates
    */
    func setPlaylistListener(){
        let songsRef = self.ref!.child("songs").child("queue").child((self.currentParty?.host)!)
        // listen for updates to vote counts and songs being added to the playlist
        songsRef.queryOrdered(byChild: "VoteCount").observe(DataEventType.value, with: { (snapshot) in
            SpotifyPlayer.shared.currentPlaylist = FirebaseController.shared.parseQueueSnapshot(snapshot: snapshot)
            self.updatePlaylist()
        })
        // listen for songs being removed from the playlist
        songsRef.observe(DataEventType.childRemoved, with: { (snapshot) in
            songsRef.observeSingleEvent(of: .value, with: {(datasnapshot) in
                SpotifyPlayer.shared.currentPlaylist = FirebaseController.shared.parseQueueSnapshot(snapshot: datasnapshot)
                self.updatePlaylist()
            })
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
        switch section {
        case 0: // Current Song
            if SpotifyPlayer.shared.currentSong == nil {
                return 0
            } else {
                return 1
            }
        case 1: // Party Queue
            return SpotifyPlayer.shared.currentPlaylist!.count
        case 2: // Party History
            return SpotifyPlayer.shared.songHistory!.count
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath) as! SongTableCell
        //This disables the songs from being voted on by the host of the party
        cell.upvoteButton.isHidden = true
        cell.downvoteButton.isHidden = true
        var currSong: Song?
        
        switch indexPath.section {
        case 0: // Current Song
            if SpotifyPlayer.shared.currentSong != nil {
                currSong = SpotifyPlayer.shared.currentSong!
            }
        case 1: // Party Queue
            currSong = SpotifyPlayer.shared.currentPlaylist![indexPath.row]
        case 2: // Party History
            currSong = SpotifyPlayer.shared.songHistory![indexPath.row]
        default:
            print("doing nothing")
        }
        
        if currSong != nil {
            cell.voteCounterLabel.text = "\(currSong!.voteCount!)"
            cell.songTitleLabel.text = currSong!.title
            cell.artistLabel.text = currSong!.artist
            currSong!.loadSongImage(completion: { image in
                cell.albumCover.image = image
            })
        }
        
        return cell
    }
    
    /**
        sort the playlist in descending order, set it in the player, and reload the tableView
    */
    func updatePlaylist() {
        SpotifyPlayer.shared.currentPlaylist = SpotifyPlayer.shared.currentPlaylist!.sorted(by: { $0.voteCount! > $1.voteCount!})
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        switch indexPath.section {
        case 0: // Current Song
            return false
        case 1: // Party Queue
            return true
        case 2: // Party History
            return false
        default:
            return false
        }
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //Delete the song from the playlist
            SpotifyPlayer.shared.currentPlaylist?[indexPath.row].ref!.removeValue()
            SpotifyPlayer.shared.currentPlaylist?.remove(at: indexPath.row)
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        }
    }
    
    // Add the titles for the current song section here
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
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25.0
    }

    // MARK: - Empty DataSource Delegates
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "No Songs in the Queue"
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline), NSAttributedStringKey.foregroundColor: UIColor.white]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Add some songs to the queue and they will be displayed right here!"
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline), NSAttributedStringKey.foregroundColor: UIColor.white]
        return NSAttributedString(string: str, attributes: attrs)
    }

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "song")
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

