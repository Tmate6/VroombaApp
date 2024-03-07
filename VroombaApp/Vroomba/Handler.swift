//
//  Handler.swift
//  Vroomba
//
//  Created by Mate Tohai on 29/01/2024.
//

import Foundation
import SwiftUI
import Combine

extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

enum CurrentControlView: CaseIterable {
    case Joystick
    case Tilt
}

class RoombaManager: ObservableObject {
    @Published var online: Bool = false
    @Published var voltage: Double? = nil
    
    let statusPollingInterval: Int = 5_000_000_000
    
    func startStatusPolling() {
        print("starting")
        Task {
            while true {
                do {
                    print("sending req")
                    let _ = try await sendStatusRequest()
                }
                catch {
                    withAnimation {
                        self.online = false
                    }
                }
                try? await Task.sleep(nanoseconds: UInt64(statusPollingInterval))
            }
        }
    }
    
    func sendStatusRequest() async throws -> Bool {
        guard let url = URL(string: "http://192.168.4.1/status") else {
            withAnimation {
                self.online = false
            }
            return false
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let voltage = json["voltage"] as? Double {
            
            if self.voltage == nil {
                self.voltage = 0
                while self.voltage! < voltage {
                    let newVoltage: Double = self.voltage! + 0.01
                    
                    withAnimation {
                        self.voltage = newVoltage.rounded(toPlaces: 2)
                    }
                    if self.voltage == voltage {
                        break
                    }
                    try? await Task.sleep(nanoseconds: 50)
                }
            }
            
            while self.voltage! < voltage {
                let newVoltage: Double = self.voltage! + 0.01
                
                withAnimation {
                    self.voltage = newVoltage.rounded(toPlaces: 2)
                }
                if self.voltage == voltage {
                    break
                }
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
            while self.voltage! > voltage {
                let newVoltage: Double = self.voltage! - 0.01
                
                withAnimation {
                    self.voltage! = newVoltage.rounded(toPlaces: 2)
                }
                if self.voltage == voltage {
                    break
                }
                try? await Task.sleep(nanoseconds: 10_000_000)
            }
            withAnimation {
                self.online = true
            }
            return true
            
        } else {
            withAnimation {
                self.online = false
                self.voltage = nil
            }
            throw URLError(.cannotParseResponse)
        }
    }
    
    func sendMovementRequest(left: Int?, right: Int?) async throws -> Bool {
        guard let url = URL(string: "http://192.168.4.1/") else {
            withAnimation {
                self.online = false
            }
            return false
        }
        
        var body: [String: Int]
        
        if left == nil {
            body = ["right": right!]
        } else if right == nil {
            body = ["left": left!]
        } else {
            body = ["left": left!, "right": right!]
        }
        
        let finalBody = try! JSONEncoder().encode(body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = finalBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (_, _) = try await URLSession.shared.data(for: request)
        
        return true
    }

    func sendMotorPositions(left: Int, right: Int) async {
        // Once again, blatantly stolen code from https://stackoverflow.com/questions/75019438/swift-have-a-timeout-for-async-await-function
        
        let requestTask = Task {
            let taskResult = try await sendMovementRequest(left: left, right: right)
            try Task.checkCancellation()
            
            return taskResult
        }
        
        let timeoutTask = Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
            requestTask.cancel()
        }
        
        do {
            let result = try await requestTask.value
            timeoutTask.cancel()
            
            withAnimation {
                self.online = result
            }
        } catch {
            withAnimation {
                self.online = false
            }
        }
    }
            
    private var cancellables: Set<AnyCancellable> = []

    
    func joystickHandler(distance: Int, angle: Int) async {
        // Set both to max value
        var left: Int = distance
        var right: Int = distance
        
        if angle - 180 > 0 { // Turning left
            left -= abs((abs((angle - 180)) - 180) * 100 / 90)
            if left < 0 {
                right -= (abs((abs((angle - 180)) - 180) * 100 / 45) - 200)
            }
        } else { // Turning right
            right -= abs((abs((angle - 180)) - 180) * 100 / 90)
            
            if right < 0 {
                left -= (abs((abs((angle - 180)) - 180) * 100 / 45) - 200)
            }
        }
        
        if left < -100 {
            left = -100 + (100 - (distance))
        }
        if right < -100 {
            right = -100 + (100 - (distance))
        }
        
        
        left = min(max(left, -100), 100)
        right = min(max(right, -100), 100)
        
        print("angle: ", angle, "distance: ", distance)
        print(left, right)
        
        await sendMotorPositions(left: left, right: right)
    }
}
