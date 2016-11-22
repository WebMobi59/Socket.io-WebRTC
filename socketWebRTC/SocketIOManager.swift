//
//  SocketIOManager .swift
//  socketWebRTC
//
//

import UIKit
//import SocketIOClientSwift
import SocketIO

class SocketIOManager: NSObject {
    static let sharedInstance = SocketIOManager()
    
    var socket = SocketIOClient(socketURL: URL(string: "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2016")!)
    
    override init() {
        super.init()
    }
    
    
    func initSocket(_ uuid: String) -> SocketIOClient{
        return SocketIOClient(socketURL: URL(string: "http://ec2-52-24-49-20.us-west-2.compute.amazonaws.com:2016/\(uuid)")!)
    }
    
    func establishConnection() {
        socket.connect(timeoutAfter: 30) { 
            print("Time out reached")
        }
        
    }
    
    func closeConnection() {
        socket.disconnect()
    }
    
    func connectToServerWithNickname(_ identifier: String, completionHandler: () -> Void) {
        socket.emit("connectUser", identifier)
        completionHandler()
    }
    
    func exitChatWithNickname(_ identifier: String, completionHandler: () -> Void) {
        socket.emit("disconnected", identifier)
        completionHandler()
    }
    
    func sendMessage(_ message: NSDictionary) {
        socket.emit("message", message)
        socket.on("message") { (data, connection) in

        }
    }


    
    
}

