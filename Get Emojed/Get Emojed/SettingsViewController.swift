//
//  SettingsViewController.swift
//  Get Emojed
//
//  Created by Rafael d'Escoffier on 11/07/17.
//  Copyright © 2017 Rafael Escoffier. All rights reserved.
//

import UIKit

struct Settings {
    static let frontCameraKey = "frontCameraKey"
    static let scaleKey = "scaleKey"
    static let SettingsChangedName = NSNotification.Name("settingsChanged")
    
    static func fromNotification(notification: Notification) -> Settings? {
        guard let userInfo = notification.userInfo,
            let frontCamera = userInfo[frontCameraKey] as? Bool,
            let scale = userInfo[frontCameraKey] as? CGFloat else {
                return nil
        }
        
        return Settings(frontCamera: frontCamera, emojiScale: scale)
    }
    
    var frontCamera: Bool
    var emojiScale: CGFloat
}

protocol SettingsDelegate: class {
    func didChangeSettings(newSettings: Settings)
}

class SettingsViewController: UIViewController {
    @IBOutlet weak var frontCameraSwitch: UISwitch!
    @IBOutlet weak var emojiScaleSlider: UISlider!
    
    weak var delegate: SettingsDelegate?
    var currentSettings: Settings?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let settings = currentSettings {
            frontCameraSwitch.isOn = settings.frontCamera
            emojiScaleSlider.value = Float(settings.emojiScale)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        let newSettings = Settings(frontCamera: frontCameraSwitch.isOn, emojiScale: CGFloat(emojiScaleSlider.value))
        
        delegate?.didChangeSettings(newSettings: newSettings)
        
        NotificationCenter.default.post(name: Settings.SettingsChangedName,
                                        object: nil,
                                        userInfo: [
                                            Settings.frontCameraKey : newSettings.frontCamera,
                                            Settings.scaleKey : newSettings.emojiScale
            ]
        )
        
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
