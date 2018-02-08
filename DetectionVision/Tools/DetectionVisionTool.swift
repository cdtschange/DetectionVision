//
//  DSVisionTool.swift
//  Vision
//
//  Created by wei.mao on 2018/2/6.
//  Copyright © 2018年 cdts. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import Vision
import CoreImage

enum DetectionVisionType {
    case faceRectangles, faceLandMark, faceHat, textRectangles
}

struct DetectionVisionTool {
    static func detect(image: UIImage, type: DetectionVisionType, complete: @escaping (DetectionData) -> Void) {
        let convertImage = CIImage(image: image)!
        let handler = VNImageRequestHandler(ciImage: convertImage, options: [:])
        let detectRequest = getRequest(fromType: type, imageSize: image.size, complete: complete)
        if let request = detectRequest {
            try? handler.perform([request])
        }
    }
    static func getRequest(fromType type: DetectionVisionType, imageSize: CGSize, complete: @escaping (DetectionData) -> Void) -> VNImageBasedRequest? {
        var detectRequest: VNImageBasedRequest? = nil
        switch type {
        case .textRectangles:
            detectRequest = VNDetectTextRectanglesRequest(completionHandler: { (request, error) in
                self.handleTextRectangles(imageSize: imageSize, observations: request.results as? [VNTextObservation] ?? [], complete: complete)
            })
            (detectRequest as! VNDetectTextRectanglesRequest).reportCharacterBoxes = true
        case .faceHat:
            fallthrough
        case .faceRectangles:
            detectRequest = VNDetectFaceRectanglesRequest(completionHandler: { (request, error) in
                self.handleFaceRectangles(imageSize: imageSize, observations: request.results as? [VNFaceObservation] ?? [], complete: complete)
            })
        case .faceLandMark:
            detectRequest = VNDetectFaceLandmarksRequest(completionHandler: { (request, error) in
                self.handleFaceLandmarks(imageSize: imageSize, observations: request.results as? [VNFaceObservation] ?? [], complete: complete)
            })
        }
        return detectRequest
    }
    
    static func convertRect(rect: CGRect, imageSize: CGSize) -> CGRect {
        return CGRect(
            x: rect.origin.x * imageSize.width,
            y: imageSize.height - rect.origin.y * imageSize.height - rect.size.height * imageSize.height,
            width: rect.size.width * imageSize.width,
            height: rect.size.height * imageSize.height)
    }
    
    static func handleTextRectangles(imageSize: CGSize, observations: [VNTextObservation], complete: (TextDetectionData) -> Void) {
        var data = TextDetectionData()
        var array = [CGRect]()
        for ob in observations {
            for box in ob.characterBoxes ?? [] {
                array.append(convertRect(rect: box.boundingBox, imageSize: imageSize))
            }
        }
        data.rects = array
        complete(data)
    }
    static func handleFaceRectangles(imageSize: CGSize, observations: [VNFaceObservation], complete: (FaceDetectionData) -> Void) {
        var data = FaceDetectionData()
        var array = [CGRect]()
        for ob in observations {
            array.append(convertRect(rect: ob.boundingBox, imageSize: imageSize))
        }
        data.rects = array
        complete(data)
    }
    static func handleFaceLandmarks(imageSize: CGSize, observations: [VNFaceObservation], complete: (FaceLandmarkDetectionData) -> Void) {
        var data = FaceLandmarkDetectionData()
        data.observations = observations
        complete(data)
    }
    
    static func drawDetect(type: DetectionVisionType, view: UIView, data: DetectionData) {
        if type == .faceLandMark {
            drawDetectFaceLandmark(view: view, data: data as! FaceLandmarkDetectionData)
        } else if type == .faceHat {
            drawDetectFaceHat(view: view, data: data)
        } else {
            drawDetectRect(view: view, data: data)
        }
    }
    static var layers = [CALayer]()
    static func drawDetectRect(view: UIView, data: DetectionData) {
        for ly in layers {
            ly.removeFromSuperlayer()
        }
        layers.removeAll()
        for rect in data.rects {
            let outline = CALayer()
            outline.frame = rect
            outline.borderWidth = 2.0
            outline.borderColor = UIColor.orange.cgColor
            layers.append(outline)
            view.layer.addSublayer(outline)
        }
    }
    static var hats = [UIImageView]()
    static func drawDetectFaceHat(view: UIView, data: DetectionData) {
        for iv in hats {
            iv.removeFromSuperview()
        }
        hats.removeAll()
        for rect in data.rects {
            let w = rect.width
            let h = rect.height
            let x = rect.origin.x - w / 4 + 3
            let y = rect.origin.y - h
            let r = CGRect(x: x, y: y, width: w, height: h)
            let hi = UIImageView(image: UIImage(named: "hat"))
            hi.frame = r
            hats.append(hi)
            view.addSubview(hi)
        }
    }
    static func drawDetectFaceLandmark(view: UIView, data: FaceLandmarkDetectionData) {
        guard let imageView = view as? UIImageView else {
            return
        }
        
        var image = imageView.image
        var useCamera = image == nil
        func drawFace(_ allPoints: [CGPoint], bound: CGRect) {
            var points = [CGPoint]()
            // 转换特征的所有点
            for point in allPoints {
                let width = view.frame.width * bound.width
                let height = view.frame.height * bound.height
                let p = CGPoint(x: point.x * width + bound.origin.x * view.frame.width, y: bound.origin.y * view.frame.height + point.y * height)
                points.append(p)
            }
            UIGraphicsBeginImageContextWithOptions(view.frame.size, false, 1)
            let context = UIGraphicsGetCurrentContext()
            UIColor.green.set()
            context?.setLineWidth(2)
            
            // 设置翻转
            context?.translateBy(x: 0, y: view.frame.height)
            context?.scaleBy(x: 1, y: -1)
            
            // 设置线类型
            context?.setLineJoin(.round)
            context?.setLineCap(.round)
            
            // 设置抗锯齿
            context?.setShouldAntialias(true)
            context?.setAllowsAntialiasing(true)
            
            // 绘制
            let rect = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
            if image != nil {
                context?.draw(image!.cgImage!, in: rect)
            }
            context?.addLines(between: points)
            context?.drawPath(using: .stroke)
            // 结束绘制
            image = UIGraphicsGetImageFromCurrentImageContext()!
            UIGraphicsEndImageContext()
        }
        
        // 遍历所有特征
        for ob in data.observations {
            drawFace(ob.landmarks?.faceContour?.normalizedPoints ?? [], bound: ob.boundingBox)
            drawFace(ob.landmarks?.innerLips?.normalizedPoints ?? [], bound: ob.boundingBox)
            drawFace(ob.landmarks?.leftEye?.normalizedPoints ?? [], bound: ob.boundingBox)
            drawFace(ob.landmarks?.leftEyebrow?.normalizedPoints ?? [], bound: ob.boundingBox)
            drawFace(ob.landmarks?.leftPupil?.normalizedPoints ?? [], bound: ob.boundingBox)
            drawFace(ob.landmarks?.medianLine?.normalizedPoints ?? [], bound: ob.boundingBox)
            drawFace(ob.landmarks?.nose?.normalizedPoints ?? [], bound: ob.boundingBox)
            drawFace(ob.landmarks?.noseCrest?.normalizedPoints ?? [], bound: ob.boundingBox)
            drawFace(ob.landmarks?.outerLips?.normalizedPoints ?? [], bound: ob.boundingBox)
            drawFace(ob.landmarks?.rightEye?.normalizedPoints ?? [], bound: ob.boundingBox)
            drawFace(ob.landmarks?.rightPupil?.normalizedPoints ?? [], bound: ob.boundingBox)
            drawFace(ob.landmarks?.rightEyebrow?.normalizedPoints ?? [], bound: ob.boundingBox)
        }
        if tempImageView != nil {
            tempImageView?.removeFromSuperview()
            tempImageView = nil
        }
        if image != nil {
            if useCamera {
                tempImageView = UIImageView(image: image)
                tempImageView!.frame = imageView.frame
                imageView.addSubview(tempImageView!)
            } else {
                imageView.image = image
            }
        }
    }
    static var tempImageView: UIImageView? = nil
}

extension UIImage {
    
    func scaleImage(width: CGFloat) -> UIImage {
        let height = size.height * width / size.width
        UIGraphicsBeginImageContext(CGSize(width: width, height: height))
        draw(in: CGRect(x: 0, y: 0, width: width, height: height))
        let result = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        let data = UIImageJPEGRepresentation(result, 0.5)!
        return UIImage(data: data)!
    }
}
