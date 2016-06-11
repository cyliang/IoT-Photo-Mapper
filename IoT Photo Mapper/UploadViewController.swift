//
//  UploadViewController.swift
//  IoT Photo Mapper
//
//  Created by Chih-Yung Liang on 2015/12/30.
//  Copyright © 2015年 Chih-Yung Liang. All rights reserved.
//

import UIKit

extension NSMutableData {
    func appendString(string: String) {
        let data = string.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
        appendData(data!)
    }
}

extension UIImage {
    func imageByNormalizingOrientation() -> UIImage {
        if (self.imageOrientation == .Up) {
            return self
        }
        
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        self.drawInRect(CGRect(origin: CGPoint(x: 0, y: 0), size: self.size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return normalized
    }
}

class UploadViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate {
    
    @IBOutlet var retakeBtn: UIBarButtonItem!
    @IBOutlet var uploadBtn: UIBarButtonItem!
    @IBOutlet var imageView: UIImageView!
    let picker = UIImagePickerController()
    var camView: UIView!
    let progressBar = UIProgressView(progressViewStyle: .Bar)
    let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .Dark))
    let progressCircle = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
    var coreData: CoreData?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.picker.allowsEditing = false
        self.picker.delegate = self
        self.setCamView()
        self.retakeImage()
        
        self.imageView.contentMode = .ScaleAspectFit
        self.blurView.frame = self.imageView.frame
        self.progressCircle.center = self.blurView.contentView.center
        self.progressBar.progress = 0.0
        self.progressBar.frame = CGRect(x: 0, y: 0, width: self.blurView.contentView.frame.width, height: 6)
        self.blurView.contentView.addSubview(self.progressCircle)
        self.blurView.contentView.addSubview(self.progressBar)
        self.retakeBtn.enabled = false
        self.uploadBtn.enabled = false

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setCamView() {
        self.camView = UIView(frame: picker.view.frame)
        let camToolBar = UIToolbar(frame: CGRect(x: 0, y: picker.view.frame.height - 141, width: picker.view.frame.width, height: 140))
        
        camToolBar.setItems([
            UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: "camCancel"),
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .Camera, target: self, action: "camTakePicture"),
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Photo Library", style: .Plain, target: self, action: "changePhotoLibrary")
        ], animated: false)
        camToolBar.barTintColor = UIColor.blackColor()
        camToolBar.tintColor = UIColor.whiteColor()
        
        self.camView.addSubview(camToolBar)
    }
    
    func camTakePicture() {
        self.picker.takePicture()
        self.picker.showsCameraControls = false
    }
    
    func camCancel() {
        self.imagePickerControllerDidCancel(self.picker)
    }
    
    func changePhotoLibrary() {
        self.picker.sourceType = .PhotoLibrary
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        imageView.image = image
        self.lockButtons(false)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.lockButtons(false)
        dismissViewControllerAnimated(true, completion: { () -> Void in
            if (self.imageView.image == nil) {
                self.navigationController?.popViewControllerAnimated(true)
            }
        })
    }
    
    @IBAction
    func retakeImage() {
        if (UIImagePickerController.isSourceTypeAvailable(.Camera)) {
            self.picker.sourceType = .Camera
            self.picker.cameraOverlayView = self.camView
            self.picker.showsCameraControls = true
        } else {
            self.picker.sourceType = .PhotoLibrary
        }
        presentViewController(self.picker, animated: true, completion: nil)
    }
    
    @IBAction
    func uploadImage() {
        self.lockButtons(true)
        
        let url = NSURL(string: "http://140.113.195.27/api/Fetch/AddPhoto")!
        let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: self, delegateQueue: NSOperationQueue.mainQueue())
        let boundary = "Boundary-\(NSUUID().UUIDString)"
        
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.HTTPBody = createRequestBody(boundary)
        
        session.dataTaskWithRequest(request).resume()
    }
    
    func createRequestBody(boundary: String) -> NSData {
        let body = NSMutableData()
        let location = self.coreData!.location
        let params: [String: String] = [
            "ACCOUNT": "0116229",
            "ACCESSCODE": "21397B163D",
            "LONGITUDE": location.coordinate.longitude.description,
            "LATITUDE": location.coordinate.latitude.description
        ]
        
        for (key, value) in params {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            body.appendString("\(value)\r\n")
        }
        
        body.appendString("--\(boundary)\r\n")
        body.appendString("Content-Disposition: form-data; name=\"MYPHOTO\"; filename=\"\(Int(NSDate().timeIntervalSince1970).description).jpg\"\r\n")
        body.appendString("Content-Type: image/jpeg\r\n\r\n")
        body.appendData(UIImageJPEGRepresentation(self.imageView.image!.imageByNormalizingOrientation(), 0.8)!)
        body.appendString("\r\n")
        
        body.appendString("--\(boundary)--\r\n")
        return body
    }
    
    func lockButtons(lock: Bool) {
        self.progressBar.progress = 0.0
        
        if (lock) {
            self.view.addSubview(self.blurView)
            self.progressCircle.startAnimating()
            self.navigationItem.setHidesBackButton(true, animated: true)
            self.retakeBtn.enabled = false
            self.uploadBtn.enabled = false
        } else {
            self.blurView.removeFromSuperview()
            self.progressCircle.stopAnimating()
            self.navigationItem.setHidesBackButton(false, animated: false)
            self.retakeBtn.enabled = true
            self.uploadBtn.enabled = true
        }
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        let alert = UIAlertController(title: "Upload Error!", message: error?.localizedDescription, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        
        self.presentViewController(alert, animated: true, completion: nil)
        self.lockButtons(false)
    }
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        self.progressBar.progress = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
    }
    
    func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        let alert = UIAlertController(title: "Upload Successfully!", message: nil, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (UIAlertAction) -> Void in
            self.coreData?.reloadPersonalData()
            self.navigationController?.popViewControllerAnimated(true)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
