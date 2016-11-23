//
//  RoomViewController.swift
//  socketWebRTC
//

import UIKit
import SwiftHTTP

class RoomViewController: UIViewController {

    @IBOutlet weak var originalView: UIView!
    @IBOutlet weak var roomBtn: UIButton!
    @IBOutlet weak var roomInfoBtn: UIButton!
    
    var mobile_number : String = ""
    var device_token : String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        roomBtn.bringSubview(toFront: originalView)
        mobile_number = UserDefaults.standard.value(forKey: "mobile_number") as! String
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        device_token = appDelegate.g_deviceToken!
        
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
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/tenant-locations/\(mobile_number)"
//        let parameters = [:]
        
        do {
            let opt = try HTTP.GET(urlString, parameters: nil, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if response.error != nil {
                    completionHandler(false)
                }else {
                    let data = response.text?.data(using: .utf8)!
                    if let parsedData = try? JSONSerialization.jsonObject(with: data!) as? [String:Any] {
                        if let apartments = parsedData?["apartments"] as? [[String:Any]] {
//                            if let apt = apartments[0]["apt"] as? String {
//                                let adr = apt + String(describing: apartments[1]["street"])
//                                self.roomInfoLabel.text = adr
//                            }
                        }
                    }
                    completionHandler(true)
                }
            }
        } catch let error {
            print("got an error creating the request: \(error)")
        }
    }
    
    func getUserInfoPrequel( completionHandler: @escaping (_ _state: Bool) -> ()) {
        let urlString = "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2017/prequal-tenants/\(mobile_number)"
        //        let parameters = [:]
        
        do {
            let opt = try HTTP.GET(urlString, parameters: nil, headers: nil, requestSerializer: JSONParameterSerializer())
            opt.start { response in
                if response.error != nil {
                    completionHandler(false)
                }else {
                    let data = response.text?.data(using: .utf8)!
                    if let parsedData = try? JSONSerialization.jsonObject(with: data!) as? [String:Any] {
                        if let apartments = parsedData?["apartments"] as? [[String:Any]] {
                            //                            if let apt = apartments[0]["apt"] as? String {
                            //                                let adr = apt + String(describing: apartments[1]["street"])
                            //                                self.roomInfoLabel.text = adr
                            //                            }
                        }
                    }
                    completionHandler(true)
                }
            }
        } catch let error {
            print("got an error creating the request: \(error)")
        }
    }

    @IBAction func roomBtnPressed(_ sender: AnyObject) {
        let CallVC = self.storyboard?.instantiateViewController(withIdentifier: "callConnectVC") as! CallConnectViewController
        self.navigationController?.pushViewController(CallVC, animated: true)
    }
    @IBAction func roomInfoBtnPressed(_ sender: AnyObject) {
        let userInfoDialog = self.storyboard?.instantiateViewController(withIdentifier: "preCallVC") as! PreCallViewController
        userInfoDialog.view.layer.cornerRadius = 10.0
        userInfoDialog.view.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
        let dialogPosition : CGPoint = CGPoint(x: self.view.center.x, y: self.view.center.y)
        userInfoDialog.view.center = dialogPosition
        self.addChildViewController(userInfoDialog)
        self.view.insertSubview(userInfoDialog.view, aboveSubview: self.view)
        userInfoDialog.didMove(toParentViewController: self)
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
