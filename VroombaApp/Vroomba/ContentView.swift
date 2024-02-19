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
    
    @ObservedObject var roomba: RoombaManager = RoombaManager()
    
    
    var body: some View {
        VStack {
            GroupBox {
                HStack {
                    Circle()
                        .frame(width: 10)
                        .padding(.leading, 8)
                        .foregroundStyle(roomba.online ? Color.green : Color.red)
                    
                    Text("Vroomba")
                        .font(.largeTitle)
                        .padding([.leading, .trailing])
                    Spacer()
                }
            }
            .padding([.top, .leading, .trailing])
            
            GroupBox {
                JoystickView(distance: $distance, angle: $angle)
            }
            .aspectRatio(contentMode: .fit)
            .padding()
            
            Spacer()
        }
        .onChange(of: distance) {
            withAnimation {
                if distance == 0 {
                    if lastSentDistance != 0 {
                        lastSentDistance = 0
                        Task {
                            await roomba.sendMotorPositions(left: 0, right: 0)
                        }
                        //print(roomba.online)
                    }
                    return
                }
                if abs(distance - (lastSentDistance ?? 0)) > 5 {
                    lastSentDistance = distance
                    lastSentAngle = angle
                    
                    Task {
                        await roomba.joystickHandler(distance: distance, angle: angle)
                    }
                    //print(roomba.online)
                }
            }
        }
        
        .onChange(of: angle) {
            withAnimation {
                if distance == 0 {
                    if lastSentDistance != 0 {
                        lastSentDistance = 0
                        Task {
                            await roomba.sendMotorPositions(left: 0, right: 0)
                        }
                    }
                    return
                }
                if abs(angle - (lastSentAngle ?? 0)) > 5 {
                    lastSentDistance = distance
                    lastSentAngle = angle
                    
                    
                    Task {
                        await roomba.joystickHandler(distance: distance, angle: angle)
                    }
                }
                //print(roomba.online)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
