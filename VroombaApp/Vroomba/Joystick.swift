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

    // Used for snapping to mid. No of cycles to stay snapped/to not snap
    @State private var dontSnapFor: Int = 20
    @State private var staySnappedFor: Int = 0
    
    // Preset values
    private let dontSnapForDefault: Int = 20
    private let staySnappedForDefault: Int = 40

    
    @Binding var distance: Int
    @Binding var angle: Int

    var simpleDrag: some Gesture {
        DragGesture()
            .onChanged { value in
                var newPos = startPos ?? pos
                
                if (startPos == nil) { // If firt cycle
                    self.staySnappedFor = 0
                    self.dontSnapFor = dontSnapForDefault
                }
                
                // Stay snapped to mid
                if staySnappedFor > 0 {
                    self.staySnappedFor -= 1
                    
                    // Dont snap for next cyeles if just unsnapped
                    if staySnappedFor == 0 {
                        self.dontSnapFor = dontSnapForDefault
                    }
                    
                    return
                }
                
                if dontSnapFor > 0 {
                    self.dontSnapFor -= 1
                }
                
                if !(pos.x < mid.x + 25 && pos.x > mid.x - 25) { // If not near mid (x)
                    newPos.x += value.translation.width
                    newPos.y += value.translation.height

                } else if !(pos.y < mid.y + 25 && pos.y > mid.y - 25) { // If not near mid (y)
                    newPos.x += value.translation.width
                    newPos.y += value.translation.height
                    
                }
                // If near mid
                else {
                    if self.dontSnapFor == 0 { // Snap, if can
                        newPos = mid
                        self.staySnappedFor = staySnappedForDefault
                        
                    } else { // Otherwise act as normal. These 4 lines solved all my problems
                        newPos.x += value.translation.width
                        newPos.y += value.translation.height
                    }
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
                    .frame(width: 80)
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
