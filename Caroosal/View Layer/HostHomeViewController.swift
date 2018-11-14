//
//  HostHomeViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 11/5/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit
import AVKit
import SwiftSpinner
import EmptyDataSet_Swift
import FirebaseDatabase

class HostHomeViewController: UIViewController {

    var accessToken: String?
    var spotifySession: SPTSession?
    var currentUsername: String?
    var currentParty: Party?
    var ref: DatabaseReference?
    var player: SPTAudioStreamingController?
    var auth = SPTAuth.defaultInstance()!
    
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var displayUserNameLabel: UILabel!
    
    @IBOutlet weak var partyTableView: UITableView!
    @IBOutlet weak var createButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.accessToken = self.spotifySession?.accessToken
        self.partyTableView.delegate = self
        self.partyTableView.dataSource = self
        
        self.partyTableView.emptyDataSetSource = self
        self.partyTableView.tableFooterView = UIView()
        
        self.ref = Database.database().reference()
        
        let notificationName = Notification.Name("partyListener")
        // Register to receive notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.listenForParty), name: notificationName, object: nil)
        
        // Initialize the Spotify Player
        self.initializePlayer(authSession: self.spotifySession!)
        
        // Set the profile image to a circular image
        // Source: https://stackoverflow.com/questions/28074679/how-to-set-image-in-circle-in-swift
        profileImage.layer.borderWidth = 1
        profileImage.layer.masksToBounds = false
        profileImage.layer.borderColor = UIColor.clear.cgColor
        profileImage.layer.cornerRadius = profileImage.frame.height / 2
        profileImage.clipsToBounds = true
        
        self.createButton.layer.cornerRadius = 5
        
        // Create the Logout Buttons
        // Source: https://stackoverflow.com/questions/43254254/left-bar-button-item
        let logoutButton = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(logoutPressed))
        self.navigationItem.leftItemsSupplementBackButton = true
        self.navigationItem.leftBarButtonItem = logoutButton
        
        if let token = self.accessToken {
            SPTUser.requestCurrentUser(withAccessToken: token, callback: {(error, data) in
                guard let user = data as? SPTUser else { print("Couldn't cast as SPTUser"); return }
                self.currentUsername = user.canonicalUserName!
                self.displayNameLabel.text = user.displayName
                self.displayUserNameLabel.text = user.canonicalUserName
                NotificationCenter.default.post(name: Notification.Name(rawValue: "partyListener"), object: nil)

                if user.images != nil {
                    let imageURL = (user.images[0] as AnyObject).imageURL!
                    DispatchQueue.global(qos: .background).async {
                        let profileImageData = NSData(contentsOf: imageURL!)
                        let profileImage = UIImage(data: profileImageData! as Data)
                        DispatchQueue.main.async {
                            self.profileImage.image = profileImage
                        }
                    }
                }
            })
        }
        
        // send a welcome alert
//        let alert = UIAlertController(title: "Welcome to Caroosal!", message: "Select songs to add to the playlist by performing a long press gesture and pulling up, or play songs by tapping on them quickly.", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
//        self.present(alert, animated: true)
    }
    
    @objc func logoutPressed(){
        self.auth.session = nil
        
        SpotifyPlayer.shared.logoutPlayer()
        
        let presentedVc = self.storyboard?.instantiateViewController(withIdentifier: "homeVC") as! LoginViewController
        if presentedVc != nil {
            presentedVc.providesPresentationContextTransitionStyle = true
            presentedVc.definesPresentationContext = true
            presentedVc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext;
            presentedVc.view.backgroundColor = UIColor.init(white: 0.4, alpha: 0.8)

            
            self.dismiss(animated: true, completion: nil)
            self.present(presentedVc, animated: true, completion: nil)
        }
    }
    
    
    @objc func listenForParty(){
        print("listening for party")
        self.ref!.child("parties").child(self.currentUsername!).observeSingleEvent(of: .value, with: {(datasnapshot) in
            let party = FirebaseController.shared.buildPartyFromSnapshot(snapshot: datasnapshot)
            self.currentParty = party
            
            self.createButton.setTitle("View Party", for: .normal)
            
            self.partyTableView.reloadData()
        })
    }

//
//    func setParty(){
//        self.currentParty = party
//        self.partyTableView.reloadData()
//    }
    
    
    @IBAction func createButtonPressed(_ sender: Any) {
        // Presenting Modal View Controller
        // Source: https://stackoverflow.com/questions/47936039/how-to-present-viewcontroller-in-modaly-swift-4
        
        if self.currentParty == nil { // Create the Party
            let presentedVc = self.storyboard?.instantiateViewController(withIdentifier: "partyCreation") as! PartyCreationViewController
            if presentedVc != nil {
                presentedVc.providesPresentationContextTransitionStyle = true
                presentedVc.definesPresentationContext = true
                presentedVc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext;
                presentedVc.view.backgroundColor = UIColor.init(white: 0.4, alpha: 0.8)
                presentedVc.currentUsername = self.currentUsername!
                self.present(presentedVc, animated: true, completion: nil)
            }
        }
        
        else { // View the Party
            let tabVc = self.storyboard?.instantiateViewController(withIdentifier: "partyHome") as! UITabBarController
            
            if tabVc != nil {
                tabVc.providesPresentationContextTransitionStyle = true
                tabVc.definesPresentationContext = true
                tabVc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext;
                tabVc.view.backgroundColor = UIColor.init(white: 0.4, alpha: 0.8)
                
                let dvc = tabVc.viewControllers![0] as! SongViewController
                let nav = tabVc.viewControllers![1] as! UINavigationController
                let playlistVC = nav.viewControllers[0] as! PlaylistViewController
                
                // send the access token and player over to the SongViewController
                dvc.accessToken = self.accessToken
                dvc.playlistVC = playlistVC
                playlistVC.ref = Database.database().reference()
                playlistVC.currentParty = self.currentParty
                playlistVC.setPlaylistListener()
                
                // Set the current party in the Spotify player
                SpotifyPlayer.shared.setCurrentParty(party: self.currentParty!)
            
                self.present(tabVc, animated: true, completion: nil)
            }
        }
    }
    
    /**
     Initialize the Spotify streaming controller
     Code modeled off of Elon Rubin's tutorial
     - parameter authSession: the session object
     */
    func initializePlayer(authSession:SPTSession){
        // if the player has yet to be initialized, set initialize it w/ access token & set delegate
        if self.player == nil {
            self.player = SPTAudioStreamingController.sharedInstance()
            self.player!.playbackDelegate = self
            self.player!.delegate = self
            try! player!.start(withClientId: auth.clientID)
            self.player!.login(withAccessToken: authSession.accessToken)
            
            // Fixing a bug where the audio does not play on device
            // Code referenced from "Allen's" answer at
            // https://stackoverflow.com/questions/35457524/avaudioplayer-working-on-simulator-but-not-on-real-device
            do {
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
                
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    
                } catch let error as NSError {
                    print(error.localizedDescription)
                }
            } catch let error as NSError {
                print(error.localizedDescription)
            }
            print("Player was initialized")
            SpotifyPlayer.shared.setPlayer(player: self.player!)
        }
        else {
            print("Error Initializing Player")
        }
    }
    
    
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "goToParty" {
            let tabVc = segue.destination as! UITabBarController
            let dvc = tabVc.viewControllers![0] as! SongViewController
            let nav = tabVc.viewControllers![1] as! UINavigationController
            let playlistVC = nav.viewControllers[0] as! PlaylistViewController

            // send the access token and player over to the SongViewController
            dvc.accessToken = self.accessToken
            dvc.playlistVC = playlistVC
            playlistVC.ref = Database.database().reference()
            playlistVC.currentParty = self.currentParty
            playlistVC.setPlaylistListener()
            
            // Set the current party in the Spotify player
            SpotifyPlayer.shared.setCurrentParty(party: self.currentParty!)
            
        }
    }
}


// MARK: Party TableView Methods

extension HostHomeViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "My Party"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.currentParty != nil {
            return 1
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "partyCell", for: indexPath) as! PartyCell
        cell.partyNameLabel.text = self.currentParty!.name
        cell.partyPasswordLabel.text = self.currentParty!.password
        return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let MinHeight: CGFloat = 150.0
        return MinHeight
    }
}

extension HostHomeViewController: UITableViewDelegate {
}

// MARK: EmptyDataSetSource Methods
extension HostHomeViewController: EmptyDataSetSource {
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "No Current Party"
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }

    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        let str = "Hit 'Create Party' to begin a party!"
        let attrs = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        return NSAttributedString(string: str, attributes: attrs)
    }

    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "song")
    }
}


extension HostHomeViewController: SPTAudioStreamingDelegate {
    // delegate method that calls once the login was successful. Performs a segue to the main controller
    func audioStreamingDidLogin(_ audioStreaming: SPTAudioStreamingController!) {
        // after a user authenticates a session, the SPTAudioStreamingController is then initialized and this method called
        SwiftSpinner.hide()
    }
}

// MARK: - SPTAudioStreamingPlaybackDelegate
extension HostHomeViewController: SPTAudioStreamingPlaybackDelegate {
    // User logged out
    func audioStreamingDidLogout(_ audioStreaming: SPTAudioStreamingController!) {
        print("Logged Out")
        try! SpotifyPlayer.shared.player?.stop()
    }
    // User skipped to the next trakc
    func audioStreamingDidSkip(toNextTrack audioStreaming: SPTAudioStreamingController!) {
        print("Skipped To Next Track")
    }
    // User skipped to previous track
    func audioStreamingDidSkip(toPreviousTrack audioStreaming: SPTAudioStreamingController!) {
        print("Skipped To Previous Track")
    }
    // User stopped playing track
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStopPlayingTrack trackUri: String!) {
        
        if let newSong = SpotifyPlayer.shared.skipToNextSong() {
            print("woohoo")
        }
        else {
            // refresh the song playing state
            SpotifyPlayer.shared.player?.setIsPlaying(false, callback: nil)
            let notificationName = Notification.Name("songStoppedPlaying")
            NotificationCenter.default.post(name: notificationName, object: nil)
        }
    }
    // user started playing track
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didStartPlayingTrack trackUri: String!) {
        SwiftSpinner.hide() // hide swift spinner
        let notificationName = Notification.Name("songStartedPlaying")
        NotificationCenter.default.post(name: notificationName, object: nil)
    }
    
    // User seeks to song position
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didSeekToPosition position: TimeInterval) {
        print("Seeked to Position")
    }
    
    // User changes playback status
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChangePlaybackStatus isPlaying: Bool) {
        let notificationName = Notification.Name("changedPlaybackStatus")
        NotificationCenter.default.post(name: notificationName, object: nil)
    }
    // Metadata of song changed
    func audioStreaming(_ audioStreaming: SPTAudioStreamingController!, didChange metadata: SPTPlaybackMetadata!) {
        print("Did Change")
    }
}

