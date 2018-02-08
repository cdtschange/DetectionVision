//
//  TextDetectionViewController.swift
//  DetectionVision
//
//  Created by wei.mao on 2018/2/6.
//  Copyright © 2018年 cdts. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class DetectionViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var session = AVCaptureSession()
    var videoDevice: AVCaptureDevice? = nil
    var started = false
    var pause = false
    var isFront = false
    var type: DetectionVisionType = .textRectangles
    var imageViewFrame = CGRect.zero
    var deviceInput: AVCaptureDeviceInput? = nil
    @IBOutlet weak var constraintImageWidth: NSLayoutConstraint!
    @IBOutlet weak var constraintImageHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if !started {
            auth()
        }
        started = true
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        imageView.layer.sublayers?[0].frame = imageView.bounds
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
    @IBAction func camera(_ sender: Any) {
        if !session.isRunning {
            imageView.image = nil
            imageView.layer.sublayers?.removeAll()
            constraintImageWidth.constant = view.frame.size.width
            constraintImageHeight.constant = view.frame.size.height
            let imageLayer = AVCaptureVideoPreviewLayer(session: session)
            imageLayer.frame = imageView.bounds
            imageView.layer.addSublayer(imageLayer)
            
            session.startRunning()
        }
    }
    @IBAction func cameraTransfer(_ sender: Any) {
        session.removeInput(deviceInput!)
        isFront = !isFront
        if isFront {
            deviceInput = try! AVCaptureDeviceInput(device: AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)!)
        } else {
            deviceInput = try! AVCaptureDeviceInput(device: AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)!)
        }
        session.addInput(deviceInput!)
    }
    @IBAction func library(_ sender: Any) {
        if session.isRunning {
            pause = true
        }
        session.stopRunning()
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }
    
    func auth() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            fallthrough
        case .notDetermined:
            startLiveVideo()
        case .denied:
            fallthrough
        case .restricted:
            showAlert(title: "相机未授权", message: "请打开设置-->隐私-->相机-->DetectionVision-->开启权限")
        }
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default, handler: nil))
        alert.show(self, sender: nil)
    }
    
    func startLiveVideo() {
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        session.addInput(deviceInput!)
        session.addOutput(deviceOutput)
        
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = imageView.bounds
        imageView.layer.addSublayer(imageLayer)
        imageViewFrame = imageView.frame
        
        session.startRunning()
    }
    
    
    func detect(image: UIImage, type: DetectionVisionType) {
        self.imageView.layer.sublayers?.removeAll()
        let image = image.scaleImage(width: view.frame.width)
        self.imageView.image = image
        constraintImageWidth.constant = image.size.width
        constraintImageHeight.constant = image.size.height
        DetectionVisionTool.detect(image: image, type: type) { [weak self] data in
            DispatchQueue.main.async() {
                DetectionVisionTool.drawDetect(type: type, view: self!.imageView, data: data)
            }
        }
    }
    
    
}

extension DetectionViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let request = DetectionVisionTool.getRequest(fromType: type, imageSize: imageViewFrame.size) { [weak self] data in
            DispatchQueue.main.async() {
                if let imageView = self?.imageView, let type = self?.type {
                    DetectionVisionTool.drawDetect(type: type, view: imageView, data: data)
                }
            }
        }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .rightMirrored, options: requestOptions)
        
        do {
            try imageRequestHandler.perform([request!])
        } catch {
            print(error)
        }
    }
}

extension DetectionViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
        if pause {
            session.startRunning()
            pause = false
        }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        detect(image: image, type: type)
    }
}
