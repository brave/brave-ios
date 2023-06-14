// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI

enum DownloadState {
  case downloading(value: Int64, total: Int64)
  case completed(_ sizeOnDisk: Int64)
}

struct PlaylistItemView: View {
  var title: String
  var isItemPlaying: Bool
  var duration: Int // Duration<Seconds>
  var downloadState: DownloadState?
  
  var body: some View {
    HStack(spacing: 12) {
      Color.clear
        .aspectRatio(1.333, contentMode: .fit)
        .frame(height: 90)
        .overlay {
          // Image
        }
        .overlay(alignment: .bottomLeading) {
          // Is Playing?
          if isItemPlaying {
            LeoPlayingSoundView()
              .frame(width: 16, height: 16)
              .padding(2)
//            Image(braveSystemName: "leo.playing.sound")
              .foregroundStyle(.white)
              .padding(8)
              .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 1)
          }
        }
        .background {
          LinearGradient(
            stops: [
              .init(color: .black.opacity(0.1), location: 0),
              .init(color: .black.opacity(0.0), location: 1.0),
              .init(color: .black.opacity(0.0), location: 1.0)
            ],
            startPoint: .bottomLeading,
            endPoint: .init(x: 0.5, y: 0)
          )
        }
        .background(Color(.secondaryBraveBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      VStack(alignment: .leading, spacing: 8) {
        Text(title)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
          .font(.callout.weight(.semibold))
        HStack {
          if #available(iOS 16.0, *) {
            Text(Duration.seconds(duration), format: .time(pattern: .minuteSecond))
          } else {
            Text("\(duration)") // FIXME: Use legacy formatter
          }
          if let downloadState {
            switch downloadState {
            case .downloading(let value, let total):
              Label {
                Text(value, format: .byteCount(style: .file))
              } icon: {
                ProgressView(value: CGFloat(value), total: CGFloat(total)) {
                  Image(braveSystemName: "leo.arrow.down")
                    .font(.caption)
                }
                .progressViewStyle(GuageProgressViewStyle())
              }
              .foregroundColor(Color(.braveBlurple))
            case .completed(let sizeOnDisk):
              Label {
                Text(sizeOnDisk, format: .byteCount(style: .file))
              } icon: {
                Image(braveSystemName: "leo.check.circle-outline")
                  .imageScale(.large)
              }
            }
          }
        }
        .font(.footnote)
        .foregroundColor(Color(.braveLabel))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
  }
}

private struct GuageProgressViewStyle: ProgressViewStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding(4)
      .overlay {
        Circle()
          .stroke(lineWidth: 2)
          .foregroundStyle(.tertiary)
      }
      .overlay {
        Circle()
          .rotation(.degrees(-90))
          .trim(from: 0, to: configuration.fractionCompleted ?? 0)
          .stroke(style: .init(lineWidth: 2, lineCap: .round, lineJoin: .round))
          .foregroundStyle(.primary)
          .animation(.spring(response: 0.3, dampingFraction: 0.8), value: configuration.fractionCompleted)
      }
  }
}

struct PlaylistItemView_PreviewProvider: PreviewProvider {
  static var previews: some View {
    PlaylistItemView(
      title: "I’m Dumb and Spent $7,000 on the New Mac Pro",
      isItemPlaying: true,
      duration: 750
    )
    .previewDisplayName("Playing")
    PlaylistItemView(
      title: "I’m Dumb and Spent $7,000 on the New Mac Pro",
      isItemPlaying: false,
      duration: 750,
      downloadState: .downloading(value: 21618799, total: 64618799)
    )
    .previewDisplayName("Downloading")
    PlaylistItemView(
      title: "I’m Dumb and Spent $7,000 on the New Mac Pro",
      isItemPlaying: false,
      duration: 750,
      downloadState: .completed(64618799)
    )
    .previewDisplayName("Downloaded")
  }
}

struct LeoPlayingSoundView: View {
  @State private var barHeights: SIMD4<Double> = .init(x: 0.45, y: 1, z: 0.6, w: 0.8)
  
  var body: some View {
    LeoPlayingSoundShape(barHeights: barHeights)
      .animation(.linear(duration: 0.3), value: barHeights)
      .onReceive(Timer.publish(every: 0.3, on: .main, in: .default).autoconnect(), perform: { _ in
        barHeights = .init(
          x: Double.random(in: 0.2...0.45), y: Double.random(in: 0.3...1), z: Double.random(in: 0.4...0.75), w: Double.random(in: 0.5...0.9)
        )
      })
  }
}

struct LeoPlayingSoundShape: Shape {
  var animatableData: AnimatablePair<AnimatablePair<CGFloat, CGFloat>, AnimatablePair<CGFloat, CGFloat>> {
    get { .init(.init(barHeights[0], barHeights[1]), .init(barHeights[2], barHeights[3]))}
    set { barHeights = [newValue.first.first, newValue.first.second, newValue.second.first, newValue.second.second ] }
  }
  
  var barHeights: SIMD4<Double> = .init(x: 0.45, y: 1, z: 0.6, w: 0.8)
  
  func path(in rect: CGRect) -> Path {
    Path { p in
      let separatorWidth = rect.width * 0.12
      let barWidth = rect.width * 0.15
      for i in 0..<4 {
        let height = rect.height * barHeights[i]
        p.addRoundedRect(in: .init(x: (CGFloat(i) * barWidth) + (CGFloat(i) * separatorWidth), y: rect.height - height, width: barWidth, height: height), cornerSize: .init(width: 2, height: 2), style: .continuous)
      }
    }
  }
}
