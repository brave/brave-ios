// Copyright 2021 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import AVKit

// Documentation for VTT file format:
// https://developer.mozilla.org/en-US/docs/Web/API/WebVTT_API
// We use this until I find a better way for AVPlayer to show subtitles..

public class PlaylistSubtitle: Codable {
    let startTime: TimeInterval
    let endTime: TimeInterval
    let text: String
    let alignment: Alignment
    let size: Int
    let position: Int
    
    init(startTime: TimeInterval, endTime: TimeInterval, text: String) {
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
        self.alignment = .center
        self.size = 0
        self.position = 0
    }
    
    enum Alignment: String, Codable {
        case start
        case center
        case end
        case none
    }
}

public class VTTParser {
    let url: String
    private(set) var subtitles: [PlaylistSubtitle]
    private var session: URLSessionDataTask?
    
    init(url: String, completion: @escaping (VTTParser) -> Void) {
        self.url = url
        self.subtitles = []
        self.session = nil
        
        if let url = URL(string: url) {
            session = URLSession(configuration: .ephemeral).dataTask(with: url) { data, response, error in
                if let error = error {
                    print(error)
                    return
                }
                
                guard let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode <= 399 else {
                    return
                }
                
                guard let data = data, let subtitles = String(data: data, encoding: .utf8), !subtitles.isEmpty else { return }
                
                let formatter = DateFormatter()
                formatter.dateFormat = "hh:mm:ss.SSS"
                
                for chunk in subtitles.replacingOccurrences(of: "\n\n", with: "\r").split(separator: "\r") {
                    if chunk.contains("-->") {
                        let dataChunks = chunk.split(separator: "\n")
                        
                        let times = dataChunks.first!.replacingOccurrences(of: " --> ", with: "\r").split(separator: "\r")
                        let startTime = String(times[0])
                        let endTime = String(String(times[1]).split(separator: " ").first!)
                        
                        let startDate = formatter.date(from: startTime)!.timeIntervalSinceNow
                        let endDate = formatter.date(from: endTime)!.timeIntervalSinceNow
                        
                        self.subtitles.append(
                            PlaylistSubtitle(
                                startTime: startDate,
                                endTime: endDate,
                                text: String(dataChunks[1...].joined(separator: "\n"))
                            )
                        )
                    }
                }
                
                completion(self)
            }
            
            session?.resume()
        }
    }
}
