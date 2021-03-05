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
                    return DispatchQueue.main.async { completion(self) }
                }
                
                guard let response = response as? HTTPURLResponse, response.statusCode >= 200 && response.statusCode <= 399 else {
                    return DispatchQueue.main.async { completion(self) }
                }
                
                guard let data = data, let subtitles = String(data: data, encoding: .utf8), !subtitles.isEmpty else {
                    return DispatchQueue.main.async { completion(self) }
                }
                
                let getRelativeSecondsFromStringInterval = { (time: String) -> TimeInterval in
                    let formatter = DateFormatter().then {
                        $0.dateFormat = "hh:mm:ss.SSS"
                    }
                    
                    let date = formatter.date(from: time)!
                    
                    let units: Set<Calendar.Component> = [.nanosecond, .second, .minute, .hour]
                    let components = Calendar.current.dateComponents(units, from: date)
                    
                    let hours = components.hour ?? 0
                    let minutes = components.minute ?? 0
                    let seconds = components.second ?? 0
                    let milliseconds = (Float(components.nanosecond ?? 0) / 1000000.0) / 1000.0
                    return TimeInterval((hours * 60 * 60) + (minutes * 60) + seconds) + TimeInterval(milliseconds)
                }
                
                for chunk in subtitles.replacingOccurrences(of: "\n\n", with: "\r").split(separator: "\r") {
                    if chunk.contains("-->") {
                        let dataChunks = chunk.split(separator: "\n")
                        
                        let times = dataChunks.first!.replacingOccurrences(of: " --> ", with: "\r").split(separator: "\r")
                        let startTime = String(times[0])
                        let endTime = String(String(times[1]).split(separator: " ").first!)
                        
                        let startDate = getRelativeSecondsFromStringInterval(startTime)
                        let endDate = getRelativeSecondsFromStringInterval(endTime)
                        
                        self.subtitles.append(
                            PlaylistSubtitle(
                                startTime: startDate,
                                endTime: endDate,
                                text: String(dataChunks[1...].joined(separator: "\n"))
                            )
                        )
                    }
                }
                
                DispatchQueue.main.async { completion(self) }
            }
            
            session?.resume()
        }
    }
}
