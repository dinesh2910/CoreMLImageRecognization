//
//  ViewController.swift
//  CoreMLImageRecognition
//
//  Created by Dinesh Danda on 10/2/18.
//  Copyright © 2018 Dinesh Danda. All rights reserved.
//

import UIKit
import CoreML
import Vision
import AVKit


class ViewController: UIViewController, UINavigationControllerDelegate{
    @IBOutlet weak var imageview: UIImageView!
    @IBOutlet weak var classifierLbl: UILabel!
   
    var model:Inceptionv3!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        model = Inceptionv3()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    
    }
    
    
    
       @IBAction func cameraBarbutton(_ sender: Any) {
        if !UIImagePickerController.isSourceTypeAvailable(.camera){
            return
            }
        let camerapicker = UIImagePickerController()
        camerapicker.sourceType = .camera
        camerapicker.delegate = self as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
        camerapicker.allowsEditing = false
        present(camerapicker,animated: true)
     }
    
    
    @IBAction func LibraryBarButton(_ sender: Any) {
        let photopicker = UIImagePickerController()
        photopicker.allowsEditing = false
        photopicker.delegate = self as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
        photopicker.sourceType = .photoLibrary
        present(photopicker,animated: true)
     }
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true)
        classifierLbl.text = "Analyzing Image..."
        guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else {
            return
        } //1
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
        image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(newImage.size.width), Int(newImage.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(newImage.size.width), height: Int(newImage.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) //3
        
        context?.translateBy(x: 0, y: newImage.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        imageview.image = newImage
        
        // Core ML
        guard let prediction = try? model.prediction(image: pixelBuffer!) else {
            return
        }
        
        classifierLbl.text = "I think this is a \(prediction.classLabel)."
    }
}
