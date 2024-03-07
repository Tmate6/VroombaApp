//
//  ContentView.swift
//  Vroomba
//
//  Created by Mate Tohai on 25/09/2023.
//

import SwiftUI
import Foundation


struct ContentView: View {
    @State var currentControlView: CurrentControlView = .Joystick
    
    @State var tiltSensitivity: Double = 300
    
    @State var distance: Int = 0
    @State private var lastSentDistance: Int? = nil
    
    @State var angle: Int = 0
    @State private var lastSentAngle: Int? = nil
    
    @ObservedObject var roomba: RoombaManager = RoombaManager()
    
    var body: some View {
        VStack {
            Button(action: {
                Task {
                    try await roomba.sendStatusRequest()
                }
            }, label: {
                GroupBox {
                    HStack {
                        Circle()
                            .frame(width: 10)
                            .padding(.leading, 8)
                            .foregroundStyle(roomba.online ? Color.green : Color.red)
                        
                        Text("Vroomba")
                            .font(.largeTitle)
                            .padding([.leading, .trailing])
                            .foregroundStyle(Color.primary)
                        Spacer()
                        
                        Text(roomba.voltage == nil ? "-" : String(format: "%.2fV", roomba.voltage!))
                            .foregroundStyle(roomba.voltage ?? 0.00 > 19 ?
                                             Color.green :
                                                roomba.voltage ?? 0.00 > 18 ?
                                             Color.yellow :
                                                roomba.voltage ?? 0.00 > 17 ?
                                             Color.orange :
                                                Color.red)
                            .font(.title)
                            .padding([.leading, .trailing])
                    }
                }
                .padding([.top, .leading, .trailing])
            })
            
            GroupBox {
                HStack {
                    Text("Controller")
                    Spacer()
                    
                    // Cutsom view as Picker() causes freezes
                    Button(action: {
                        currentControlView = .Joystick
                    }, label: {
                        GroupBox {
                            Text("Joystick")
                                .foregroundStyle(currentControlView == .Joystick ? Color.primary : Color.secondary)
                                .padding(.vertical, -3)
                        }
                    })
                    
                    Button(action: {
                        currentControlView = .Tilt
                    }, label: {
                        GroupBox {
                            Text("Tilt")
                                .foregroundStyle(currentControlView == .Tilt ? Color.primary : Color.secondary)
                                .padding(.vertical, -3)
                        }
                    })
                }
            }
            .padding([.top, .leading, .trailing])
            .padding(.bottom, 2)
            
            switch currentControlView {
            case .Joystick:
                GroupBox {
                    JoystickView(distance: $distance, angle: $angle)
                }
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal)
                
            case .Tilt:
                GroupBox {
                    TiltView(sensitivity: $tiltSensitivity, distance: $distance, angle: $angle)
                }
                .aspectRatio(contentMode: .fit)
                .padding(.horizontal)
                
                GroupBox {
                    HStack {
                        Text("Sensitivity")
                        Slider(value: $tiltSensitivity, in: 200...800)
                    }
                }
                .padding(.horizontal)
            }
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
                    }
                    return
                }
                if abs(distance - (lastSentDistance ?? 0)) > 5 {
                    lastSentDistance = distance
                    lastSentAngle = angle
                    
                    Task {
                        await roomba.joystickHandler(distance: distance, angle: angle)
                    }
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
        .onAppear {
            roomba.startStatusPolling()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
