//
//  PreCallViewController.swift
//  socketWebRTC
//

import UIKit
import SwiftHTTP

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

    
    var mobile_number : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mobile_number = UserDefaults.standard.value(forKey: "mobile_number") as! String
        
        self.submitBtn.layer.borderWidth = 1.0
        self.submitBtn.layer.borderColor = UIColor(red: 39/255, green: 122/255, blue: 1.0, alpha: 1.0).cgColor
        self.submitBtn.layer.cornerRadius = 5.0
        
        getUserInfo()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getUserInfo() {
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenant-locations?phone=\(mobile_number)"
        //        let parameters = [:]
        
        do {
            let opt = try HTTP.GET(urlString, parameters: nil, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if response.error == nil {
                    let data = response.text?.data(using: .utf8)!
                    if let parsedData = try? JSONSerialization.jsonObject(with: data!) as? [String:Any] {
                        if let apartments = parsedData?["apartments"] as? [[String:Any]] {
                            print(apartments)
                        }
                        
                    }
                }else {
                    
                }
            }
        } catch let error {
            print("got an error creating the request: \(error)")
        }
    }
    
    @IBAction func subnitBtnPressed(_ sender: Any) {
        
    }

//    @IBAction func addPhoneNumBtnPressed(_ sender: AnyObject) {
//        
//    }
//
//    @IBAction func callBtnPressed(_ sender: AnyObject) {
//        self.view.removeFromSuperview()
//        UserDefaults.standard.setValue(false, forKey: "fromAPNS")
//        UserDefaults.standard.synchronize()
//        let callConnectVC = self.storyboard?.instantiateViewController(withIdentifier: "callConnectVC") as! CallConnectViewController
//        self.navigationController?.pushViewController(callConnectVC, animated: true)
//    }
//    
//    @IBAction func rotateBtnPressed(_ sender: AnyObject) {
//        self.view.removeFromSuperview()
//    }

}
