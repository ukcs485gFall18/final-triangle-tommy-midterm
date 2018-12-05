//
//  MaxiSongCardViewController.swift
//  Caroosal
//
//  Created by Tommy Deeter on 10/2/18.
//  Copyright © 2018 Tommy Deeter. All rights reserved.
//

import UIKit

protocol MaxiPlayerSourceProtocol: class {
    var originatingFrameInWindow: CGRect { get }
    var originatingCoverImageView: UIImageView { get }
    func refreshButtonState()
}


// This file is base-code from Tutorial (https://www.raywenderlich.com/221-recreating-the-apple-music-now-playing-transition)
// Plus our modifications
class MaxiSongCardViewController: UIViewController, SongSubscriber {
    
    // MARK: - Properties
    let cardCornerRadius: CGFloat = 10
    var currentSong: Song?
    
    // Added Player objects
    var player: SPTAudioStreamingController?
    var songPlayerVC: SongPlayControlViewController?
    var songVC: SongViewController?
    weak var sourceView: MaxiPlayerSourceProtocol!
    let primaryDuration = 0.5
    let backingImageEdgeInset: CGFloat = 15.0
    // custom UIColor found from http://uicolor.xyz/#/hex-to-ui
    let customPurpleColor = UIColor(red:0.39, green:0.37, blue:0.85, alpha:1.0)
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    //cover image constraints
    @IBOutlet weak var coverImageContainerTopInset: NSLayoutConstraint!
    
    //scroller
    @IBOutlet weak var scrollView: UIScrollView!
    //this gets colored white to hide the background.
    //It has no height so doesnt contribute to the scrollview content
    @IBOutlet weak var stretchySkirt: UIView!
    
    //cover image
    @IBOutlet weak var coverImageContainer: UIView!
    @IBOutlet weak var coverArtImage: UIImageView!
    @IBOutlet weak var dismissChevron: UIButton!
    //add cover image constraints here
    //cover image constraints
    @IBOutlet weak var coverImageLeading: NSLayoutConstraint!
    @IBOutlet weak var coverImageTop: NSLayoutConstraint!
    @IBOutlet weak var coverImageBottom: NSLayoutConstraint!
    @IBOutlet weak var coverImageHeight: NSLayoutConstraint!
    
    //backing image
    var backingImage: UIImage?
    @IBOutlet weak var backingImageView: UIImageView!
    @IBOutlet weak var dimmerLayer: UIView!
    
    //add backing image constraints here
    @IBOutlet weak var backingImageTopInset: NSLayoutConstraint!
    @IBOutlet weak var backingImageLeadingInset: NSLayoutConstraint!
    @IBOutlet weak var backingImageTrailingInset: NSLayoutConstraint!
    @IBOutlet weak var backingImageBottomInset: NSLayoutConstraint!
    
    //lower module constraints
    @IBOutlet weak var lowerModuleTopConstraint: NSLayoutConstraint!
    
    //fake tabbar contraints
    var tabBarImage: UIImage?
    @IBOutlet weak var bottomSectionHeight: NSLayoutConstraint!
    @IBOutlet weak var bottomSectionLowerConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomSectionImageView: UIImageView!
    
    // MARK: - View Life Cycle
    // Most code below is animation code that we followed along in the tutorial
    override func awakeFromNib() {
        super.awakeFromNib()
        modalPresentationCapturesStatusBarAppearance = true //allow this VC to control the status bar appearance
        modalPresentationStyle = .overFullScreen //dont dismiss the presenting view controller when presented
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        backingImageView.image = backingImage
        scrollView.contentInsetAdjustmentBehavior = .never //dont let Safe Area insets affect the scroll view
        
        coverImageContainer.layer.cornerRadius = cardCornerRadius
        coverImageContainer.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        let startedName = Notification.Name("songStoppedPlaying")
        let changedPlaybackName = Notification.Name("changedPlaybackStatus")
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshCoverImage), name: startedName, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.refreshCoverImage), name: changedPlaybackName, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureImageLayerInStartPosition()
        coverArtImage.image = sourceView.originatingCoverImageView.image
        configureCoverImageInStartPosition()
        stretchySkirt.backgroundColor = customPurpleColor //from starter project, this hides the gap
        configureLowerModuleInStartPosition()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateBackingImageIn()
        animateImageLayerIn()
        animateCoverImageIn()
        animateLowerModuleIn()
    }
        
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? SongSubscriber {
            destination.currentSong = currentSong
            //destination.player = self.player
            self.songPlayerVC = destination as! SongPlayControlViewController
        }
    }
    
    @objc func refreshCoverImage(){
        let coverImageData = NSData(contentsOf: (SpotifyPlayer.shared.currentSong?.coverArtURL)!)
        self.coverArtImage.image = UIImage(data: coverImageData! as Data)
    }
}

// MARK: - IBActions
extension MaxiSongCardViewController {
    
    @IBAction func dismissAction(_ sender: Any) {
        animateBackingImageOut()
        animateCoverImageOut()
        animateLowerModuleOut()
        animateImageLayerOut() { _ in
            self.dismiss(animated: false)
        }
    }
    
}

//background image animation
extension MaxiSongCardViewController {
    
    //1. Configure the backing image
    private func configureBackingImageInPosition(presenting: Bool) {
        let edgeInset: CGFloat = presenting ? backingImageEdgeInset : 0
        let dimmerAlpha: CGFloat = presenting ? 0.3 : 0
        let cornerRadius: CGFloat = presenting ? cardCornerRadius : 0
        
        backingImageLeadingInset.constant = edgeInset
        backingImageTrailingInset.constant = edgeInset
        let aspectRatio = backingImageView.frame.height / backingImageView.frame.width
        backingImageTopInset.constant = edgeInset * aspectRatio
        backingImageBottomInset.constant = edgeInset * aspectRatio
        //2. Set the dimmer alpha speed
        dimmerLayer.alpha = dimmerAlpha
        //3. Set the corner radius
        backingImageView.layer.cornerRadius = cornerRadius
    }
    
    //4. Define the animation of the backing image
    private func animateBackingImage(presenting: Bool) {
        UIView.animate(withDuration: primaryDuration) {
            self.configureBackingImageInPosition(presenting: presenting)
            self.view.layoutIfNeeded() //IMPORTANT!
        }
    }
    
    //5. Perform the animation of the backing image In
    func animateBackingImageIn() {
        animateBackingImage(presenting: true)
    }
    //6. Perform the animation of the backing image Out
    func animateBackingImageOut() {
        animateBackingImage(presenting: false)
    }
}


//Image Container animation.
extension MaxiSongCardViewController {
    
    private var startColor: UIColor {
        return UIColor.white.withAlphaComponent(0.3)
    }
    
    private var endColor: UIColor {
        return customPurpleColor
    }
    
    //1.
    private var imageLayerInsetForOutPosition: CGFloat {
        let imageFrame = view.convert(sourceView.originatingFrameInWindow, to: view)
        let inset = imageFrame.minY - backingImageEdgeInset
        return inset
    }
    
    //2.
    func configureImageLayerInStartPosition() {
        coverImageContainer.backgroundColor = startColor
        let startInset = imageLayerInsetForOutPosition
        dismissChevron.alpha = 0
        coverImageContainer.layer.cornerRadius = 0
        coverImageContainerTopInset.constant = startInset
        view.layoutIfNeeded()
    }
    
    //3.
    func animateImageLayerIn() {
        //4.
        UIView.animate(withDuration: primaryDuration / 4.0) {
            self.coverImageContainer.backgroundColor = self.endColor
        }
        
        //5.
        UIView.animate(withDuration: primaryDuration, delay: 0, options: [.curveEaseIn], animations: {
            self.coverImageContainerTopInset.constant = 0
            self.dismissChevron.alpha = 1
            self.coverImageContainer.layer.cornerRadius = self.cardCornerRadius
            self.view.layoutIfNeeded()
        })
    }
    
    //6.
    func animateImageLayerOut(completion: @escaping ((Bool) -> Void)) {
        let endInset = imageLayerInsetForOutPosition
        
        UIView.animate(withDuration: primaryDuration / 4.0,
                       delay: primaryDuration,
                       options: [.curveEaseOut], animations: {
                        self.coverImageContainer.backgroundColor = self.startColor
        }, completion: { finished in
            completion(finished) //fire complete here , because this is the end of the animation
        })
        
        UIView.animate(withDuration: primaryDuration, delay: 0, options: [.curveEaseOut], animations: {
            self.coverImageContainerTopInset.constant = endInset
            self.dismissChevron.alpha = 0
            self.coverImageContainer.layer.cornerRadius = 0
            self.view.layoutIfNeeded()
        })
    }
}

//cover image animation
extension MaxiSongCardViewController {
    //1.
    func configureCoverImageInStartPosition() {
        let originatingImageFrame = sourceView.originatingCoverImageView.frame
        coverImageHeight.constant = originatingImageFrame.height
        coverImageLeading.constant = originatingImageFrame.minX
        coverImageTop.constant = originatingImageFrame.minY
        coverImageBottom.constant = originatingImageFrame.minY
    }
    
    //2.
    func animateCoverImageIn() {
        let coverImageEdgeContraint: CGFloat = 30
        let endHeight = coverImageContainer.bounds.width - coverImageEdgeContraint * 2
        UIView.animate(withDuration: primaryDuration, delay: 0, options: [.curveEaseIn], animations:  {
            self.coverImageHeight.constant = endHeight
            self.coverImageLeading.constant = coverImageEdgeContraint
            self.coverImageTop.constant = coverImageEdgeContraint
            self.coverImageBottom.constant = coverImageEdgeContraint
            self.view.layoutIfNeeded()
        })
    }
    
    //3.
    func animateCoverImageOut() {
        UIView.animate(withDuration: primaryDuration,
                       delay: 0,
                       options: [.curveEaseOut], animations:  {
                        self.configureCoverImageInStartPosition()
                        self.view.layoutIfNeeded()
        })
    }
}

//lower module animation
extension MaxiSongCardViewController {
    
    //1.
    private var lowerModuleInsetForOutPosition: CGFloat {
        let bounds = view.bounds
        let inset = bounds.height - bounds.width
        return inset
    }
    
    //2.
    func configureLowerModuleInStartPosition() {
        lowerModuleTopConstraint.constant = lowerModuleInsetForOutPosition
    }
    
    //3.
    func animateLowerModule(isPresenting: Bool) {
        let topInset = isPresenting ? 0 : lowerModuleInsetForOutPosition
        UIView.animate(withDuration: primaryDuration,
                       delay:0,
                       options: [.curveEaseIn],
                       animations: {
                        self.lowerModuleTopConstraint.constant = topInset
                        self.view.layoutIfNeeded()
        })
    }
    
    //4.
    func animateLowerModuleOut() {
        animateLowerModule(isPresenting: false)
    }
    
    //5.
    func animateLowerModuleIn() {
        animateLowerModule(isPresenting: true)
    }
}
