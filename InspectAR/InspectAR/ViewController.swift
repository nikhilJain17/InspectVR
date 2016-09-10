
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
    
    let screenSize: CGRect = UIScreen.mainScreen().bounds

    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer? // Master layer where all the other stuff is layed on top of yerexcept this is on replcator layer
    
    // whose idea was this
    // some autist probably
    
    
    let replicatorLayer = CAReplicatorLayer()

    
    
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
        var output: AVCaptureStillImageOutput?
        
        if captureSession?.canAddInput(input) != nil {
            captureSession?.addInput(input)
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            
            output = AVCaptureStillImageOutput()
            
            if (captureSession?.canAddOutput(output) != nil) {
            
                captureSession?.addOutput(stillImageOutput)
//                captureSession?.addOutput(output)
            
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewLayer?.frame = CGRect(x: 0, y: 0, width: 300, height:  self.view.bounds.size.height - 70)
                //previewLayer?.frame = CGRect(self.view.bounds)
                
                replicatorLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)
                //                replicatorLayer.frame = CGRectMake(13, 30, 360, self.view.bounds.size.height - 70)
                replicatorLayer.instanceCount = 2
                
                replicatorLayer.instanceTransform = CATransform3DMakeTranslation(self.view.bounds.size.width / 2 + 120, 0.0, 0.0)
                
                
                previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
                
                
                // setup the layer
                
                
                replicatorLayer.addSublayer(previewLayer!)
                
                self.view.layer.addSublayer(replicatorLayer)
                captureSession?.startRunning()
            }
        }
    }
    

    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            print("you touched me")
            capturePicture()
        }
        super.touchesBegan(touches, withEvent:event)
    }

    // begin
    
    
    
    // try take pic
    func screenShotMethod() {
        
        print("you screenshotted me")
        
        UIGraphicsBeginImageContextWithOptions(UIScreen.mainScreen().bounds.size, false, 0);
        self.view.drawViewHierarchyInRect(view.bounds, afterScreenUpdates: true)
        let image:UIImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
//        self.imgView.image = image;
        // save to camera roll
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

    }
   
    
    // take the picture
    func capturePicture(){
        
        print("Capturing image")
//        stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
//        captureSession?.addOutput(stillImageOutput)
        
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo){
            stillImageOutput!.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {
                (sampleBuffer, error) in
                let imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                let dataProvider = CGDataProviderCreateWithCFData(imageData)
                let cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, CGColorRenderingIntent.RenderingIntentDefault)
                let image = UIImage(CGImage: cgImageRef!, scale: 1.0, orientation: UIImageOrientation.Down)
                
                let imageView = UIImageView(image: image)
                imageView.frame = CGRect(x:0, y:0, width:self.screenSize.width, height:self.screenSize.height)
                
                //Show the captured image to
                self.view.addSubview(imageView)
                
                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

                
                // remove after 2 seconds
                let time = dispatch_time(dispatch_time_t(DISPATCH_TIME_NOW), 2 * Int64(NSEC_PER_SEC))
                    dispatch_after(time, dispatch_get_main_queue()) {
                    imageView.removeFromSuperview()
                }

                
                
            })
        }
    }
    
    func takePhoto(){
        
        
        if let stillOutput = self.stillImageOutput {
            // we do this on another thread so that we don't hang the UI
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                //find the video connection
                var videoConnection : AVCaptureConnection?
                for connecton in stillOutput.connections {
                    //find a matching input port
                    for port in connecton.inputPorts!{
                        if port.mediaType == AVMediaTypeVideo {
                            videoConnection = connecton as? AVCaptureConnection
                            break //for port
                        }
                    }
                    
                    if videoConnection  != nil {
                        break// for connections
                    }
                }
                if videoConnection  != nil {
                    stillOutput.captureStillImageAsynchronouslyFromConnection(videoConnection){
                        (imageSampleBuffer : CMSampleBuffer!, _) in
                        
                        let imageDataJpeg = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(imageSampleBuffer)
                        var pickedImage: UIImage = UIImage(data: imageDataJpeg)!
                        
                        
                        UIImageWriteToSavedPhotosAlbum(pickedImage, nil, nil, nil)

                    }
                    self.captureSession!.stopRunning()
                    
                    
                    
                }
            }
        }
        
    }

    
}