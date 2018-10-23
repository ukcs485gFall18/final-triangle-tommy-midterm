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

class PlaylistViewController: UITableViewController, EmptyDataSetSource, EmptyDataSetDelegate {
    var ref: DatabaseReference?
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
    
    func setPlaylistListener(){
        // listen for updates to vote counts and songs being added to the playlist
        var voteHandle = self.ref!.child("songs").child("queue").queryOrdered(byChild: "VoteCount").observe(DataEventType.value, with: { (snapshot) in
            SpotifyPlayer.shared.currentPlaylist = FirebaseController.shared.parseQueueSnapshot(snapshot: snapshot)
            self.updatePlaylist()
        })
        // listen for songs being removed from the playlist
        var removeHandle = self.ref!.child("songs").child("queue").observe(DataEventType.childRemoved, with: { (snapshot) in
            var updateHandle = self.ref!.child("songs").child("queue").observeSingleEvent(of: .value, with: {(datasnapshot) in
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
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if SpotifyPlayer.shared.currentSong == nil {
                return 0
            } else {
                return 1
            }
        } else if section == 1 {
            if SpotifyPlayer.shared.currentPlaylist!.isEmpty {
                return 0
            }
            return SpotifyPlayer.shared.currentPlaylist!.count
        } else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath) as! SongTableCell
        var currSong: Song
        if indexPath.section == 0 {
            if SpotifyPlayer.shared.currentSong != nil {
                currSong = SpotifyPlayer.shared.currentSong!
                cell.upvoteButton.isHidden = true
                cell.downvoteButton.isHidden = true
            }
            else {
                return cell
            }
        } else {
            currSong = SpotifyPlayer.shared.currentPlaylist![indexPath.row]
        }
        cell.voteCounterLabel.text = "\(currSong.voteCount!)"
        cell.songTitleLabel.text = currSong.title
        cell.artistLabel.text = currSong.artist
        currSong.loadSongImage(completion: { image in
            cell.albumCover.image = image
        })
        return cell
    }
    
    // when the user hits either the upvote / downvote button, update the playlist
    func updateSongVoteCount(modifier: Int, row: Int){
        let currSong = SpotifyPlayer.shared.currentPlaylist![row]
        print(currSong.ref!)
        let newVoteCount = currSong.voteCount! + modifier
        if newVoteCount == -5 {
            SpotifyPlayer.shared.currentPlaylist?.remove(at: row)
            currSong.ref?.removeValue()
            self.tableView.reloadData()
            return
        }
        let childUpdates = ["VoteCount": newVoteCount]
        currSong.ref!.updateChildValues(childUpdates)
    }
    
    
    @IBAction func upvoteTouched(_ sender: Any) {
        // code for finding current cell in row was found at https://stackoverflow.com/questions/39585638/get-indexpath-of-uitableviewcell-on-click-of-button-from-cell
        let buttonPostion = (sender as AnyObject).convert((sender as AnyObject).bounds.origin, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: buttonPostion) {
            updateSongVoteCount(modifier: 1, row: indexPath.row)
        }
    }
    
    @IBAction func downvoteTouched(_ sender: Any) {
        // code for finding current cell in row was found at https://stackoverflow.com/questions/39585638/get-indexpath-of-uitableviewcell-on-click-of-button-from-cell
        let buttonPostion = (sender as AnyObject).convert((sender as AnyObject).bounds.origin, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: buttonPostion) {
            if SpotifyPlayer.shared.currentPlaylist![indexPath.row].voteCount! > -5 { // if song gets to -5, gets booted
                updateSongVoteCount(modifier: -1, row: indexPath.row)
            }
        }
    }
    
    // sort the playlist in descending order, set it in the player, and reload the tableView
    func updatePlaylist() {
        SpotifyPlayer.shared.currentPlaylist = SpotifyPlayer.shared.currentPlaylist!.sorted(by: { $0.voteCount! > $1.voteCount!})
        self.tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //Delete the song from the playlist
            SpotifyPlayer.shared.currentPlaylist?[indexPath.row].ref!.removeValue()
            SpotifyPlayer.shared.currentPlaylist?.remove(at: indexPath.row)
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    // Add the titles for the current song section here
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Currently Playing"
        } else if section == 1 {
            return "Party Queue"
        }
        
        return "Empty"
        
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 25.0
    }

    // MARK: - Empty DataSource Delegates
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "No Songs in the Queue"
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Add some songs to the queue and they will be displayed right here!"
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
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

