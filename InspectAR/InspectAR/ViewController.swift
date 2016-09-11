
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
    
    var taskArray: [String] = []
    var timeArray: [String] = []
    
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
    var currentIndex = 0;
    
    // soquet
    let socket = SocketIOClient(socketURL: NSURL(string: "http://05751d3d.ngrok.io")!)
    
    // http://eac5581f.ngrok.io
    // http://05751d3d.ngrok.io
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        socket.connect()
        
        socket.on("connect") { data, ack in
            
            self.socket.emit("want tasks")
            self.socket.emit("want leaderboard")
            
        }
        
        socket.on("got tasks") { data, ack in
            
            print("got tasks")
            
            self.taskArray = data[0] as! [String]
            self.timeArray = data[1] as! [String]
            
            print(self.taskArray)
            print(self.timeArray)
            
            self.mainPriority.string = "\(self.taskArray[0])"
            self.additionalTasks.string = "\(self.taskArray.count) tasks today"

            
        }
        
        socket.on("up") { data, ack in
            
            print("up")
            // switch modes
            self.switchModes(self.mainMode)
            
        }
        
        socket.on("right") { data, ack in
            
            
            print("right")
            // swipe right boi
            let a:Int = (self.overviewIndex.string?.integerValue)! - 1
            
            print(a)
            
            if (a+1 < self.taskArray.count) {
                self.currentIndex = a+1
                self.scrollInOverviewMode()
            }
            else {
//                self.currentIndex = 0
//                self.scrollInOverviewMode()
            }
            
        }
        
        socket.on("left") { data, ack in
            
            print("left")
            // swipe right boi
            let a:Int = (self.overviewIndex.string?.integerValue)! - 1
            
            print(a)
            
            if (a-1 > -1) {
                self.currentIndex = a-1
                self.scrollInOverviewMode()
            }
            else {
//                self.currentIndex = self.taskArray.count - 1
//                self.scrollInOverviewMode()
            }
            
        }
        
        socket.on("leaderboard") { data, ack in
            
            print(data[0])
            print(data[1])
            
        }
        
        socket.on("ontext") { data, ack in
            self.taskArray.append(data[0] as! String)
//            self.append
            
        }
        
        
    }
    
    
    // when the view loads
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        
        print("view did lod")
        
        
        self.captureSession = AVCaptureSession()
        self.captureSession?.sessionPreset = AVCaptureSessionPreset1920x1080
        
        let backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        let input = try! AVCaptureDeviceInput(device: backCamera)
        
        //var input = AVCaptureDeviceInput(device: backCamera, error: &error)
        var output: AVCaptureStillImageOutput?
        
        if self.captureSession?.canAddInput(input) != nil {
            self.captureSession?.addInput(input)
            
            self.stillImageOutput = AVCaptureStillImageOutput()
            self.stillImageOutput?.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            
            output = AVCaptureStillImageOutput()
            
            if (self.captureSession?.canAddOutput(output) != nil) {
            
                self.captureSession?.addOutput(self.stillImageOutput)
//                captureSession?.addOutput(output)
            
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                self.previewLayer?.frame = CGRect(x: 0, y: 0, width: 300, height:  self.view.bounds.size.height - 70)
                //previewLayer?.frame = CGRect(self.view.bounds)
                
                self.replicatorLayer.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)
                //                replicatorLayer.frame = CGRectMake(13, 30, 360, self.view.bounds.size.height - 70)
                self.replicatorLayer.instanceCount = 2
                
                self.replicatorLayer.instanceTransform = CATransform3DMakeTranslation(self.view.bounds.size.width / 2 + 120, 0.0, 0.0)
                
                
                self.previewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
                
                
                // setup the views
                
                // @TODO get data from server to populate this
                // @TODO swipe up with pebble to change views
                
                self.mainPriority.fontSize = 20
                self.mainPriority.frame = CGRectMake(5, 100, 311, 311)
                self.mainPriority.alignmentMode = kCAAlignmentCenter
//                self.mainPriority.string = "\(self.taskArray[0])"
                self.mainPriority.foregroundColor = UIColor.whiteColor().CGColor
                
                self.additionalTasks.fontSize = 20
                self.additionalTasks.frame = CGRectMake(5, 300, 311, 311)
                self.additionalTasks.alignmentMode = kCAAlignmentCenter
//                self.additionalTasks.string = "\(self.taskArray.count) tasks today"
                
                self.overviewCenter.fontSize = 20
                self.overviewCenter.frame = CGRectMake(5, 100, 311, 311)
                self.overviewCenter.alignmentMode = kCAAlignmentCenter
//                self.overviewCenter.string = "Thorough information"
                
                
                self.overviewIndex.fontSize = 15
                self.overviewIndex.frame = CGRectMake(5, 300, 311, 311)
                self.overviewIndex.alignmentMode = kCAAlignmentCenter
                self.overviewIndex.string = "1"
                
                
                ////////////////////////////////////////////////////////
                

                // start off in main mode
                self.previewLayer?.addSublayer(self.mainPriority)
                self.previewLayer!.addSublayer(self.additionalTasks)
                
                
                self.replicatorLayer.addSublayer(self.previewLayer!)
                
                self.view.layer.addSublayer(self.replicatorLayer)
                self.captureSession?.startRunning()
            
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
        
            overviewCenter.string = taskArray[0] + "\n" + timeArray[0]
            overviewIndex.string = "1"
            
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
    
    func scrollInOverviewMode() {
        
        overviewCenter.string = taskArray[currentIndex] + "\n" + timeArray[0]
        overviewIndex.string = "\(currentIndex + 1)"
        
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