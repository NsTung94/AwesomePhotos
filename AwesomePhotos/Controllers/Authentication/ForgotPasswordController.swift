//
//  ForgotPasswordController.swift
//  AwesomePhotos
//
//  Created by Apple on 3/31/19.
//  Copyright © 2019 Minh Quang Pham. All rights reserved.
//

import UIKit
import Firebase
import SnapKit

//ForgotPasswordController for ForgotPasswordView
class ForgotPasswordController : GenericViewController<ForgotPasswordView>, UITextFieldDelegate {
    
    //MARK: - Init
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
        navigationItem.largeTitleDisplayMode = .automatic
        navigationController?.navigationBar.prefersLargeTitles = true

        navigationItem.title = "Reset Password"

        //To lock screen in portrait mode
        super.viewWillAppear(animated)
        let appdelegate = UIApplication.shared.delegate as! AppDelegate
        appdelegate.shouldSupportOrientation = .portrait // set desired orientation
        let value = UIInterfaceOrientation.portrait.rawValue // set desired orientation
        UIDevice.current.setValue(value, forKey: "orientation")
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavBar(title: "")
        hideKeyboardWhenTappedAround()
        //Delegate textfields to make keyboard disappear when tap Return on keyboard
        contentView.emailTextField.delegate = self
    }
    
    //Function to make keyboard disappear when tap Return on keyboard
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        contentView.emailTextField.resignFirstResponder()
        return true
    }
    
    
    //MARK: - Selectors    
    @objc func handleForgotPassword() {
        guard let email = contentView.emailTextField.text else { return }
        sendResetPassword(email: email)
    }
    
    @objc override func handleGoBack() {
        navigationController?.popViewController(animated: true)
    }

    
    //MARK: - API
    func sendResetPassword(email: String) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in //Attempt to send reset password email
            //If send email fails
            if let error = error {
                let alert = AlertService.basicAlert(imgName: "GrinFace", title: "Email sending failed", message: error.localizedDescription)
                self.present(alert, animated: true)
                return
            }
            //If send email succeeds
            let alert = AlertService.basicAlert(imgName: "WinkFace",title: "Help is on the way!",message: "Check your inbox for a password reset link")
            self.present(alert, animated: true)
            
            self.contentView.emailTextField.text = ""
        }
    }
}
