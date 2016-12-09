//
//  CallConnectViewController.swift
//  socketWebRTC
//

import UIKit
import AVFoundation
import SwiftHTTP

let TAG = "CallConnectViewController"
let VIDEO_TRACK_ID = TAG + "VIDEO"
let AUDIO_TRACK_ID = TAG + "AUDIO"
let LOCAL_MEDIA_STREAM_ID = TAG + "STREAM"

class CallConnectViewController: UIViewController, RTCSessionDescriptionDelegate, RTCPeerConnectionDelegate, RTCEAGLVideoViewDelegate {

    @IBOutlet weak var remoteview_mask: UIView!
    @IBOutlet weak var openBtn: UIButton!
    @IBOutlet weak var dropBtn: UIButton!
    @IBOutlet weak var muteBtn: UIButton!
    @IBOutlet weak var remoteUserView: RTCEAGLVideoView!
    
    var mediaStream: RTCMediaStream!
    var localVideoTrack: RTCVideoTrack!
    var localAudioTrack: RTCAudioTrack!
    var remoteVideoTrack: RTCVideoTrack!
    var remoteAudioTrack: RTCAudioTrack!
    var roomName: String!
    var isMute : Bool = false
    
    func Log(_ value:String) {
        print(TAG + " " + value)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(forName:NSNotification.Name.AVAudioSessionRouteChange , object:nil, queue:nil, using:catchNotification)

        self.initComponents();
        
        self.initWebRTC()
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            roomName = delegate.roomId //Set the SessionID(roomID)
        }

        remoteUserView.delegate = self
        localAudioTrack = peerConnectionFactory.audioTrack(withID: AUDIO_TRACK_ID)
        mediaStream = peerConnectionFactory.mediaStream(withLabel: LOCAL_MEDIA_STREAM_ID)
        mediaStream.addAudioTrack(localAudioTrack)
        
        let isfromAPNS = UserDefaults.standard.value(forKey: "fromAPNS") as! Bool
        if isfromAPNS {
            self.sigConnect(SocketIOManager.sharedInstance.socket.socketURL.absoluteString)
            UserDefaults.standard.setValue(false, forKey: "fromAPNS")
            UserDefaults.standard.synchronize()
        }
        
        // Do any additional setup after loading the view.
    }
    
    func catchNotification(notification:Notification) -> Void {
        let interuptionDict = notification.userInfo
        if let interuptionRouteChangeReason = interuptionDict?[AVAudioSessionRouteChangeReasonKey] {
            let routeChangeReason = interuptionRouteChangeReason as! UInt
            switch (routeChangeReason) {
            case AVAudioSessionRouteChangeReason.categoryChange.rawValue:
                do {
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(AVAudioSessionPortOverride.speaker)
                } catch {
                    
                }
            default:
                break;
            }
        }
    }
    
    func initComponents() {
        remoteview_mask.layoutIfNeeded()
        remoteview_mask.setNeedsLayout()
        remoteview_mask.layer.cornerRadius = remoteview_mask.frame.size.width/2
        remoteview_mask.addSubview(remoteUserView)
        remoteview_mask.clipsToBounds  = true
        
        openBtn.layoutIfNeeded()
        openBtn.setNeedsLayout()
        openBtn.layer.cornerRadius = openBtn.frame.size.width/2
        openBtn.clipsToBounds  = true
        
        dropBtn.layoutIfNeeded()
        dropBtn.setNeedsLayout()
        dropBtn.layer.cornerRadius = dropBtn.frame.size.width/2
        dropBtn.clipsToBounds  = true
        
        muteBtn.layoutIfNeeded()
        muteBtn.setNeedsLayout()
        muteBtn.layer.cornerRadius = muteBtn.frame.size.width/2
        muteBtn.clipsToBounds  = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        RTCPeerConnectionFactory.deinitializeSSL()
        UserDefaults.standard.setValue(false, forKey: "fromAPNS")
        UserDefaults.standard.synchronize()
    }
    
    func videoView(_ videoView: RTCEAGLVideoView!, didChangeVideoSize size: CGSize) {

    }
    
    func showRoomDialog() {
        sigRecoonect()
    }
    
    func getRoomName() -> String {
        return (roomName == nil || roomName.isEmpty) ? "1111": "1111"
    }
    
    var peerConnectionFactory: RTCPeerConnectionFactory! = nil
    var peerConnection: RTCPeerConnection! = nil
    var pcConstraints: RTCMediaConstraints! = nil
    var videoConstraints: RTCMediaConstraints! = nil
    var audioConstraints: RTCMediaConstraints! = nil
    var mediaConstraints: RTCMediaConstraints! = nil
    
    var socket = SocketIOManager.sharedInstance.socket
    var wsServerUrl: String! = nil
    var peerStarted: Bool = false
    
    func initWebRTC() {
        RTCPeerConnectionFactory.initializeSSL()
        peerConnectionFactory = RTCPeerConnectionFactory()
        
        pcConstraints = RTCMediaConstraints()
        videoConstraints = RTCMediaConstraints()
        audioConstraints = RTCMediaConstraints()
        mediaConstraints = RTCMediaConstraints(
            mandatoryConstraints: [
                RTCPair(key: "OfferToReceiveAudio", value: "true"),
                RTCPair(key: "OfferToReceiveVideo", value: "true")
            ],
            optionalConstraints: nil)
    }
    
    func connect() {
        if (!peerStarted) {
            sendOffer()
            peerStarted = true
        }
    }
    
    func hangUp() {
        sendDisconnect()
        stop()
    }
    
    func stop() {
        if (peerConnection != nil) {
            peerConnection.close()
            peerConnection = nil
            peerStarted = false
        }
    }
    
    func prepareNewConnection() -> RTCPeerConnection {
//        let url1:URL = URL(string: "stun:23.21.150.121")!
        let url2:URL = URL(string: "stun:stun.l.google.com:19302")!
        let icsServers: [RTCICEServer] = [
//            RTCICEServer(uri: url1, username: "", password: ""),
            RTCICEServer(uri: url2, username: "", password: "")]
        let rtcConfig: RTCConfiguration = RTCConfiguration()
        rtcConfig.tcpCandidatePolicy = RTCTcpCandidatePolicy.disabled
        rtcConfig.bundlePolicy = RTCBundlePolicy.maxBundle
        rtcConfig.rtcpMuxPolicy = RTCRtcpMuxPolicy.require
        
        peerConnection = peerConnectionFactory.peerConnection(withICEServers: icsServers, constraints: pcConstraints, delegate: self)
        peerConnection.add(mediaStream)
        return peerConnection
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState) {
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState) {
        var stateString: String = ""
        switch newState {
        case RTCICEConnectionNew:
            stateString = "RTCICEConnectionNew"
        case RTCICEConnectionChecking:
            stateString = "RTCICEConnectionChecking"
        case RTCICEConnectionConnected:
            stateString = "RTCICEConnectionConnected"
        case RTCICEConnectionCompleted:
            stateString = "RTCICEConnectionCompleted"
        case RTCICEConnectionFailed:
            stateString = "RTCICEConnectionFailed"
        case RTCICEConnectionDisconnected:
            stateString = "RTCICEConnectionDisconnected"
        case RTCICEConnectionClosed:
            stateString = "RTCICEConnectionClosed"
        default:
            stateString = "Unknown"
        }
        Log("ICE connection : \(stateString)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!) {
        if (candidate != nil) {
            Log("iceCandidate: " + candidate.description)
            let json:[String: AnyObject] = [
                "type" : "candidate" as AnyObject,
                "candidate" : [
                    "sdpMLineIndex" : candidate.sdpMLineIndex as AnyObject,
                    "sdpMid" : candidate.sdpMid as AnyObject,
                    "candidate" : candidate.sdp as AnyObject
                ] as AnyObject
            ]
            Log("Sending ICE candidate...")
            Log("\(json)")
            sigSend(json as NSDictionary)
        } else {
            Log("End of candidates. -------------------")
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
        if (peerConnection == nil) {
            return
        }
        if (stream.audioTracks.count > 1 || stream.videoTracks.count > 1) {
            Log("Weird-looking stream: " + stream.description)
            return
        }
        if (stream.videoTracks.count == 1) {
            remoteVideoTrack = stream.videoTracks[0] as! RTCVideoTrack
            remoteVideoTrack.setEnabled(true)
            remoteVideoTrack.add(remoteUserView)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
        remoteVideoTrack = nil
        //        stream.videoTracks[0].dispose()
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, didOpen dataChannel: RTCDataChannel!) {
    }
    
    func peerConnection(onRenegotiationNeeded peerConnection: RTCPeerConnection!) {
    }
    
    func onOffer(_ sdp:RTCSessionDescription) {
        setOffer(sdp)
        sendAnswer()
        peerStarted = true
    }
    
    func onAnswer(_ sdp:RTCSessionDescription) {
        setAnswer(sdp)
    }
    
    func onCandidate(_ candidate:RTCICECandidate) {
        peerConnection.add(candidate)
    }
    
    func sendSDP(_ sdp:RTCSessionDescription) {
        let json:[String: AnyObject] = [
            "type" : sdp.type as AnyObject,
            "sdp"  : sdp.description as AnyObject
        ]
        print(json)
        sigSend(json as NSDictionary)
    }
    
    func sendOffer() {
        peerConnection = prepareNewConnection()
        peerConnection.createOffer(with: self, constraints: mediaConstraints)
    }
    
    func setOffer(_ sdp:RTCSessionDescription) {
        if (peerConnection != nil) {
            Log("peer connection already exists")
        }
        peerConnection = prepareNewConnection()
        peerConnection.setRemoteDescriptionWith(self, sessionDescription: sdp)
    }
    
    func sendAnswer() {
        Log("sending Answer. Creating remote session description...")
        if (peerConnection == nil) {
            Log("peerConnection NOT exist!")
            return
        }
        peerConnection.createAnswer(with: self, constraints: mediaConstraints)
    }
    
    func setAnswer(_ sdp:RTCSessionDescription) {
        if (peerConnection == nil) {
            Log("peerConnection NOT exist!")
            return
        }
        peerConnection.setRemoteDescriptionWith(self, sessionDescription: sdp)
    }
    
    func sendDisconnect() {
        let json:[String: AnyObject] = [
            "type" : "user disconnected" as AnyObject
        ]
        sigSend(json as NSDictionary)
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: Error!) {
        if (error == nil) {
            peerConnection.setLocalDescriptionWith(self, sessionDescription: sdp)
            sendSDP(sdp)
        } else {
            Log("sdp creation error: " + error.localizedDescription)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: Error!) {
    }
    
    func sigConnect(_ wsUrl:String) {
        wsServerUrl = wsUrl
//        socket.connect()
//        let opts:[String: AnyObject] = [
//            "log"  : true as AnyObject
//        ]
        Log("connecting to " + wsServerUrl)
        
        socket.on("connect") { data in
            self.Log("WebSocket connection opened to: " + self.wsServerUrl)
            self.sigEnter()
        }
        
        socket.on("disconnect") { data in
            self.Log("WebSocket connection closed.")
        }
        
        socket.on("message") { (data, emitter) in
            if (data.count == 0) {
                return
            }
            
            let json = data[0] as! NSDictionary
            self.Log("WebServiceResponse->C: " + json.description)
            
            var type = ""
            
            if let event = json["event"] as? String {
                type = event
            }
            
            if let typeString = json["type"] as? String {
                type = typeString
            }
            
            print("Printing log")
            print(type)
            if (type == "offer") {
                self.Log("Received offer, set offer, sending answer....")
                let sdp = RTCSessionDescription(type: type, sdp: json["sdp"] as! String)
                self.onOffer(sdp!)
            } else if (type == "answer" && self.peerStarted) {
                self.Log("Received answer, setting answer SDP")
                let sdp = RTCSessionDescription(type: type, sdp: json["sdp"] as! String)
                self.onAnswer(sdp!)
            } else if (type == "answer") {
                self.Log("Received answer, setting answer SDP")
                let sdp = RTCSessionDescription(type: type, sdp: json["sdp"] as! String)
                print(sdp!)
                self.onAnswer(sdp!)
            } else if (type == "candidate" && self.peerStarted) {
                self.Log("Received ICE candidate...")
                let remotecandidate: NSDictionary = json["candidate"] as! NSDictionary
                let candidate = RTCICECandidate(
                    mid: remotecandidate["sdpMid"] as! String,
                    index: remotecandidate["sdpMLineIndex"] as! Int,
                    sdp: remotecandidate["candidate"] as! String)
                self.onCandidate(candidate!)
            } else if ((type == "user disconnected" || type == "remote left") && self.peerStarted) {
                self.Log("disconnected")
                self.stop()
            }  else if (type == "joined session") {
                self.sendOffer()
                self.peerStarted = true
            } else {
                self.Log("Unexpected WebSocket message: " + (data[0] as AnyObject).description)
            }
        }
        socket.connect()
    }
    
    func sigRecoonect() {
        socket.disconnect()
        socket.connect()
    }
    
    func sigEnter() {
        let roomName = getRoomName()
        self.Log("Entering room: " + roomName)
        SocketIOManager.sharedInstance.sendMessage(["method" : "createOrJoin", "sessionId": roomName])
        
    }
    
    func sigSend(_ msg:NSDictionary) {
        socket.emit("message", msg)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func openBtnPressed(_ sender: AnyObject) {
        if !peerStarted {
            self.sigConnect(SocketIOManager.sharedInstance.socket.socketURL.absoluteString)
        }
    }

    @IBAction func dropBtnPressed(_ sender: AnyObject) {
        self.hangUp()
        DispatchQueue.main.async {
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func muteBtnPressed(_ sender: AnyObject) {
        if !isMute { // if Current state is mute, turn off the mute
            if peerStarted {
                self.localAudioTrack.setEnabled(false)
                isMute = true
                self.muteBtn.setImage(UIImage(named: "call_mute.png"), for: .normal)
            }
        } else { //Otherwise
            if peerStarted {
                localAudioTrack.setEnabled(true)
                self.muteBtn.setImage(UIImage(named: "un_mute.png"), for: .normal)
                isMute = false
            }
        }
    }
}
