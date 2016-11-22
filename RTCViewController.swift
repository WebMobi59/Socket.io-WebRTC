//
//  RTCViewController.swift
//  
//
//
//

import UIKit
import AVFoundation
import SwiftHTTP

let TAG = "RTCViewController"
let VIDEO_TRACK_ID = TAG + "VIDEO"
let AUDIO_TRACK_ID = TAG + "AUDIO"
let LOCAL_MEDIA_STREAM_ID = TAG + "STREAM"

class RTCViewController: UIViewController, RTCSessionDescriptionDelegate, RTCPeerConnectionDelegate, RTCEAGLVideoViewDelegate{

    
    var mediaStream: RTCMediaStream!
    var localVideoTrack: RTCVideoTrack!
    var localAudioTrack: RTCAudioTrack!
    var remoteVideoTrack: RTCVideoTrack!
    var remoteAudioTrack: RTCAudioTrack!
    var renderer: RTCEAGLVideoView!
    var renderer_sub: RTCEAGLVideoView!
    var roomName: String!
    
    func Log(_ value:String) {
        print(TAG + " " + value)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initWebRTC()
        sigConnect(SocketIOManager.sharedInstance.socket.socketURL.absoluteString)
        renderer = RTCEAGLVideoView(frame: self.view.frame)
        renderer_sub = RTCEAGLVideoView(frame: self.view.frame)
        self.view.addSubview(renderer)
        self.view.addSubview(renderer_sub)
        renderer.delegate = self
        
        var device: AVCaptureDevice! = nil
        for captureDevice in AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo) {
            if ((captureDevice as AnyObject).position == AVCaptureDevicePosition.front) {
                device = captureDevice as! AVCaptureDevice
            }
        }
        if (device != nil) {
            let capturer = RTCVideoCapturer(deviceName: device.localizedName)
            let videoConstraints = RTCMediaConstraints()
            let videoSource = peerConnectionFactory.videoSource(with: capturer, constraints: videoConstraints)
            
            localVideoTrack = peerConnectionFactory.videoTrack(withID: VIDEO_TRACK_ID, source: videoSource)
            localAudioTrack = peerConnectionFactory.audioTrack(withID: AUDIO_TRACK_ID)
            
            mediaStream = peerConnectionFactory.mediaStream(withLabel: LOCAL_MEDIA_STREAM_ID)
            
            mediaStream.addVideoTrack(localVideoTrack)
            mediaStream.addAudioTrack(localAudioTrack)
            
            localVideoTrack.add(renderer_sub)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
        
    override func viewDidDisappear(_ animated: Bool) {
        RTCPeerConnectionFactory.deinitializeSSL()
    }
    
    func videoView(_ videoView: RTCEAGLVideoView!, didChangeVideoSize size: CGSize) {
        let w = renderer.bounds.height * size.width / size.height
        let h = renderer.bounds.height
        let x = (w - renderer.bounds.width) / 2
        renderer.frame = CGRect(x: -x, y: 0, width: w, height: h)
    }
    
    func showRoomDialog() {
        sigRecoonect()
    }
    
    func getRoomName() -> String {
        return (roomName == nil || roomName.isEmpty) ? "1111": roomName
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
        let url1:URL = URL(string: "stun:23.21.150.121")!
        let url2:URL = URL(string: "stun:stun.l.google.com:19302")!
        let icsServers: [RTCICEServer] = [
            RTCICEServer(uri: url1, username: "", password: ""),
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
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!) {
        if (candidate != nil) {
            Log("iceCandidate: " + candidate.description)
            let json:[String: AnyObject] = [
                "type" : "candidate" as AnyObject,
                "sdpMLineIndex" : candidate.sdpMLineIndex as AnyObject,
                "sdpMid" : candidate.sdpMid as AnyObject,
                "candidate" : candidate.sdp as AnyObject
            ]
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
            remoteVideoTrack.add(renderer)
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
        
        let opts:[String: AnyObject] = [
            "log"  : true as AnyObject
        ]
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
                print(sdp)
                self.onAnswer(sdp!)
            } else if (type == "candidate" && self.peerStarted) {
                self.Log("Received ICE candidate...")
                let candidate = RTCICECandidate(
                    mid: json["sdpMid"] as! String,
                    index: json["sdpMLineIndex"] as! Int,
                    sdp: json["candidate"] as! String)
                self.onCandidate(candidate!)
            } else if ((type == "user disconnected" || type == "remote left") && self.peerStarted) {
                self.Log("disconnected")
                self.stop()
            }  else if (type == "joined session") {
                self.sendOffer()
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

    

}
