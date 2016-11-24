//
//  RoomViewController.swift
//  socketWebRTC
//

import UIKit
import SwiftHTTP
import MZFormSheetPresentationController

class RoomViewController: UIViewController {

    @IBOutlet weak var originalView: UIView!
    @IBOutlet weak var roomBtn: UIButton!
    @IBOutlet weak var roomInfoBtn: UIButton!
    
    var mobile_number : String = ""
    var device_token : String = ""
    var userInfo : Dictionary = [
        "first":"",
        "last":"",
        "apt":"",
        "street":"",
        "zip":"",
        "city":"",
        "state":""
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        roomBtn.bringSubview(toFront: originalView)
        mobile_number = UserDefaults.standard.value(forKey: "mobile_number") as! String
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if appDelegate.g_deviceToken != nil {
            device_token = appDelegate.g_deviceToken!
        } else {
            device_token = UserDefaults.standard.value(forKey: "deviceToken") as! String
        }
      

        //set DeviceToken to Server
        registerDeviceTokenWithTenents(completionHandler: {(_state) in
            if _state {
                UserDefaults.standard.setValue(self.device_token, forKey: "deviceToken")
                UserDefaults.standard.synchronize()
            } else {
                self.registerDeviceTokenWithPrequelTenents(completionHandler: { (_state1) in
                    if _state1 {
                        UserDefaults.standard.setValue(self.device_token, forKey: "deviceToken")
                        UserDefaults.standard.synchronize()
                    } else {
                        //do something in the case which got error
                    }
                })
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.roomInfoBtn.layer.cornerRadius = self.roomInfoBtn.layer.frame.width / 2
        getUserInfo(completionHandler: {(_state) in
            if !_state {
                self.getUserInfoPrequel(completionHandler: { (_state1) in
                    if !_state1 {
                        //do something
                    }
                })
            }
        })
    }
    
    func registerDeviceTokenWithTenents( completionHandler: @escaping (_ _state: Bool) -> ()) {
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenants/\(mobile_number)"
        let parameters = ["deviceToken" : device_token]
        
        do {
            let opt = try HTTP.PUT(urlString, parameters: parameters, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if response.error != nil {
                    print("Error in PUT http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenants/\(self.mobile_number)")
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
    
    func registerDeviceTokenWithPrequelTenents( completionHandler: @escaping (_ _state: Bool) -> ()) {
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/prequal-tenants/\(mobile_number)"
        let parameters = ["deviceToken" : device_token]
        
        do {
            let opt = try HTTP.PUT(urlString, parameters: parameters, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if response.error != nil {
                    print("Error in PUT http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/prequal-tenants/\(self.mobile_number)")
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
    
    func getUserInfo( completionHandler: @escaping (_ _state: Bool) -> ()) {
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
                        if parsedData?["first"] != nil {
                            self.userInfo["first"] = parsedData?["first"] as? String
                        }
                        if parsedData?["last"] != nil {
                            self.userInfo["last"] = parsedData?["last"] as? String
                        }
                        if parsedData?["apt"] != nil {
                            self.userInfo["apt"] = parsedData?["apt"] as? String
                        }
                        if parsedData?["street"] != nil {
                            self.userInfo["street"] = parsedData?["street"] as? String
                        }
                        if parsedData?["zip"] != nil {
                            self.userInfo["zip"] = parsedData?["zip"] as? String
                        }
                        if parsedData?["state"] != nil {
                            self.userInfo["state"] = parsedData?["state"] as? String
                        }
                        self.roomBtn.titleLabel?.text = self.userInfo["apt"]! + self.userInfo["street"]!
                    }
                    completionHandler(true)
                }
            }
        } catch let error {
            print("got an error creating the request: \(error)")
            completionHandler(false)
        }
    }
    
    func getUserInfoPrequel( completionHandler: @escaping (_ _state: Bool) -> ()) {
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
                        if parsedData?["first"] != nil {
                            self.userInfo["first"] = parsedData?["first"] as? String
                        }
                        if parsedData?["last"] != nil {
                            self.userInfo["last"] = parsedData?["last"] as? String
                        }
                        if parsedData?["apt"] != nil {
                            self.userInfo["apt"] = parsedData?["apt"] as? String
                        }
                        if parsedData?["street"] != nil {
                            self.userInfo["street"] = parsedData?["street"] as? String
                        }
                        if parsedData?["zip"] != nil {
                            self.userInfo["zip"] = parsedData?["zip"] as? String
                        }
                        if parsedData?["state"] != nil {
                            self.userInfo["state"] = parsedData?["state"] as? String
                        }
                        self.roomBtn.titleLabel?.text = self.userInfo["apt"]! + self.userInfo["street"]!
                    }
                    completionHandler(true)
                }
            }
        } catch let error {
            print("got an error creating the request: \(error)")
            completionHandler(false)
        }
    }

    @IBAction func roomBtnPressed(_ sender: AnyObject) {
        DispatchQueue.main.async {
            let CallVC = self.storyboard?.instantiateViewController(withIdentifier: "callConnectVC") as! CallConnectViewController
            self.navigationController?.pushViewController(CallVC, animated: true)
        }
    }
    
    @IBAction func roomInfoBtnPressed(_ sender: AnyObject) {
        
        let userInfoDialog = self.storyboard?.instantiateViewController(withIdentifier: "preCallVC") as! PreCallViewController
        userInfoDialog.userInfo = self.userInfo
        let formSheetController = MZFormSheetPresentationViewController(contentViewController: userInfoDialog)
        formSheetController.presentationController?.contentViewSize = CGSize(width: 300, height: 400)  // or pass in UILayoutFittingCompressedSize to size automatically with auto-layout
        formSheetController.contentViewControllerTransitionStyle = .bounce
        self.present(formSheetController, animated: true, completion: nil)
    }
}
