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

class VoterViewController: UITableViewController, EmptyDataSetSource, EmptyDataSetDelegate {

    var ref: DatabaseReference?
    var currentPlaylist: [Song]?
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
        self.navigationItem.title = "Queue"
    }

    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }

    // set a listener for playlist updates
    func setPlaylistListener(){
        var dataStack = DataStack()
        // listen for updates to vote counts and songs being added to the playlist
        var voteHandle = self.ref!.child("songs").child("queue").queryOrdered(byChild: "VoteCount").observe(DataEventType.value, with: { (snapshot) in
            self.currentPlaylist = FirebaseController.shared.parseQueueSnapshot(snapshot: snapshot)
            self.updatePlaylist()
        })
        // listen for songs being removed from the playlist
        var removeHandle = self.ref!.child("songs").child("queue").observe(DataEventType.childRemoved, with: { (snapshot) in
            var updateRef = self.ref!.child("songs").child("queue").observeSingleEvent(of: .value, with: {(snapshot) in
                self.currentPlaylist = FirebaseController.shared.parseQueueSnapshot(snapshot: snapshot)
                self.updatePlaylist()
            })
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.currentPlaylist == nil {
            return 0
        }
        return self.currentPlaylist!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath) as! SongTableCell
        let currSong = self.currentPlaylist![indexPath.row]
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
            if self.currentPlaylist![indexPath.row].voteCount! > -5 {
                updateSongVoteCount(modifier: -1, row: indexPath.row)
            }
        }
    }

    // sort the playlist in descending order, set it in the player, and reload the tableView
    func updatePlaylist() {
        self.currentPlaylist = self.currentPlaylist!.sorted(by: { $0.voteCount! > $1.voteCount!})
        self.tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Party Queue"
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
