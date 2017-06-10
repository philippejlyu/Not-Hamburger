//
//  ViewController.swift
//  Object Recognizer
//
//  Created by Philippe Yu on 2017-06-10.
//  Copyright © 2017 Philippe Yu. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController {
    
    //MARK: - Properties
    let model = VGG16()
    var image = UIImage()
    let imagePicker = UIImagePickerController()
    
    //MARK: - Outlets
    @IBOutlet weak var objectTextView: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - Core ML
    
    func getPrediction(picture: UIImage) {
        DispatchQueue.main.async {
            let newImage = self.resizeImage(image: picture, targetSize: CGSize(width: 224, height: 224))
            
            //Convert it to a pixel buffer ref
            //You need to create a context
            let context = CIContext(options: nil)
            //Safely unwrap the ciImage and cgImage
            if let ciImage = CIImage(image: newImage),
                let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
                //Create the pixel buffer
                var pxBuffer: CVPixelBuffer?
                //Create an empty options dictionary
                let options: NSDictionary = [:]
                //Get the data from the cgImage
                let dataFromImageProvider = cgImage.dataProvider?.data
                //Now we use this to create the CVPixelBuffer
                CVPixelBufferCreateWithBytes(kCFAllocatorDefault,
                                             cgImage.width,
                                             cgImage.height,
                                             kCVPixelFormatType_32BGRA,
                                             CFDataGetMutableBytePtr(dataFromImageProvider as! CFMutableData),
                                             cgImage.bytesPerRow,
                                             nil,
                                             nil,
                                             options,
                                             &pxBuffer)
                //Now we get the prediction
                guard let prediction = try? self.model.prediction(image: pxBuffer!) else {
                    fatalError("Error getting the prediction")
                }
                
                //Now we put the prediction data in the UI
                let itemName = prediction.classLabel
                
                //Do this as sometimes the prediction gives multiple things. We only want the first.
                //We find the first as they are separated by a comma
                let indexOfComma = itemName.index(of: ",")
                //Check to see if there is a comma
                if indexOfComma != nil {
                    //There is a comma, we need to get the substring from the start to the comma.
                    let firstObject = itemName.substring(to: indexOfComma!)
                    //Set the label
                    self.objectTextView.text = firstObject
                } else {
                    //Since there is no comma, we don't need to do the comma stuff
                    self.objectTextView.text = itemName
                }
                
            }
        }
    }
    
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let width = round(image.size.width * (targetSize.width/image.size.width))
        let height = round((image.size.height * (targetSize.height/image.size.height)))
        let newSize = CGSize(width: width, height: height)
        let rect = CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height)
        
        //This is where we resize it
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: rect)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    //This is where we take the photo
    @IBAction func takePhoto(_ sender: Any) {
        //Set stuff for the image picker
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        //Present the image picker
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    //When the picture is taken, we run this
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        imagePicker.dismiss(animated: true, completion: nil)
        image = (info[UIImagePickerControllerOriginalImage] as? UIImage)!
        getPrediction(picture: image)
        imageView.image = image
    }
}

