//
//  PlaylistViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/4/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import FirebaseDatabase

class PlaylistViewController: UITableViewController {
    var ref: DatabaseReference?
    override func viewDidLoad() {        super.viewDidLoad()        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewDidAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    // set a listener for playlist updates
    func setPlaylistListener(){
        var dataStack = DataStack()
        var refHandle = self.ref!.child("playlist").queryOrdered(byChild: "VoteCount").observe(DataEventType.value, with: { (snapshot) in
            let playlistDict = snapshot.value as? [String: Any]
            if let songDict = playlistDict {
                print("PRINTING SONG DICT")
                print(songDict)
                var songArr = [[String: Any]]()
                for item in songDict {
                    let newRef = self.ref!.child("playlist").child(item.key)
                    var songVals = item.value as! [String: Any]
                    let artist = songVals["Artist"] as! String
                    let coverURL = songVals["CoverURL"] as! String
                    let duration = 0
                    let mediaURL = songVals["MediaURL"] as! String
                    let title = songVals["Title"] as! String
                    let voteCount = songVals["VoteCount"] as! Int
                    let newDict: [String: Any] = ["title": title, "artist": artist, "coverArtURL": coverURL, "duration": duration, "mediaURL": mediaURL, "voteCount": voteCount, "databaseRef": newRef]
                    songArr.append(newDict)
                }
                var dictionaryTest:[String: Any] = [:]
                dictionaryTest["Songs"] = songArr
                dataStack.load(dictionary: dictionaryTest) { [weak self] success in
                    SpotifyPlayer.shared.currentPlaylist = dataStack.allSongs
                    self?.updatePlaylist()
                }
            }
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
        if SpotifyPlayer.shared.currentPlaylist!.isEmpty {
            return 0
        }
        return SpotifyPlayer.shared.currentPlaylist!.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath) as! SongTableCell
        let currSong = SpotifyPlayer.shared.currentPlaylist![indexPath.row]
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
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //Delete the song from the playlist
            SpotifyPlayer.shared.currentPlaylist?.remove(at: indexPath.row)
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

