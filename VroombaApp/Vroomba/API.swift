//
//  API.swift
//  Vroomba
//
//  Created by Mate Tohai on 25/09/2023.
//

import Foundation

func sendMotorPositions(right: Int, left: Int) {
    guard let url = URL(string: "http://192.168.4.1/") else { return }
    
    let body = ["right": right, "left": left]
    let finalBody = try! JSONEncoder().encode(body)
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = finalBody
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    URLSession.shared.dataTask(with: request) { (data, response, error) in
       print(response)
    }.resume()
}

func
