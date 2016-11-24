//
//  PreCallViewController.swift
//  socketWebRTC
//

import UIKit
import SwiftHTTP
import MZFormSheetPresentationController

class PreCallViewController: UIViewController {


    @IBOutlet weak var firstNameTextField: UITextField!
    @IBOutlet weak var lastNameTextField: UITextField!
    @IBOutlet weak var streetLabel: UILabel!
    @IBOutlet weak var suiteLabel: UILabel!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var zipCodeLabel: UILabel!
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var indicatorLoading: UIActivityIndicatorView!
    
    var mobile_number : String = ""
    var userInfo = [String:String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mobile_number = UserDefaults.standard.value(forKey: "mobile_number") as! String
        
        self.submitBtn.layer.borderWidth = 1.0
        self.submitBtn.layer.borderColor = UIColor(red: 39/255, green: 122/255, blue: 1.0, alpha: 1.0).cgColor
        self.submitBtn.layer.cornerRadius = 5.0
        
        initUI()
//        getUserInfo()
        // Do any additional setup after loading the view.
    }
    
    func initUI() {
        self.firstNameTextField.text = userInfo["first"]
        self.lastNameTextField.text = userInfo["last"]
        self.streetLabel.text = userInfo["street"]
        self.suiteLabel.text = userInfo["apt"]
        self.cityLabel.text = userInfo["city"]
        self.stateLabel.text = userInfo["state"]
        self.zipCodeLabel.text = userInfo["zip"]
        self.phoneNumberLabel.text = mobile_number
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateUserName( completionHandler: @escaping (_ _state: Bool) -> ()) {
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/debug/prequal-tenants"
        let parameters = ["id" : mobile_number, "first" : self.firstNameTextField.text!, "last" : self.lastNameTextField.text!]
        
        do {
            let opt = try HTTP.POST(urlString, parameters: parameters, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if response.error != nil {
                    print("Error in POST http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/debug/prequal-tenants")
                    print(response.text!)
                    completionHandler(false)
                }else {
                    completionHandler(true)
                }
            }
        } catch let error {
            print("got an error creating the request: \(error)")
        }
    }
    
    @IBAction func subnitBtnPressed(_ sender: Any) {
        self.submitBtn.isEnabled = false
        self.indicatorLoading.startAnimating()
        self.updateUserName(completionHandler: { (_state) in
            if _state { // Submit is success
                self.dismiss(animated: true, completion: nil)
            } else { // Submit is failed
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
}
