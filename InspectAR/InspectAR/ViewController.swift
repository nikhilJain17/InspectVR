
//
//  ViewController.swift
//
//

import UIKit
import AVFoundation
import HealthKit
import Foundation
import CoreLocation
import MediaPlayer
import WatchConnectivity

extension Double {
    func format(f: String) -> String {
        return String(format: "%\(f)f", self)
    }
}

class ViewController: UIViewController, WCSessionDelegate, UINavigationControllerDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, CLLocationManagerDelegate {
    
    
    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer? // Master layer where all the other stuff is layed on top of yerexcept this is on replcator layer
    
    // whose idea was this
    // some autist probably
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    // when the view loads
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = AVCaptureSessionPreset1920x1080
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let input = try! AVCaptureDeviceInput(device: backCamera)
        
        //var input = AVCaptureDeviceInput(device: backCamera, error: &error)
        var output: AVCaptureVideoDataOutput?
        
        if captureSession?.canAddInput(input) != nil {
            captureSession?.addInput(input)
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            
            output = AVCaptureVideoDataOutput()
            
            if (captureSession?.canAddOutput(output) != nil) {
                
                //captureSession?.addOutput(stillImageOutput)
                captureSession?.addOutput(output)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewLayer?.frame = CGRect(x: 0, y: 0, width: 300, height:  self.view.bounds.size.height - 70)
                //previewLayer?.frame = CGRect(self.view.bounds)
                
                let replicatorLayer = CAReplicatorLayer()
                replicatorLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)
//                replicatorLayer.frame = CGRectMake(13, 30, 360, self.view.bounds.size.height - 70)
                replicatorLayer.instanceCount = 2
                
                replicatorLayer.instanceTransform = CATransform3DMakeTranslation(self.view.bounds.size.width / 2 + 120, 0.0, 0.0)
                
                
                previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
            
                
                // setup the layer
                
                
                replicatorLayer.addSublayer(previewLayer!)
                
                self.view.layer.addSublayer(replicatorLayer)
                captureSession?.startRunning()
            }
        }
    }
    
}