//
//  PreCallViewController.swift
//  socketWebRTC
//

import UIKit
import SwiftHTTP
import MZFormSheetPresentationController
import SVProgressHUD

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
    @IBOutlet weak var closeBtn: UIButton!
    
    var mobile_number : String = ""
    var userInfo:User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mobile_number = UserDefaults.standard.value(forKey: "mobile_number") as! String
        
        self.submitBtn.layer.borderWidth = 1.0
        self.submitBtn.layer.borderColor = UIColor(red: 39/255, green: 122/255, blue: 1.0, alpha: 1.0).cgColor
        self.submitBtn.layer.cornerRadius = 5.0

        self.closeBtn.layer.borderWidth = 1.0
        self.closeBtn.layer.borderColor = UIColor(red: 39/255, green: 122/255, blue: 1.0, alpha: 1.0).cgColor
        self.closeBtn.layer.cornerRadius = 5.0

        
        SVProgressHUD.show(withStatus: "Fetching UserInfo...")
        getUserName(completionHandler: {(_state) in
            if !_state {
                self.getUserNamePrequel(completionHandler: { (_state1) in
                    if !_state1 {
                        //do something
                        
                    } else {
                        DispatchQueue.main.async {
                            self.initUI()
                        }
                    }
                    SVProgressHUD.dismiss()
                })
            } else {
                DispatchQueue.main.async {
                    self.initUI()
                }
                SVProgressHUD.dismiss()
            }
        })
        
        // Do any additional setup after loading the view.
    }
    
    func initUI() {
        self.firstNameTextField.text = userInfo?.first
        self.lastNameTextField.text = userInfo?.last
        self.streetLabel.text = userInfo?.street
        self.suiteLabel.text = userInfo?.apt
        self.cityLabel.text = userInfo?.city
        self.stateLabel.text = userInfo?.state
        self.zipCodeLabel.text = userInfo?.zip
        self.phoneNumberLabel.text = mobile_number
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func getUserName( completionHandler: @escaping (_ _state: Bool) -> ()) {
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenants/\(mobile_number)"
        do {
            let opt = try HTTP.GET(urlString, parameters: nil, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if response.error != nil {
                    print("Error in GET : http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenants/\(self.mobile_number)")
                    print(response.text!)
                    completionHandler(false)
                }else {
                    let data = response.text?.data(using: .utf8)!
                    if let parsedData = try? JSONSerialization.jsonObject(with: data!) as? [String:Any] {
                        if let first = parsedData?["first"] as? String {
                            self.userInfo?.first = first
                        }
                        
                        if let last = parsedData?["last"] as? String {
                            self.userInfo?.last = last
                        }
                    }
                    completionHandler(true)
                }
            }
        } catch let error {
            print("got an error creating the request: \(error)")
            completionHandler(false)
        }
    }
    
    func getUserNamePrequel( completionHandler: @escaping (_ _state: Bool) -> ()) {
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/prequal-tenants/\(mobile_number)"
        
        do {
            let opt = try HTTP.GET(urlString, parameters: nil, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if response.error != nil {
                    print("Error in GET : http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/prequal-tenants/\(self.mobile_number)")
                    completionHandler(false)
                }else {
                    let data = response.text?.data(using: .utf8)!
                    if let parsedData = try? JSONSerialization.jsonObject(with: data!) as? [String:Any] {
                        if let first = parsedData?["first"] as? String {
                            self.userInfo?.first = first
                        }
                        
                        if let last = parsedData?["last"] as? String {
                            self.userInfo?.last = last
                        }
                    }
                    completionHandler(true)
                }
            }
        } catch let error {
            print("got an error creating the request: \(error)")
            completionHandler(false)
        }
    }
    
    func updateUserName( completionHandler: @escaping (_ _state: Bool) -> ()) {
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenants/\(self.mobile_number)"
        let parameters = ["id" : mobile_number, "first" : self.firstNameTextField.text!, "last" : self.lastNameTextField.text!]
        
        do {
            let opt = try HTTP.PUT(urlString, parameters: parameters, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if response.error != nil {
                    print("Error in POST http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenants")
                    print(response.text!)
                    completionHandler(false)
                }else {
                    completionHandler(true)
                }
            }
        } catch let error {
            print("got an error creating the request: \(error)")
            
            let alertViewController = UIAlertController(title: "Alert", message: "This application required connection to the internet", preferredStyle: .alert)
            let OkAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertViewController.addAction(OkAction)
            self.present(alertViewController, animated: true, completion: nil)
            
            completionHandler(false)
        }
    }
    
    @IBAction func subnitBtnPressed(_ sender: Any) {
        SVProgressHUD.show(withStatus: "Updating UserInfo")
        self.updateUserName(completionHandler: { (_state) in
            if _state { // Submit is success
                self.dismiss(animated: true, completion: nil)
            } else { // Submit is failed
                self.dismiss(animated: true, completion: nil)
            }
            SVProgressHUD.dismiss()
        })
    }
    
    @IBAction func closeBtnPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
