//
//  Handler.swift
//  Vroomba
//
//  Created by Mate Tohai on 29/01/2024.
//

import SwiftUI
import Combine

enum CurrentControlView: CaseIterable {
    case Joystick
    case Tilt
}

class RoombaManager: ObservableObject {
    @Published var online: Bool = false
    
    func sendRequest(left: Int, right: Int) async throws -> Bool {
        guard let url = URL(string: "http://192.168.4.1/") else {
            self.online = false
            return false
        }
        
        let body = ["left": left, "right": right]
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
            let taskResult = try await sendRequest(left: left, right: right)
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
            
            self.online = result
        } catch {
            self.online = false
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
