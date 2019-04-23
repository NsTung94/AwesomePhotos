import Foundation
import UIKit
import FirebaseStorage
import Firebase

class PreviewmageViewController : UIViewController{
    
    //MARK: - Properties
    @IBOutlet weak var photo: UIImageView!
    var image : UIImage!
    let db = Firestore.firestore()
    
    //MARK: - Initialization
    override func viewDidLoad() {
        super.viewDidLoad()
        photo.image = self.image
    }
    
    //MARK: - Methods
    
    //Uploads the taken photo to Firebase Storage
    @IBAction func savePhotoBtnPressed(_ sender: UIButton) {
        let id = UUID()
        let photoName = id.uuidString
        guard let imageData = image.jpegData(compressionQuality: 0.55) else { return }
        
        //Upload to Firestore
        let data = ["name": photoName + ".jpg"]
        var ref: DocumentReference? = nil
        ref = db.collection("photos").addDocument(data: data) { (error) in
            if let error = error {
                print(error.localizedDescription)
            } else {
                print("Upload to Firestore finished")
            }
        }
        
        //Upload to Firebase
        for (_,value) in PhotoTypesConstants {
            let storageReference : StorageReference = {
                return Storage.storage().reference(forURL: "gs://awesomephotos-b794e.appspot.com/").child("User/doc12/Uploads/Photo/\((ref?.documentID)!)/\(value)")
            }()
            
            let uploadImageRef = storageReference.child(id.uuidString + "-\(value).jpg")
            _ = uploadImageRef.putData(imageData, metadata : nil) { (metadata, error) in
                if let error = error {
                    print(error.localizedDescription)
                } else {
                    print("Upload to Firebase finished")
                }
            }
            
//            uploadTask.observe(.progress){ (snapshot) in
//                print(snapshot.progress ?? "Progress cancelled")
//            }
//            uploadTask.resume()
//            dismiss(animated: true, completion: nil)
        }
    }
    //Saves the photo to local storage
    @IBAction func saveToLocalButtonPressed(_ sender: UIButton) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        dismiss(animated: true, completion: nil)
    }

    
    //Returns the users to the camera
    @IBAction func cancelBtnPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
}