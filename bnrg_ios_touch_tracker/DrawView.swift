//
//  DrawView.swift
//  bnrg_ios_touch_tracker
//
//  Created by Roman Brazhnikov on 31.05.2018.
//  Copyright © 2018 Roman Brazhnikov. All rights reserved.
//

import UIKit

class DrawView: UIView{
    var currentLine: Line?
    var finishedLines = [Line]()
    
    func stroke(_ line: Line){
        let path = UIBezierPath()
        path.lineWidth = 10
        path.lineCapStyle = .round
        
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
    }
    
    override func draw(_ rect: CGRect) {
        // Drawing finished lines in black
        UIColor.black.setStroke()
        for line in finishedLines {
            stroke(line)
        }
        
        // Line currentrly being drawn is in red
        if let line = currentLine {
            UIColor.red.setStroke()
            stroke(line)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        
        // getting location of the touch in view's coordinate system
        let location = touch.location(in: self)
        
        currentLine = Line(begin: location, end: location)
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if var line = currentLine{
            let touch = touches.first!
            let location = touch.location(in: self)
            line.end = location
            
            finishedLines.append(line)
        }
        currentLine = nil
        setNeedsDisplay()
    }
}

