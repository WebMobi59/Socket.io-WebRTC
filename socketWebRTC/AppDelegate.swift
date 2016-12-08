//
//  AppDelegate.swift
//  socketWebRTC
//
//

/*
 {"aps": {"alerts" : "test",
 "sound": " "},
 "message": "call",
 "param": "http://[socketIOServer]/UUID"
 }
 */

import UIKit
import SwiftHTTP
import IQKeyboardManagerSwift
import UserNotifications
import SwiftMessageBar

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, UITextFieldDelegate {

    var window: UIWindow?
    var g_deviceToken: String?
    private var uuid : UUID?
    var roomId : String?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // register push notificatio
        registerPushNotifications()
        
        UserDefaults.standard.setValue(false, forKey: "fromAPNS")
        UserDefaults.standard.synchronize()
        
        // parsing notification data
        if let launchOptions = launchOptions {
            if let userInfo = launchOptions[UIApplicationLaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] {
               self.application(application, didReceiveRemoteNotification: userInfo)
            } else {
                
            }
        } else {
            DispatchQueue.main.async {
                self.window = UIWindow(frame: UIScreen.main.bounds)
                let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
                var initialViewController: UIViewController
                if((UserDefaults.standard.value(forKey: "deviceToken")) != nil) //your condition if user is already logged in or not
                {
                    // if already logged in then redirect to RoomViewController
                    initialViewController = mainStoryboard.instantiateViewController(withIdentifier: "roomNavVC") as! UINavigationController // 'RoomViewController' is the storyboard id of RoomViewController
                } else {
                    //If not logged in then show RegisterViewController
                    initialViewController = mainStoryboard.instantiateViewController(withIdentifier: "navRootVC") as! UINavigationController // 'RegisterViewController' is the storyboard id of RegisterViewController
                }
                
                self.window?.rootViewController = initialViewController
                self.window?.makeKeyAndVisible()
            }
        }
        IQKeyboardManager.sharedManager().enable = true
        
        return true
    }
    
    //Me
    func application(_ application: UIApplication, didRegister notificationSettings: UIUserNotificationSettings) {
        if notificationSettings.types != UIUserNotificationType() {
            application.registerForRemoteNotifications()
        }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Registration failed!")
    }
    //

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        
        var token: String = ""
        for i in 0..<deviceToken.count {
            token += String(format: "%02.2hhx", deviceToken[i] as CVarArg)
        }
        
        g_deviceToken = token
    }
    
    func applicationWillResignActive(_ application: UIApplication) {

    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        let socket = SocketIOManager.sharedInstance.socket
        let aps = userInfo["aps"] as? [AnyHashable: Any]
        _ = userInfo["message"] as? String
        _ = userInfo["param"] as? String
        let alert_message = aps!["alert"] as? String
        
        if let rtcConnectionKey = userInfo["rtcConnectionKey"] as? String {
            if UIApplication.shared.applicationState == UIApplicationState.active {
                uuid = SwiftMessageBar.showMessageWithTitle("Incoming Call", message: alert_message, type: .success, duration: 3, dismiss: false, callback: {
                    print(rtcConnectionKey)
                    self.roomId = rtcConnectionKey
                    UserDefaults.standard.setValue(true, forKey: "fromAPNS")
                    UserDefaults.standard.synchronize()
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "roomNavVC") as! UINavigationController
                    self.window?.rootViewController = vc
                    
                    let roomVC = storyboard.instantiateViewController(withIdentifier: "callConnectVC")
                    vc.pushViewController(roomVC, animated: true)
                })
            } else {
                print(rtcConnectionKey)
                self.roomId = rtcConnectionKey
                UserDefaults.standard.setValue(true, forKey: "fromAPNS")
                UserDefaults.standard.synchronize()
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let vc = storyboard.instantiateViewController(withIdentifier: "roomNavVC") as! UINavigationController
                self.window?.rootViewController = vc
                
                let roomVC = storyboard.instantiateViewController(withIdentifier: "callConnectVC")
                vc.pushViewController(roomVC, animated: true)
            }
        } else {
            uuid = SwiftMessageBar.showMessageWithTitle(nil, message: alert_message, type: .success, duration: 3, dismiss: false, callback: {
                print("Got APNS")
            })
        }
        
        if (socket.status == .notConnected || socket.status == .disconnected ){
            
        }else{
            
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // init application badge number
        application.applicationIconBadgeNumber = 0;
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //Me
    func registerPushNotifications() {
        DispatchQueue.main.async {
            let settings = UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
        }
    }
    //
    
}

