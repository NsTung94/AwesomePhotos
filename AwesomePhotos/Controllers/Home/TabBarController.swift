//
//  TabBarController.swift
//  AwesomePhotos
//
//  Created by User on 5/3/19.
//

import UIKit
import Firebase
import FirebaseUI
import AVFoundation
import MediaWatermark

class TabBarController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    @IBOutlet weak var libraryCollectionView: UICollectionView!
    @IBOutlet weak var mySegmentedControl: UISegmentedControl!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    lazy var db = Firestore.firestore()
    lazy var userUid = Auth.auth().currentUser?.uid
    
    var photosUid: [String] = []
    var ownedPhotosUid: [String] = []
    var nwmPhotosUid: [String] = []
    var wmPhotosUid: [String] = []
    
    var videosUid: [String] = []
    var ownedVideosUid: [String] = []
    var nwmVideosUid: [String] = []
    var wmVideosUid: [String] = []
    
    var showPhotos = true
    
    let thumbnailCache = NSCache<NSString, UIImage>()
    
    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action:#selector(handleRefresh),for: UIControl.Event.valueChanged)
        refreshControl.tintColor = UIColor.mainRed()
        return refreshControl
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.libraryCollectionView.addSubview(self.refreshControl)
        fetchPhotos()
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showPhotos {
            return photosUid.count
        } else {
            return videosUid.count
        }
    }
    
    
    fileprivate func showPhotos(_ indexPath: IndexPath, _ cell: LibraryCollectionViewCell) {
        self.activityIndicator.startAnimating()
        let photoUid = photosUid[indexPath.row]
        cell.myImage.image = nil
        DispatchQueue.global().async {
            self.db.collection("photos").document(photoUid).getDocument{document, error in
                if let document = document, document.exists {
                    guard let data = document.data() else { return }
                    var photoType = ""
                    if self.ownedPhotosUid.contains(photoUid) {
                        photoType = "pathToOG"
                    } else if self.nwmPhotosUid.contains(photoUid) {
                        photoType = "pathToNWM"
                    } else {
                        photoType = "pathToWM"
                    }
                    if photoType == "" { return }
                    let reference = Storage.storage()
                        .reference(forURL: "gs://awesomephotos-b794e.appspot.com/")
                        .child(data[photoType] as! String)
                    cell.filePath = data[photoType] as? String
                    cell.photoUid = photoUid
                    DispatchQueue.main.async {
                        cell.myImage.sd_setImage(with: reference, placeholderImage: UIImage(named: "SleepFace"))
                        self.activityIndicator.stopAnimating()
                    }
                } else {
                    print("Document does not exist")
                    return
                }
            }
        }
    }
    
    fileprivate func showVideos(_ indexPath: IndexPath, _ cell: LibraryCollectionViewCell) {
        self.activityIndicator.startAnimating()
        let videoUid = videosUid[indexPath.row]
        cell.myImage.image = nil
        self.db.collection("medias").document(videoUid).getDocument{document, error in
            if let document = document, document.exists {
                guard let data = document.data() else { return }
                var videoType: String
                if self.ownedVideosUid.contains(videoUid) {
                    videoType = "pathToOG"
                } else if self.nwmVideosUid.contains(videoUid) {
                    videoType = "pathToNWM"
                } else {
                    videoType = "pathToWM"
                }
                // If there is cache
                if let imageFromCache = self.thumbnailCache.object(forKey: videoUid as NSString) {
                    cell.myImage.image = imageFromCache
                    self.activityIndicator.stopAnimating()
                // If the is no cache
                } else {
                    let reference = Storage.storage().reference(forURL: "gs://awesomephotos-b794e.appspot.com/").child(data[videoType] as! String)
                    reference.downloadURL { url, error in
                        if let error = error {
                            print(error.localizedDescription)
                        } else {
                            let downloadURL = url
                            let thumbnail = self.createThumbnailOfVideoFromRemoteUrl(url: downloadURL!.absoluteString)
                            DispatchQueue.global(qos: .background).async {
                                if thumbnail != nil {
                                    let mediaProcessor = MediaProcessor()
                                    mediaProcessor.processElements(item: self.makeWmCopyOfImage(thumbnail: thumbnail!)) {(result, error) in
                                        DispatchQueue.main.async {
                                            self.thumbnailCache.setObject(result.image!, forKey: videoUid as NSString)
                                            cell.myImage.image = result.image
                                            self.activityIndicator.stopAnimating()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                cell.filePath = data[videoType] as? String
                cell.photoUid = videoUid
            } else {
                print("Document does not exist")
                return
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! LibraryCollectionViewCell

        if showPhotos {
            showPhotos(indexPath, cell)
        } else {
            showVideos(indexPath, cell)
        }
        return cell
    }
    
    fileprivate func showImageView(_ indexPath: IndexPath) {
        // Instatiate the image view
        let ownedImageViewStoryboard: UIStoryboard = UIStoryboard(name: "OwnedImageView", bundle: nil)
        let ownedImageViewController: OwnedImageViewController = ownedImageViewStoryboard.instantiateViewController(withIdentifier: "ownedImageViewController") as! OwnedImageViewController
        let selectedCell = libraryCollectionView.cellForItem(at: indexPath) as! LibraryCollectionViewCell
        // Pass properties
        ownedImageViewController.filePath = selectedCell.filePath
        ownedImageViewController.photoUid = selectedCell.photoUid
        ownedImageViewController.owned = ownedPhotosUid.contains(selectedCell.photoUid!)
        ownedImageViewController.shared = nwmPhotosUid.contains(selectedCell.photoUid!)
        ownedImageViewController.wm = wmPhotosUid.contains(selectedCell.photoUid!)
        // Move to image view
        let navController = UINavigationController(rootViewController: ownedImageViewController)
        self.present(navController, animated: true, completion: nil)
    }
    
    fileprivate func showVideoPlaybackView(_ indexPath: IndexPath) {
        // Instatiate the video playback view
        let videoPlaybackStoryboard: UIStoryboard = UIStoryboard(name: "VideoPreview", bundle: nil)
        let videoPlaybackController: VideoPlaybackController = videoPlaybackStoryboard.instantiateViewController(withIdentifier: "VideoPlaybackController") as! VideoPlaybackController
        let selectedCell = libraryCollectionView.cellForItem(at: indexPath) as! LibraryCollectionViewCell
        let reference = Storage.storage()
            .reference(forURL: "gs://awesomephotos-b794e.appspot.com/")
            .child(selectedCell.filePath!)
        // Fetch the download URL
        reference.downloadURL {[unowned self] (url, error) in
            if let error = error {
                self.present(AlertService.basicAlert(imgName: "GrinFace", title: "Download Failed", message: error.localizedDescription), animated: true, completion: nil)
            } else {
                let downloadURL = url
                // Pass properties
                videoPlaybackController.videoURL = downloadURL
                videoPlaybackController.owned = self.ownedVideosUid.contains(selectedCell.photoUid!)
                videoPlaybackController.shared = self.nwmVideosUid.contains(selectedCell.photoUid!)
                videoPlaybackController.wm = self.wmVideosUid.contains(selectedCell.photoUid!)
                videoPlaybackController.videoUid = selectedCell.photoUid
                videoPlaybackController.thumbnail = selectedCell.myImage.image
                // Move to video playback view
                let navController = UINavigationController(rootViewController: videoPlaybackController)
                self.present(navController, animated: true, completion: nil)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if showPhotos {
            showImageView(indexPath)
        } else {
            showVideoPlaybackView(indexPath)
        }
    }
    
    func createThumbnailOfVideoFromRemoteUrl(url: String) -> UIImage? {
        let asset = AVAsset(url: URL(string: url)!)
        let assetImgGenerate = AVAssetImageGenerator(asset: asset)
        assetImgGenerate.appliesPreferredTrackTransform = true
        let time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 100)
        do {
            let img = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: img)
            return thumbnail
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    fileprivate func makeWmCopyOfImage(thumbnail: UIImage) -> MediaItem {
        let item = MediaItem(image: thumbnail)
        let playIcon = UIImage(named: "icons8-play_filled")
        let firstElement = MediaElement(image: playIcon!)
        firstElement.frame = CGRect(x: item.size.width/2-item.size.width/11, y: item.size.height/2-item.size.height/11, width: item.size.width/5, height: item.size.height/5)
        item.add(elements: [firstElement])
        return item
    }
    
    @IBAction func switchCustom(_ sender: UISegmentedControl) {
        showPhotos = !showPhotos
        libraryCollectionView.reloadData()
    }
    
    @IBOutlet var filterChoices: [UIButton]!
    
    @IBAction func filterAction(_ sender: UIButton) {
        filterChoices.forEach { (button) in
        button.isHidden = !button.isHidden }
    }
    
    
    @IBAction func filterChoicesTapped(_ sender: UIButton) {
    }
    
    fileprivate func clearArrays() {
        self.ownedPhotosUid.removeAll()
        self.nwmPhotosUid.removeAll()
        self.wmPhotosUid.removeAll()
        self.photosUid.removeAll()
        self.videosUid.removeAll()
        self.ownedVideosUid.removeAll()
        self.nwmVideosUid.removeAll()
        self.wmVideosUid.removeAll()
    }
    
    func fetchPhotos() {
        self.db.collection("users").document(userUid!).addSnapshotListener{snapshot, error in
            self.clearArrays()
            if let document = snapshot, document.exists {
                guard let data = document.data() else { return }
                // Photos
                self.ownedPhotosUid = data["ownedPhotos"] as! [String]
                self.nwmPhotosUid = data["sharedPhotos"] as! [String]
                self.wmPhotosUid = data["wmPhotos"] as! [String]
                self.photosUid += data["ownedPhotos"] as! [String]
                self.photosUid += data["sharedPhotos"] as! [String]
                self.photosUid += data["wmPhotos"] as! [String]
                
                // Videos
                self.ownedVideosUid = data["ownedVideos"] as! [String]
                self.nwmVideosUid = data["sharedVideos"] as! [String]
                self.wmVideosUid = data["wmVideos"] as! [String]
                self.videosUid += data["ownedVideos"] as! [String]
                self.videosUid += data["sharedVideos"] as! [String]
                self.videosUid += data["wmVideos"] as! [String]
                
            } else {
                print("Document does not exist")
                return
            }
        }
        DispatchQueue.main.async {
            self.libraryCollectionView.reloadData() // breakpoint here to see if storyNames still empty
        }
    }
    
    // Refresh control
    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        self.libraryCollectionView.reloadData()
        refreshControl.endRefreshing()
    }
}


