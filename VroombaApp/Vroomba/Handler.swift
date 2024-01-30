//
//  Handler.swift
//  Vroomba
//
//  Created by Mate Tohai on 29/01/2024.
//

import Foundation

func sendMotorPositions(left: Int, right: Int) {
    guard let url = URL(string: "http://192.168.4.1/") else { return }
    
    let body = ["left": left, "right": right]
    let finalBody = try! JSONEncoder().encode(body)
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = finalBody
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { (data, response, error) in
       print(response)
    }.resume()
}

func joystickHandler(distance: Int, angle: Int) {
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
    
    print(left, right)
    
    sendMotorPositions(left: left, right: right)
}
