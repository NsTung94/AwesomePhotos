//
//  ProgressTableViewCellControllerTableViewCell.swift
//  AwesomePhotos
//
//  Created by Rasmus Petersen on 09/05/2019.
//

import UIKit

let progressCapturedKey = "AwesomePhotos.ProgressCaptured"
let thumbnailCapturedKey = "AwesomePhotos.ThumbnailCaptured"
let progressBarNotification = Notification.Name(rawValue: progressCapturedKey)
let thumbnailNotification = Notification.Name(rawValue: thumbnailCapturedKey)


class ProgressTableViewCellControllerTableViewCell: UITableViewCell {
    
    @IBOutlet weak var abortButton: UIButton!
    @IBOutlet weak var uploadName: UILabel!
    @IBOutlet weak var progressBarView: UIProgressView!
    @IBOutlet weak var thumbnailImage: UIImageView!
    

    var previewVC = PreviewmageViewController()
    var cameraVC = CameraViewController()
    lazy var smallId = randomStringWithLength(len: 6)
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        progressBarView.layer.cornerRadius = 8
        progressBarView.clipsToBounds = true
        progressBarView.layer.sublayers![1].cornerRadius = 8
        progressBarView.subviews[1].clipsToBounds = true
        
        
        NotificationCenter.default.addObserver(forName: thumbnailNotification,
                                               object: nil,
                                               queue: nil,
                                               using: catchThumbnail)
        
        NotificationCenter.default.addObserver(forName: progressBarNotification,
                                               object: nil,
                                               queue: nil,
                                               using: catchProgressNotification)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    //Removes leftover observers
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func populateTableCell(progressCell : Progress){
        uploadName.text = progressCell.label
        progressBarView.progress = Float(progressCell.progress)
        thumbnailImage?.image = progressCell.image
    }
    
    func catchThumbnail(notification : Notification){

        guard let thumbNail = notification.userInfo as? [String : UIImage] else {return}
        for (value) in thumbNail.values{
            print(value)
            self.thumbnailImage.image = value
            self.thumbnailImage.sizeToFit()
        }
    }

    func catchProgressNotification(notification : Notification) {
        
        uploadName.text = "IMG_\(smallId).JPG" as String
        guard let progress = notification.userInfo as? [String : Float] else { return }
        for (value) in progress.values {
            progressBarView.setProgress(value, animated: true)
        }
    }

    
    func randomStringWithLength(len: Int) -> NSString {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        
        let randomString : NSMutableString = NSMutableString(capacity: len)
        
        for _ in 1...len{
            let length = UInt32 (letters.length)
            let rand = arc4random_uniform(length)
            randomString.appendFormat("%C", letters.character(at: Int(rand)))
        }
        return randomString
    }
    var isPaused = false
    @IBAction func abortSequenceButtonPressed(_ sender: UIButton) {
        
        if isPaused == false{
            cameraVC.uploadTask?.pause()
            progressBarView.setProgress(0.0, animated: true)
            uploadName.text = "Upload Cancelled"
            abortButton.setImage(UIImage(named: "upload"), for: .normal)
            isPaused = true
        }
        else{
            cameraVC.uploadTask?.resume()
            abortButton.setImage(UIImage(named: "Close"), for: .normal)
            abortButton.tintColor = .red
            NotificationCenter.default.addObserver(forName: progressBarNotification,
                                                   object: nil,
                                                   queue: nil,
                                                   using: catchProgressNotification)
            isPaused = false
        }

    }
    
}

