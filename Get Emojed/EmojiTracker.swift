//
//  EmojiTracker.swift
//  Get Emojed
//
//  Created by Rafael d'Escoffier on 12/07/17.
//  Copyright © 2017 Rafael Escoffier. All rights reserved.
//

import Foundation
import GoogleMobileVision
import GoogleMVDataOutput

class EmojiTracker: NSObject, GMVOutputTrackerDelegate {
    weak var parentView: UIView?
    var emojiImageView: UIImageView?
    
    fileprivate let neutralImage = #imageLiteral(resourceName: "neutral")
    fileprivate let smilingImage = #imageLiteral(resourceName: "smiling")
    fileprivate let smileyImage = #imageLiteral(resourceName: "smiley")
    fileprivate let winkImage = #imageLiteral(resourceName: "wink")
    
    fileprivate var currentSettings: Settings
    
    init(parentView: UIView, settings: Settings) {
        self.parentView = parentView
        self.currentSettings = settings
        
        super.init()
        
        NotificationCenter.default.addObserver(forName: Settings.SettingsChangedName, object: nil, queue: nil) { notification in
            if let notif = Settings.fromNotification(notification: notification) {
                self.currentSettings = notif
            }
        }
    }
    
    func dataOutput(_ dataOutput: GMVDataOutput!, detectedFeature feature: GMVFeature!) {
        guard let face = feature as? GMVFaceFeature else { return }
        let details = generateDetails(face: face, dataOutput: dataOutput)
        let imageView = imageViewFrom(details: details)
        
        emojiImageView = imageView
        
        self.parentView?.addSubview(imageView)
        
        print("Face detected")
    }
    
    func dataOutput(_ dataOutput: GMVDataOutput!, updateMissing features: [GMVFeature]!) {
    }
    
    func dataOutput(_ dataOutput: GMVDataOutput!, updateFocusing feature: GMVFeature!, forResultSet features: [GMVFeature]!) {
        guard let face = feature as? GMVFaceFeature else { return }
        
        let details = generateDetails(face: face, dataOutput: dataOutput)
        
        emojiImageView?.frame = details.frame
        emojiImageView?.center = details.center
        emojiImageView?.layer.transform = details.transform
        emojiImageView?.image = details.image
    }
    
    func dataOutputCompleted(withFocusingFeature dataOutput: GMVDataOutput!) {
        emojiImageView?.removeFromSuperview()
    }
    
    private func generateDetails(face: GMVFaceFeature, dataOutput: GMVDataOutput) -> EmojiDetails {
        let zRadians = -face.headEulerAngleZ / 180.0 * CGFloat(Double.pi)
        let yRadians = -face.headEulerAngleY / 180.0 * CGFloat(Double.pi)
        let transform = CATransform3DConcat(CATransform3DMakeRotation(yRadians, 0, 1, 0), CATransform3DMakeRotation(zRadians, 0, 0, 1))
        
        let fixedOffset = currentSettings.frontCamera ? dataOutput.offset : dataOutput.offset.applying(CGAffineTransform(translationX: 0, y: -15))
        
        let faceRect = scaledRect(rect: face.bounds, xScale: dataOutput.xScale, yScale: dataOutput.yScale, offset: fixedOffset).applying(CGAffineTransform(scaleX: currentSettings.emojiScale, y: currentSettings.emojiScale))
        let nosePosition = scaledPoint(point: face.noseBasePosition, xScale: dataOutput.xScale, yScale:dataOutput.yScale, offset: fixedOffset)
        
        let emoji: UIImage
        
        if face.leftEyeOpenProbability < 0.30 || face.rightEyeOpenProbability < 0.30 {
            emoji = winkImage
        } else {
            switch face.smilingProbability {
            case 0..<0.25: emoji = neutralImage
            case 0.25..<0.70: emoji = smilingImage
            default: emoji = smileyImage
            }
        }
        
        let details = EmojiDetails(id: face.trackingID,
                                   image: emoji,
                                   frame: faceRect,
                                   center: nosePosition,
                                   transform: transform)
        
        return details
    }
    
    private func imageViewFrom(details: EmojiDetails) -> UIImageView {
        let emojiImageView = UIImageView(image: details.image)
        emojiImageView.frame = details.frame
        emojiImageView.center = details.center
        emojiImageView.layer.transform = details.transform
        emojiImageView.contentMode = .scaleAspectFit
        
        return emojiImageView
    }
    
    private func scaledPoint(point: CGPoint, xScale: CGFloat, yScale: CGFloat, offset: CGPoint) -> CGPoint {
        let resultPoint = CGPoint(x: point.x * xScale + offset.x,y: point.y * yScale + offset.y)
        
        return resultPoint
    }
    
    private func scaledRect(rect: CGRect, xScale: CGFloat, yScale: CGFloat, offset: CGPoint) -> CGRect {
        var resultRect = CGRect(x: rect.origin.x * xScale,
                                y: rect.origin.y * yScale,
                                width: rect.size.width * xScale,
                                height: rect.size.height * yScale)
        
        resultRect = resultRect.offsetBy(dx: offset.x, dy: offset.y)
        
        return resultRect
    }
}
