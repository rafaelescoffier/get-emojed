//
//  ViewController.swift
//  Get Emojed
//
//  Created by Rafael d'Escoffier on 06/07/17.
//  Copyright © 2017 Rafael Escoffier. All rights reserved.
//

import UIKit
import AVFoundation
import GoogleMobileVision
import GoogleMVDataOutput

struct EmojiDetails {
    var id: UInt
    var image: UIImage
    var frame: CGRect
    var center: CGPoint
    var transform: CATransform3D
}

class ViewController: UIViewController {

    @IBOutlet weak var recordView: UIView!
    @IBOutlet weak var captureView: UIView!
    @IBOutlet weak var overlayView: UIView!
    
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var captureSession:AVCaptureSession?
    var dataOutput: GMVDataOutput?
    var faceDetector: GMVDetector?

    fileprivate let defaultOrientation = UIDevice.current.orientation
    
    fileprivate var currentSettings = Settings(frontCamera: true, emojiScale: 1.1)
    
    fileprivate var scanning = false
    fileprivate var frameCount = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let detectorOptions: [AnyHashable: Any] = [GMVDetectorFaceMinSize: 0.3,
                                                   GMVDetectorFaceTrackingEnabled: true,
                                                   GMVDetectorFaceMode: GMVDetectorFaceModeOption.fastMode.rawValue,
                                                   GMVDetectorFaceLandmarkType: GMVDetectorFaceLandmark.all.rawValue,
                                                   GMVDetectorFaceClassificationType: GMVDetectorFaceClassification.all.rawValue]
        let faceDetector = GMVDetector(ofType: GMVDetectorTypeFace, options: detectorOptions)
        let output = GMVMultiDataOutput(detector: faceDetector)
        
        output?.multiDataDelegate = self
        
        self.faceDetector = faceDetector
        self.dataOutput = output
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupCapture()
        startCapture()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        clearCapture()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let vc = segue.destination as? SettingsViewController else { return }
        
        vc.delegate = self
        vc.currentSettings = currentSettings
    }
}

extension ViewController: GMVMultiDataOutputDelegate {
    func dataOutput(_ dataOutput: GMVDataOutput!, trackerFor feature: GMVFeature!) -> GMVOutputTrackerDelegate! {
        print("Generating tracker for new feature")
        
        let tracker = EmojiTracker(parentView: overlayView, settings: currentSettings)
        return tracker
    }
}

extension ViewController: SettingsDelegate {
    func didChangeSettings(newSettings: Settings) {
        currentSettings = newSettings
    }
}

// MARK: - Capture Methods
extension ViewController {
    fileprivate func startCapture() {
        if !scanning {
            captureSession?.startRunning()
            scanning = true
        }
    }
    
    fileprivate func stopCapture() {
        if scanning {
            captureSession?.stopRunning()
            scanning = false
        }
    }
    
    fileprivate func clearCapture() {
        stopCapture()
        
        videoPreviewLayer?.removeFromSuperlayer()
        
        captureSession = nil
        captureSession = nil
        videoPreviewLayer = nil
    }
    
    fileprivate func setupCapture() {
        let currentCamera: Int = currentSettings.frontCamera ? 1 : 0
        
        guard let captureDevice = AVCaptureDevice.devices(withMediaType: AVMediaTypeVideo)[currentCamera] as? AVCaptureDevice else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            let captureSession = AVCaptureSession()
            self.captureSession = captureSession
            
            captureSession.sessionPreset = AVCaptureSessionPresetMedium
            captureSession.addInput(input)
            
            guard let dataOutput = self.dataOutput, captureSession.canAddOutput(dataOutput) else {
                clearCapture()
                return
            }
            
            captureSession.addOutput(dataOutput)
            captureSession.commitConfiguration()
        
            setupPreview()
        } catch let error as NSError {
            print("Capture setup failed with error: \(error)")
        }
    }
    
    fileprivate func setupPreview() {
        if videoPreviewLayer == nil {
            let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            
            self.videoPreviewLayer = videoPreviewLayer
            
            captureView.layer.insertSublayer(videoPreviewLayer!, at: 0)
        }
        
        videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspect
        videoPreviewLayer?.bounds = captureView.layer.bounds
        videoPreviewLayer?.position = CGPoint(x: captureView.layer.bounds.midX, y: captureView.layer.bounds.midY)
    }
}

// MARK: - Rotation
extension ViewController {
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        coordinator.animate(alongsideTransition: { context in
            
        }) { context in
         self.setupPreview()
        }
    }
    
    override func willAnimateRotation(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        if self.videoPreviewLayer != nil {
            if (toInterfaceOrientation == .portrait) {
                self.videoPreviewLayer?.connection.videoOrientation = .portrait
            } else if (toInterfaceOrientation == .portraitUpsideDown) {
                self.videoPreviewLayer?.connection.videoOrientation = .portraitUpsideDown
            } else if (toInterfaceOrientation == .landscapeLeft) {
                self.videoPreviewLayer?.connection.videoOrientation = .landscapeLeft
            } else if (toInterfaceOrientation == .landscapeRight) {
                self.videoPreviewLayer?.connection.videoOrientation = .landscapeRight
            }
        }
    }
}

