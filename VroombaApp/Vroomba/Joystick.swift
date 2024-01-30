//
//  Joystick.swift
//  https://github.com/Tmate6/SwiftStuff/tree/main/Joystick
//
//  Created by Mate Tohai on 28/01/2024.
//

import SwiftUI
import Foundation

struct JoystickView: View {
    @State private var mid: CGPoint = CGPoint(x: 0, y: 0)
    @State private var radius: CGFloat = 0 // Radius of bounds circle. Change in .onAppear to modity size
    @State private var pos: CGPoint = CGPoint(x: 50, y: 50)
    
    @GestureState private var fingerPos: CGPoint? = nil
    @GestureState private var startPos: CGPoint? = nil
    
    // Used for snapping to mid
    @State private var incrementalStartPos: CGPoint = CGPoint(x: 50, y: 50)
    @State private var cycles: UInt16 = 0
    
    @Binding var distance: Int
    @Binding var angle: Int
    
    var simpleDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                // Refresh incrementalStartPos every 200 cycles
                if cycles >= 200 {
                    incrementalStartPos = pos
                    cycles = 0
                }
                cycles += 1
                var newPos = startPos ?? pos
                
                // Go to real position
                if (startPos == nil) { // If firt cycle
                    newPos.x += value.translation.width
                    newPos.y += value.translation.height
                    
                } else if (incrementalStartPos.x < mid.x + 5 && incrementalStartPos.x > mid.x - 5) { // If started near mid
                    newPos.x += value.translation.width
                    newPos.y += value.translation.height
                    
                } else if !(pos.x < mid.x + 10 && pos.x > mid.x - 10) { // If not near mid (x)
                    newPos.x += value.translation.width
                    newPos.y += value.translation.height
                    
                } else if !(pos.y < mid.y + 10 && pos.y > mid.y - 10) { // If not near mid (y)
                    newPos.x += value.translation.width
                    newPos.y += value.translation.height
                    
                }
                // Snap to mid
                else {
                    newPos = mid
                }
                
                self.angle = 180 - Int(atan2(newPos.x - mid.x, newPos.y - mid.y) * (180.0 / .pi)) // Angle in degrees
                
                var newDistance: Int = Int((CGFloat(sqrt(pow(newPos.x - mid.x, 2) + pow(newPos.y - mid.y, 2))) / radius) * 100)
                
                // Stop from going outside bounds
                if newDistance > 100 {
                    let angle = atan2(newPos.y - mid.y, newPos.x - mid.x) // Angle in radians... i think
                    newPos.x = mid.x + radius * cos(angle)
                    newPos.y = mid.y + radius * sin(angle)
                    newDistance = 100
                }
                
                self.distance = newDistance
                self.pos = newPos
                
                
            }
            .updating($startPos) { (value, startPos, transaction) in
                startPos = startPos ?? pos
            }
    }
    
    var fingerDrag: some Gesture {
        DragGesture()
            .updating($fingerPos) { (value, fingerPos, transaction) in
                fingerPos = value.location
            }
    }
    
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
                Path { path in
                    path.move(to: mid)
                    path.addLine(to: pos)
                }
                .stroke(Color.gray, style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                
                Circle()
                    .stroke(Color.gray)
                    .frame(width: 60)
                    .position(mid)
                
                Circle()
                    .stroke(Color.gray, lineWidth: 4)
                    .frame(width: radius*2)
                    .position(mid)
                
                Circle()
                    .foregroundColor(.white)
                    .frame(width: 50)
                    .position(pos)
                    .gesture(
                        simpleDrag.simultaneously(with: fingerDrag)
                    )
            }
            .onAppear {
                mid = CGPoint(x: geometry.size.width/2, y: geometry.size.height/2)
                pos = mid
                radius = geometry.size.width/2
            }
        }
    }
}
