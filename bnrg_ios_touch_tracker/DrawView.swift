//
//  DrawView.swift
//  bnrg_ios_touch_tracker
//
//  Created by Roman Brazhnikov on 31.05.2018.
//  Copyright © 2018 Roman Brazhnikov. All rights reserved.
//

import UIKit

class DrawView: UIView, UIGestureRecognizerDelegate{
    //
    //  Data
    //
    
    var currentLines = [NSValue:Line]()
    var finishedLines = [Line]()
    var selectedLineIndex: Int? {
        didSet{
            if selectedLineIndex == nil {
                let menu = UIMenuController.shared
                menu.setMenuVisible(false, animated: true)
            }
        }
    }
    
    var moveRecognizer: UIPanGestureRecognizer!
    
    //
    // Properties
    //
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @IBInspectable var finishedLineColor: UIColor = UIColor.black {
        didSet{
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var currentLineColor: UIColor = UIColor.red {
        didSet{
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var selectedLineColor: UIColor = UIColor.green {
        didSet{
            setNeedsDisplay()
        }
    }
    
    @IBInspectable var lineThickess: CGFloat = 10 {
        didSet{
            setNeedsDisplay()
        }
    }
    
    
    //
    //  Logic
    //
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        // creating/adding double tap to clear
        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.doubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.delaysTouchesBegan = true
        addGestureRecognizer(doubleTapRecognizer)
        
        // creating/adding single tap to select a line
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DrawView.tap(_:)))
        tapRecognizer.delaysTouchesBegan = true
        tapRecognizer.require(toFail: doubleTapRecognizer)
        addGestureRecognizer(tapRecognizer)
        
        // long press
        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(DrawView.longPress(_:)))
        addGestureRecognizer(longPressRecognizer)
        
        // pan / move
        moveRecognizer = UIPanGestureRecognizer(target: self, action: #selector(DrawView.moveLine(_:)))
        moveRecognizer.delegate = self
        moveRecognizer.cancelsTouchesInView = false
        addGestureRecognizer(moveRecognizer)
    }
    
    @objc func doubleTap(_ gestureRecognizer: UIGestureRecognizer){
        print("Recognized a double tap")
        
        selectedLineIndex = nil
        currentLines.removeAll()
        finishedLines.removeAll()
        
        setNeedsDisplay()
    }
    
    @objc func tap(_ gestureRecognizer: UIGestureRecognizer){
        print("Recognized a tap")
        
        let point = gestureRecognizer.location(in: self)
        selectedLineIndex = indexOfLine(at: point)
        
        // grabbing the munu conroller
        let menu = UIMenuController.shared
        
        if selectedLineIndex != nil {
            // making DrawView the target of menu item action messages
            becomeFirstResponder()
            
            // creating a new "delete" UIMenuItem
            let deleteItem = UIMenuItem(title: "Delete", action: #selector(DrawView.deleteLine(_:)))
            menu.menuItems = [deleteItem]
            
            // telling the menu where it should come from and show it
            let targetRect = CGRect(x: point.x, y: point.y, width: 2, height: 2)
            menu.setTargetRect(targetRect, in: self)
            menu.setMenuVisible(true, animated: true)
        } else {
            // hiding the menu if no line is selected
            menu.setMenuVisible(false, animated: true)
        }
        
        setNeedsDisplay()
    }
    
    @objc func longPress(_ gestureRecognizer: UIGestureRecognizer){
        print("Recognized a long press")
        
        if gestureRecognizer.state == .began {
            let point = gestureRecognizer.location(in: self)
            selectedLineIndex = indexOfLine(at: point)
            
            if selectedLineIndex != nil {
                currentLines.removeAll()
            }
        } else if gestureRecognizer.state == .ended {
            selectedLineIndex = nil
        }
        
        setNeedsDisplay()
    }
    
    @objc func deleteLine(_ sender: UIMenuController){
        // remove the selected line from the list of finishedLines
        if let index = selectedLineIndex {
            finishedLines.remove(at: index)
            selectedLineIndex = nil
            
            // redraw everything
            setNeedsDisplay()
        }
    }
    
    @objc func moveLine(_ gestureRecognizer: UIPanGestureRecognizer){
        print("Recognized a pan")
    }
    
    func stroke(_ line: Line){
        let path = UIBezierPath()
        path.lineWidth = lineThickess
        path.lineCapStyle = .round
        
        path.move(to: line.begin)
        path.addLine(to: line.end)
        path.stroke()
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    override func draw(_ rect: CGRect) {
        finishedLineColor.setStroke()
        for line in finishedLines {
            stroke(line)
        }
        
        currentLineColor.setStroke()
        for (_, line) in currentLines {
            stroke(line)
        }
        
        if let index = selectedLineIndex{
            selectedLineColor.setStroke()
            let selectedLine = finishedLines[index]
            stroke(selectedLine)
        }
    }

    func indexOfLine(at point: CGPoint) -> Int? {
        // Find a line close to point
        for (index, line) in finishedLines.enumerated(){
            let begin = line.begin
            let end = line.end
            
            // checking a few point on the line
            for t in stride(from: CGFloat(0), to: 1.0, by: 0.05) {
                let x = begin.x + ((end.x - begin.x) * t)
                let y = begin.y + ((end.y - begin.y) * t)
                
                // if the tapped point is within 20 points, let's return this line
                if hypot(x - point.x, y - point.y) < 20.0 {
                    return index
                }
            }
        }
        
        // nothing is close enough
        return nil
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        for touch in touches {
            let location = touch.location(in: self)
            let newLine = Line(begin: location, end: location)
            let key = NSValue(nonretainedObject: touch)
            currentLines[key] = newLine
        }
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            currentLines[key]?.end = touch.location(in: self)
        }
        
        setNeedsDisplay() 
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        
        for touch in touches {
            let key = NSValue(nonretainedObject: touch)
            if var line = currentLines[key] {
                line.end = touch.location(in: self)
                finishedLines.append(line)
                currentLines.removeValue(forKey: key)
            }
        }
        
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        print(#function)
        
        currentLines.removeAll()
        setNeedsDisplay()
    }
    
    
}

