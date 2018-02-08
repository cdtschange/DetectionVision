//
//  DetectionModel.swift
//  Vision
//
//  Created by wei.mao on 2018/2/6.
//  Copyright © 2018年 cdts. All rights reserved.
//

import UIKit
import Vision

protocol DetectionData {
    var rects: [CGRect] { get set }
}

struct TextDetectionData: DetectionData {
    var rects: [CGRect] = []
}
struct FaceDetectionData: DetectionData {
    var rects: [CGRect] = []
}
struct FaceLandmarkDetectionData: DetectionData {
    var rects: [CGRect] = []
    var observations: [VNFaceObservation] = []
}

