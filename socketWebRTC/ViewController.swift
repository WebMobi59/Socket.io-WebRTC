//
//  ViewController.swift
//  socketWebRTC
//
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var connectionStatusLabel: UILabel!
    
    let uuid = UUID().uuidString
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectionStatusLabel.text = "This is test."
        print("Socket Status === \(SocketIOManager.sharedInstance.socket.status)")
    
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func conectionManualy(_ sender: AnyObject) {
        
        SocketIOManager.sharedInstance.establishConnection()
        SocketIOManager.sharedInstance.connectToServerWithNickname(uuid) {
                print("initializing connection...")
        }
        SocketIOManager.sharedInstance.socket.on("log") { (dataArray, ask) in
            self.connectionStatusLabel.text = (dataArray[0] as AnyObject).description
        }
        print("Manual Socket Status === \(SocketIOManager.sharedInstance.socket.status)")
    }
    
    @IBAction func message(_ sender: AnyObject) {
        
        SocketIOManager.sharedInstance.sendMessage(["method" : "createOrJoin", "sessionId": "123"])
        print("Message Socket Status === \(SocketIOManager.sharedInstance.socket.status)")
    }
    
    
}

