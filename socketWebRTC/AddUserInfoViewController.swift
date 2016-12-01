//
//  AddUserInfoViewController.swift
//  socketWebRTC
//

import UIKit
import SwiftHTTP

class AddUserInfoViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var firstnameTextField: UITextField!
    @IBOutlet weak var lastnameTextField: UITextField!
    @IBOutlet weak var streetTextField: UITextField!
    @IBOutlet weak var aptTextField: UITextField!
    @IBOutlet weak var cityTextField: UITextField!
    @IBOutlet weak var stateTextField: UITextField!
    @IBOutlet weak var zipcodeTextField: UITextField!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var phonenumberLabel: UILabel!
    
    var mobile_number : String = ""
    var device_token : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mobile_number = UserDefaults.standard.value(forKey: "mobile_number") as! String
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        device_token = appDelegate.g_deviceToken!
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.phonenumberLabel.text = mobile_number
        self.submitBtn.layer.cornerRadius = 5.0
        self.closeBtn.layer.cornerRadius = 5.0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func isAddUser( completionHandler: @escaping (_ _bool: Bool) -> ()){
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/prequal-tenants"
        let parameters = [
            "id" : self.mobile_number,
            "first" : self.firstnameTextField.text!,
            "last" : self.lastnameTextField.text!,
            "deviceToken" : device_token,
            "street" : self.streetTextField.text!,
            "city" : self.cityTextField.text!,
            "state" : self.stateTextField.text!,
            "zip" : self.zipcodeTextField.text!
        ]
        
        do {
            let opt = try HTTP.POST(urlString, parameters: parameters, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if let err = response.error {
                    print("isAddUserNameWithPhoneNumber ===> error: \(err.localizedDescription)")
                    completionHandler(false)
                } else {
                    completionHandler(true)
                }
            }
        } catch let error {

            let alertViewController = UIAlertController(title: "Alert", message: "This application required connection to the internet", preferredStyle: .alert)
            let OkAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertViewController.addAction(OkAction)
            self.present(alertViewController, animated: true, completion: nil)
            
            completionHandler(false)

            print("got an error creating the request: \(error)")
        }
    }
    
    func isAddUserUpdate( completionHandler: @escaping (_ _bool: Bool) -> ()){
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/prequal-tenants/\(mobile_number)"
        let parameters = [
            "first" : self.firstnameTextField.text!,
            "last" : self.lastnameTextField.text!,
            "deviceToken" : device_token,
            "street" : self.streetTextField.text!,
            "city" : self.cityTextField.text!,
            "state" : self.stateTextField.text!,
            "zip" : self.zipcodeTextField.text!
        ]
        
        do {
            let opt = try HTTP.PUT(urlString, parameters: parameters, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if let err = response.error {
                    print("isAddUserNameWithPhoneNumber ===> error: \(err.localizedDescription)")
                    completionHandler(false)
                } else {
                    completionHandler(true)
                }
            }
        } catch let error {
            completionHandler(false)
            print("got an error creating the request: \(error)")
        }
    }
    
    @IBAction func submitBtnPressed(_ sender: AnyObject) {
        let alertViewController = UIAlertController(title: "Notice", message: "Thank you for registering your information. We will notify you once your account is activated", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler:{ (ok) in
            self.isAddUser() { (_bool) in
                if _bool {
                    DispatchQueue.main.async {
                        let roomVC = self.storyboard?.instantiateViewController(withIdentifier: "roomVC") as! RoomViewController
                        self.navigationController?.pushViewController(roomVC, animated: true)
                        
                    }
                } else {
                    self.isAddUserUpdate(completionHandler: { (_bool1) in
                        if _bool {
                            DispatchQueue.main.async {
                                let roomVC = self.storyboard?.instantiateViewController(withIdentifier: "roomVC") as! RoomViewController
                                self.navigationController?.pushViewController(roomVC, animated: true)
                                
                            }
                        } else {
                            
                        }
                    })
                }
            }
        })
        alertViewController.addAction(okAction)
        self.present(alertViewController, animated: true, completion: nil)
    }

    @IBAction func closeBtnPressed(_ sender: Any) {
        DispatchQueue.main.async {
            let roomVC = self.storyboard?.instantiateViewController(withIdentifier: "roomVC") as! RoomViewController
            self.navigationController?.pushViewController(roomVC, animated: true)
        }
    }

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == firstnameTextField {
            lastnameTextField.becomeFirstResponder()
        } else if textField == lastnameTextField {
            streetTextField.becomeFirstResponder()
        } else if textField == streetTextField {
            aptTextField.becomeFirstResponder()
        } else if textField == aptTextField {
            cityTextField.becomeFirstResponder()
        } else if textField == cityTextField {
            stateTextField.becomeFirstResponder()
        } else if textField == stateTextField {
            zipcodeTextField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
