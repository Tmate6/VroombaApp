//
//  Tilt.swift
//  https://github.com/Tmate6/SwiftStuff/tree/main/TiltView
//
//  Created by Mate Tohai on 22/02/2024.
//

import SwiftUI
import Foundation
import CoreMotion

class MotionManager {
    let motionManager = CMMotionManager()

    func startDeviceMotionUpdates(handler: @escaping (CMDeviceMotion?, Error?) -> Void) {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.1
            motionManager.startDeviceMotionUpdates(to: .main) { (data, error) in
                handler(data, error)
            }
        }
    }
}


struct TiltView: View {
    @State private var mid: CGPoint = CGPoint(x: 0, y: 0)
    @State private var radius: CGFloat = 0 // Radius of bounds circle. Change in .onAppear to modity size
    @State private var pos: CGPoint = CGPoint(x: 50, y: 50)
    
    // Preset values
    @Binding var sensitivity: Double
    private let snapWidth: CGFloat = 120
    
    private let motionManager = MotionManager()
    @State private var pitch: Double = 0
    @State private var roll: Double = 0
    
    @State private var stop: Bool = false
    
    // Output values. Distance from 0-100 and angle in degrees
    @Binding var distance: Int
    @Binding var angle: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                HStack {
                    VStack {
                        Text("\(angle)°, \(distance)")
                        Spacer()
                    }
                    Spacer()
                }
                
                Circle() // Snap cirlce
                    .stroke(Color.gray)
                    .contentShape(Circle())
                    .frame(width: snapWidth)
                    .position(mid)
                    .onTapGesture {
                        stop.toggle()
                    }
                
                Circle() // Bounds circle
                    .stroke(Color.gray, lineWidth: 4)
                    .frame(width: radius*2)
                    .position(mid)
                
                Circle() // Moving circle
                    .foregroundColor(stop ? .red : .white)
                    .frame(width: 50)
                    .position(pos)
                    .onTapGesture {
                        stop.toggle()
                    }
            }
            .onAppear {
                mid = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
                pos = mid
                radius = geometry.size.width/2
                
                self.motionManager.startDeviceMotionUpdates { (data, error) in
                    guard let data = data else { return }
                    let pitch = data.attitude.pitch
                    let roll = data.attitude.roll
                    
                    DispatchQueue.main.async {
                        self.pitch = pitch
                        self.roll = roll
                    }
                }
            }
            .onDisappear {
                self.stop = true
            }
            .onChange(of: pitch) {
                if stop {
                    return
                }
                
                var newPos: CGPoint
                
                let effectiveRoll = self.roll * sensitivity
                let effectivepitch = self.pitch * sensitivity
                
                // If not near mid
                if !((abs(effectiveRoll) < snapWidth/2)) {
                    print("1")
                    newPos = CGPoint(x: effectiveRoll + mid.x, y: effectivepitch + mid.y)
                }
                else if !((abs(effectivepitch) < snapWidth/2)) {
                    print("2")
                    newPos = CGPoint(x: effectiveRoll + mid.x, y: effectivepitch + mid.y)
                }
                // If near mid
                else {
                    newPos = mid
                }
                
                self.angle = 180 - Int(atan2(newPos.x - mid.x, newPos.y - mid.y) * (180.0 / .pi)) // Angle in degrees
                
                var newDistance: Int = Int((CGFloat(sqrt(pow(newPos.x - mid.x, 2) + pow(newPos.y - mid.y, 2))) / radius) * 100)
                
                // Stop from going outside bounds
                if newDistance > 100 {
                    let angle = atan2(newPos.y - mid.y, newPos.x - mid.x)
                    newPos.x = mid.x + radius * cos(angle)
                    newPos.y = mid.y + radius * sin(angle)
                    newDistance = 100
                }
                
                self.distance = newDistance
                
                withAnimation {
                    self.pos = newPos
                }
            }
            .onChange(of: stop) {
                if stop {
                    self.pos = mid
                }
            }
        }
    }
}
