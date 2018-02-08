//
//  ViewController.swift
//  DetectionVision
//
//  Created by wei.mao on 2018/2/6.
//  Copyright © 2018年 cdts. All rights reserved.
//

import UIKit

class ViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let controller = segue.destination as! DetectionViewController
        if segue.identifier == "text" {
            controller.type = .textRectangles
        } else if segue.identifier == "face" {
            controller.type = .faceRectangles
        } else if segue.identifier == "faceLandmark" {
            controller.type = .faceLandMark
        } else if segue.identifier == "faceHat" {
            controller.type = .faceHat
        }
    }
}

