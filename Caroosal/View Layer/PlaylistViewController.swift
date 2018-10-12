//
//  PlaylistViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/4/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit

class SongTableCell: UITableViewCell {
    @IBOutlet weak var voteCounterLabel: UILabel!
}

class PlaylistViewController: UITableViewController {
    var songs: [Song] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func viewDidAppear(_ animated: Bool) {
        print(songs)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songs.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "songCell", for: indexPath) as! SongTableCell
        let currSong = self.songs[indexPath.row]
        cell.textLabel?.text = currSong.title
        cell.voteCounterLabel.text = "\(currSong.voteCount)"
        return cell
    }
    
    @IBAction func upvoteTouched(_ sender: Any) {
        // code for finding current cell in row was found at https://stackoverflow.com/questions/39585638/get-indexpath-of-uitableviewcell-on-click-of-button-from-cell
        let buttonPostion = (sender as AnyObject).convert((sender as AnyObject).bounds.origin, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: buttonPostion) {
            let rowIndex =  indexPath.row
            
            let currentCell = self.tableView.cellForRow(at: indexPath) as! SongTableCell
            songs[indexPath.row].voteCount = songs[indexPath.row].voteCount + 1
            updatePlaylist()
        }
    }
    
    @IBAction func downvoteTouched(_ sender: Any) {
        // code for finding current cell in row was found at https://stackoverflow.com/questions/39585638/get-indexpath-of-uitableviewcell-on-click-of-button-from-cell
        let buttonPostion = (sender as AnyObject).convert((sender as AnyObject).bounds.origin, to: tableView)
        if let indexPath = tableView.indexPathForRow(at: buttonPostion) {
            let rowIndex =  indexPath.row
            
            let currentCell = self.tableView.cellForRow(at: indexPath) as! SongTableCell
            if songs[indexPath.row].voteCount > 0 { // no negatives
                songs[indexPath.row].voteCount = songs[indexPath.row].voteCount - 1
              
            }
            updatePlaylist()
        }
    }
    
    // sort the playlist in descending order, set it in the player, and reload the tableView
    func updatePlaylist() {
        self.songs = songs.sorted(by: { $0.voteCount > $1.voteCount})
        SpotifyPlayer.shared.setPlaylist(newPlaylist: self.songs)
        self.tableView.reloadData()
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
