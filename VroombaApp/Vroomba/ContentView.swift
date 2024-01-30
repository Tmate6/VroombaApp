//
//  ContentView.swift
//  Vroomba
//
//  Created by Mate Tohai on 25/09/2023.
//

import SwiftUI
import Foundation

struct ContentView: View {
    @State var distance: Int = 0
    @State private var lastSentDistance: Int? = nil
    
    @State var angle: Int = 0
    @State private var lastSentAngle: Int? = nil
    
    var body: some View {
        GroupBox {
            JoystickView(distance: $distance, angle: $angle)
        }
        .aspectRatio(contentMode: .fit)
        .padding()
        .onChange(of: distance) {
            if abs(distance - (lastSentDistance ?? 0)) > 5 {
                lastSentDistance = distance
                lastSentAngle = angle
                
                joystickHandler(distance: distance, angle: angle)
            }
        }
        .onChange(of: angle) {
            if abs(angle - (lastSentAngle ?? 0)) > 5 {
                lastSentDistance = distance
                lastSentAngle = angle
                
                joystickHandler(distance: distance, angle: angle)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
