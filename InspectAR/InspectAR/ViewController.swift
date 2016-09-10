
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
    
    var taskArray: [String] = ["Task 0", "Task 1", "Task 2", "Task 3", "task 4", "Task 5", "Task 6"]
    
    let screenSize: CGRect = UIScreen.mainScreen().bounds

    var captureSession: AVCaptureSession?
    var stillImageOutput: AVCaptureStillImageOutput?
    var previewLayer: AVCaptureVideoPreviewLayer? // Master layer where all the other stuff is layed on top of yerexcept this is on replcator layer
    
    // whose idea was this
    // some autist probably
    
    
    let replicatorLayer = CAReplicatorLayer()

    // normal mode views
    let mainPriority: CATextLayer =  CATextLayer(); // at the top of the screen in normal mode
    let additionalTasks: CATextLayer = CATextLayer(); // all the other crap
    
    // overview mode views - one in middle, big; 2 on left/right, waiting to be scrolled to
    let overviewCenter: CATextLayer = CATextLayer();
    let overviewIndex: CATextLayer = CATextLayer()
    
    var mainMode: Bool = true;
    
    // soquet
    let socket = SocketIOClient(socketURL: NSURL(string: "http://05751d3d.ngrok.io")!)
    
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
                
                
                // setup the views
                
                // @TODO get data from server to populate this
                // @TODO swipe up with pebble to change views
                
                mainPriority.fontSize = 20
                mainPriority.frame = CGRectMake(5, 5, 311, 311)
                mainPriority.alignmentMode = kCAAlignmentCenter
                mainPriority.string = "Main task goes here!"
                mainPriority.foregroundColor = UIColor.whiteColor().CGColor
                
                additionalTasks.fontSize = 20
                additionalTasks.frame = CGRectMake(5, 300, 311, 311)
                additionalTasks.alignmentMode = kCAAlignmentCenter
                additionalTasks.string = "\(taskArray.count) tasks today"
                
                overviewCenter.fontSize = 20
                overviewCenter.frame = CGRectMake(5, 30, 250, 250)
                overviewCenter.alignmentMode = kCAAlignmentCenter
                overviewCenter.string = "Thorough information"
                
                
                overviewIndex.fontSize = 15
                overviewIndex.frame = CGRectMake(5, 10, 311, 311)
                overviewIndex.alignmentMode = kCAAlignmentCenter
                overviewIndex.string = "1"
                
                
                ////////////////////////////////////////////////////////
                

                // start off in main mode
                previewLayer?.addSublayer(mainPriority)
                previewLayer!.addSublayer(additionalTasks)
                
                
                replicatorLayer.addSublayer(previewLayer!)
                
                self.view.layer.addSublayer(replicatorLayer)
                captureSession?.startRunning()
            }
        }
    }
    
    
    // switches modes based on swipe with pebble
    func switchModes(overviewMode: Bool) {
        
//        scrollInOverviewMode(3)
        
        if (overviewMode) {
            // get rid of the current mode's views and put in the other ones
            mainPriority.removeFromSuperlayer()
            additionalTasks.removeFromSuperlayer()
        
            previewLayer?.addSublayer(overviewCenter)
            previewLayer?.addSublayer(overviewIndex)
        }
        else {
            overviewCenter.removeFromSuperlayer()
            overviewIndex.removeFromSuperlayer()
            
            previewLayer?.addSublayer(mainPriority)
            previewLayer?.addSublayer(additionalTasks)
        }
        
        mainMode = !mainMode
            
    }
    
    func scrollInOverviewMode(index: Int) {
        
        overviewCenter.string = taskArray[index]
        overviewIndex.string = "\(index)"
        
    }

    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            print("you touched me")
            switchModes(mainMode);
//            capturePicture()
        }
        super.touchesBegan(touches, withEvent:event)
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
    } // end of capturePicture
    
    

    
}