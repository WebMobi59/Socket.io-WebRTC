//
//  ConfirmViewController.swift
//  socketWebRTC
//

import UIKit
import SwiftHTTP

class ConfirmViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var confirmTextField: UITextField!
    @IBOutlet weak var confirmBtn: UIButton!
    var mobile_number : String = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        mobile_number = UserDefaults.standard.value(forKey: "mobile_number") as! String
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        // Dispose of any resources that can be recreated.
    }
    
    func isValidActivationCode(code : String, completionHandler: @escaping (_ _bool: Int) -> ()){
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenant-authorization/\(mobile_number)"
        let parameters = ["activationCode" : code]
        
        do {
            let opt = try HTTP.PUT(urlString, parameters: parameters, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if response.error != nil {
                    print(response.text!)
                    let data = response.text?.data(using: .utf8)!
                    if let parsedData = try? JSONSerialization.jsonObject(with: data!) as? [String:String] {
                        let reason = (parsedData?["reason"])! as String
                        if reason.contains("rejected") {
                            completionHandler(2)
                        } else {
                            completionHandler(1)
                        }
                    }
                }else {
                    completionHandler(0)
                }
            }
        } catch let error {
            
            completionHandler(2)
            print("got an error creating the request: \(error)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.confirmBtn.layer.cornerRadius = 5.0
    }

    @IBAction func confirmBtnPressed(_ sender: AnyObject) {
        let activationCode = self.confirmTextField.text
        self.isValidActivationCode(code: activationCode! as String) { (_bool) in
            DispatchQueue.main.async {
                if _bool == 0 { // Success
                    let roomVC = self.storyboard?.instantiateViewController(withIdentifier: "roomVC") as! RoomViewController
                    self.navigationController?.pushViewController(roomVC, animated: true)
                } else if _bool == 1 { //Expired
                    let alertViewController = UIAlertController(title: "Alert", message: "Please check the phone number you entered and try again", preferredStyle: .alert)
                    let OkAction = UIAlertAction(title: "OK", style: .default, handler: { (ok) in
                        let registerVC = self.storyboard?.instantiateViewController(withIdentifier: "registerVC") as! RegisterViewController
                        self.navigationController?.pushViewController(registerVC, animated: true)
                    })
                    alertViewController.addAction(OkAction)
                    self.present(alertViewController, animated: true, completion: nil)
                } else { //Rejected
                    let alertViewController = UIAlertController(title: "Alert", message: "The Activation Code you entered is incorrect. Please check the code and try again", preferredStyle: .alert)
                    let OkAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alertViewController.addAction(OkAction)
                    self.present(alertViewController, animated: true, completion: nil)
                }
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
