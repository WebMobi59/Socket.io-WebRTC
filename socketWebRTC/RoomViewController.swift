//
//  RoomViewController.swift
//  socketWebRTC
//

import UIKit
import SwiftHTTP
import MZFormSheetPresentationController
import SVProgressHUD

class RoomViewController: UIViewController {

    @IBOutlet weak var originalView: UIView!
    @IBOutlet weak var roomBtn: UIButton!
    @IBOutlet weak var roomInfoBtn: UIButton!
    
    var mobile_number : String = ""
    var device_token : String = ""
    var _user: User?
    
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
      
        SVProgressHUD.show(withStatus: "Loading UserInfo...")

        self.registerDeviceTokenWithTenents(completionHandler: {(_state) in
            if _state {
                UserDefaults.standard.setValue(self.device_token, forKey: "deviceToken")
                UserDefaults.standard.synchronize()
                
                self.getUserInfomation()
            } else {
                self.registerDeviceTokenWithPrequelTenents(completionHandler: { (_state1) in
                    if _state1 {
                        UserDefaults.standard.setValue(self.device_token, forKey: "deviceToken")
                        UserDefaults.standard.synchronize()
                        
                        
                            self.getUserInfomation()
                        
                    } else {
                        //do something in the case which got error
                        SVProgressHUD.dismiss()
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
    }
    
    func getUserInfomation() {
        self.getUserInfo(completionHandler: {(_state) in
            if !_state {
                self.getUserInfoPrequel(completionHandler: { (_state1) in
                    if !_state1 {
                        //do something
                    } else {
                        DispatchQueue.main.async {
                            self.roomBtn.setTitle((self._user?.apt)! + " " + (self._user?.street)!, for: .normal)
                        }
                    }
                    SVProgressHUD.dismiss()
                })
            } else {
                DispatchQueue.main.async {
                    self.roomBtn.setTitle((self._user?.apt)! + " " + (self._user?.street)!, for: .normal)
                }
                SVProgressHUD.dismiss()
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
            
            let alertViewController = UIAlertController(title: "Alert", message: "This application required connection to the internet", preferredStyle: .alert)
            let OkAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertViewController.addAction(OkAction)
            self.present(alertViewController, animated: true, completion: nil)
            
            completionHandler(false)
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
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenant-locations?phone=\(mobile_number)"
        do {
            let opt = try HTTP.GET(urlString, parameters: nil, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if response.error != nil {
                    print("Error in GET : http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenant-locations?phone=\(self.mobile_number)")
                    print(response.text!)
                    completionHandler(false)
                }else {
                    let data = response.text?.data(using: .utf8)!
                    if let parsedData = try? JSONSerialization.jsonObject(with: data!) as! [String:Any] {
                        if let userDataArr = parsedData["apartments"] as? [Any] {
                            if let userData = userDataArr[0] as? [String: Any] {
                                let tmpUser = User()
                                if let first = userData["first"] as? String {
                                    tmpUser.first = first
                                }
                                
                                if let last = userData["last"] as? String {
                                    tmpUser.last = last
                                }
                                
                                if let apt = userData["apt"] as? String {
                                    tmpUser.apt = apt
                                }
                                
                                if let street = userData["street"] as? String {
                                    tmpUser.street = street
                                }
                                
                                if let zip = userData["zip"] as? String {
                                    tmpUser.zip = zip
                                }
                                
                                
                                if let state = userData["state"] as? String {
                                    tmpUser.state = state
                                }
                                
                                self._user = tmpUser
                            }
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
                    if let parsedData = try? JSONSerialization.jsonObject(with: data!) as! [String:Any] {
                        if let userDataArr = parsedData["apartments"] as? [Any] {
                            if let userData = userDataArr[0] as? [String: Any] {
                                let tmpUser = User()
                                if let first = userData["first"] as? String {
                                    tmpUser.first = first
                                }
                                
                                if let last = userData["last"] as? String {
                                    tmpUser.last = last
                                }
                                
                                if let apt = userData["apt"] as? String {
                                    tmpUser.apt = apt
                                }
                                
                                if let street = userData["street"] as? String {
                                    tmpUser.street = street
                                }
                                
                                if let zip = userData["zip"] as? String {
                                    tmpUser.zip = zip
                                }
                                
                                
                                if let state = userData["state"] as? String {
                                    tmpUser.state = state
                                }
                                
                                self._user = tmpUser
                                
                            }
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

    @IBAction func roomBtnPressed(_ sender: AnyObject) {
        DispatchQueue.main.async {
            let CallVC = self.storyboard?.instantiateViewController(withIdentifier: "callConnectVC") as! CallConnectViewController
            self.navigationController?.pushViewController(CallVC, animated: true)
        }
    }
    
    @IBAction func roomInfoBtnPressed(_ sender: AnyObject) {
        
        let userInfoDialog = self.storyboard?.instantiateViewController(withIdentifier: "preCallVC") as! PreCallViewController
        userInfoDialog.userInfo = self._user
        let formSheetController = MZFormSheetPresentationViewController(contentViewController: userInfoDialog)
        formSheetController.presentationController?.contentViewSize = CGSize(width: 300, height: 400)  // or pass in UILayoutFittingCompressedSize to size automatically with auto-layout
        formSheetController.contentViewControllerTransitionStyle = .bounce
        self.present(formSheetController, animated: true, completion: nil)
    }
}
