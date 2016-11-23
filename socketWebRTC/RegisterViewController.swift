//
//  RegisterViewController.swift
//  socketWebRTC
//

import UIKit
import SwiftHTTP

class RegisterViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var phonenumberTextField: UITextField!
    @IBOutlet weak var submitBtn: UIButton!
    let deviceToken = UserDefaults.standard.value(forKey: "deviceToken")
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.submitBtn.layer.cornerRadius = 5.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func isAlreadyRegistger(number : String, completionHandler: @escaping (_ _state: Int) -> ()){
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenant-authorization"//API change        
        let parameters = ["id" : number]
        
        do {
            let opt = try HTTP.POST(urlString, parameters: parameters, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if response.error != nil {
                    completionHandler(1)
                } else {
                    completionHandler(0)
                }
            }
        } catch let error {
            completionHandler(-1)
            print("got an error creating the request: \(error)")
        }
    }
    
    @IBAction func submitBtnClick(_ sender: AnyObject) {
        if let phonenumber = self.phonenumberTextField.text {
            self.isAlreadyRegistger(number: phonenumber, completionHandler: { (_state) in
                DispatchQueue.main.async{
                    UserDefaults.standard.setValue(phonenumber, forKey: "mobile_number")
                    UserDefaults.standard.synchronize()
                    if _state == 0 { // OK
                        let confirmVC = self.storyboard?.instantiateViewController(withIdentifier: "confirmVC") as! ConfirmViewController
                        self.navigationController?.pushViewController(confirmVC, animated: true)
                    } else if _state == 1 { // Unknown
                        let addUserInfoVC = self.storyboard?.instantiateViewController(withIdentifier: "addUserInfoVC") as! AddUserInfoViewController
                        self.navigationController?.pushViewController(addUserInfoVC, animated: true)
                    } else {
                        let alertViewController = UIAlertController(title: "Alert", message: "Network connection was failed. Please check your connection and try again later", preferredStyle: .alert)
                        let OkAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                        alertViewController.addAction(OkAction)
                        self.present(alertViewController, animated: true, completion: nil)
                    }
                }
                
            })
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField == self.phonenumberTextField){
            phonenumberTextField.resignFirstResponder()
        }
        return true
    }
}
