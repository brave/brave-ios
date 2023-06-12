// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import DesignSystem

enum ContentSpeed: Double {
  case normal = 1.0
  case fast = 1.5
  case faster = 2
  
  mutating func increase() {
    switch self {
    case .normal: self = .fast
    case .fast: self = .faster
    case .faster: self = .normal
    }
  }
}

struct MediaControls: View {
  var title: String
  
  @State private var value: Int = 68
  @State private var isPlaying: Bool = false
  @State private var isScrubbing: Bool = false
  @State private var isShuffleEnabled: Bool = false
  @State private var contentSpeed: ContentSpeed = .normal
  
  @State private var resumePlayingAfterScrub: Bool = false
  
  var body: some View {
    VStack {
      HStack(spacing: 8) {
        Color.clear
          .frame(width: 20, height: 20)
          .background(Material.ultraThin)
          .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        Text(title)
          .font(.body.weight(.semibold))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      MediaScrubber(currentTime: $value, totalDuration: 1008, isScrubbing: $isScrubbing)
      VStack(spacing: 24) {
        PlaybackControls(isPlaying: $isPlaying)
        ExtraControls(isShuffleEnabled: $isShuffleEnabled, contentSpeed: $contentSpeed)
      }
      .disabled(isScrubbing)
      .opacity(isScrubbing ? 0.5 : 1.0)
      .animation(.linear(duration: 0.1), value: isScrubbing)
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 24)
    .colorScheme(.dark)
    .onChange(of: isScrubbing) { newValue in
      if newValue {
        resumePlayingAfterScrub = isPlaying
        isPlaying = false
      } else {
        isPlaying = resumePlayingAfterScrub
      }
    }
    .onReceive(Timer.publish(every: 1, on: .main, in: .default).autoconnect(), perform: { _ in
      if isPlaying {
        value += 1
      }
    })
  }
}

struct PlaybackControls: View {
  @Binding var isPlaying: Bool
  
  private var playButtonTransition: AnyTransition {
    .scale.combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.7))
  }
  
  var body: some View {
    HStack {
      Button { } label: {
        Image(braveSystemName: "leo.start.outline")
      }
      Spacer()
      Button { } label: {
        Image(braveSystemName: "leo.rewind.15")
      }
      Spacer()
      Toggle(isOn: $isPlaying, label: {
        // Maintain the sizes when swapping images
        ZStack {
          Image(braveSystemName: "leo.pause.filled")
          Image(braveSystemName: "leo.play.filled")
        }
        .accessibilityHidden(true)
        .hidden()
        .overlay {
          if isPlaying {
            Image(braveSystemName: "leo.pause.filled")
              .transition(playButtonTransition)
          } else {
            Image(braveSystemName: "leo.play.filled")
              .transition(playButtonTransition)
          }
        }
      })
      .toggleStyle(.button)
      .foregroundStyle(.primary)
      .font(.title)
      Spacer()
      Button { } label: {
        Image(braveSystemName: "leo.forward.15")
      }
      Spacer()
      Button { } label: {
        Image(braveSystemName: "leo.end.outline")
      }
    }
    .buttonStyle(.spring(scale: 0.85))
    .imageScale(.large)
    .foregroundStyle(.primary)
    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
  }
}

struct ExtraControls: View {
  @Binding var isShuffleEnabled: Bool
  @Binding var contentSpeed: ContentSpeed
  
  var body: some View {
    HStack {
      Toggle(isOn: $isShuffleEnabled) {
        ZStack {
          Image(braveSystemName: "leo.shuffle.toggle-on")
          Image(braveSystemName: "leo.shuffle.off")
        }
        .accessibilityHidden(true)
        .hidden()
        .overlay {
          if isShuffleEnabled {
            Image(braveSystemName: "leo.shuffle.toggle-on")
              .transition(.opacity.animation(.linear(duration: 0.1)))
          } else {
            Image(braveSystemName: "leo.shuffle.off")
              .transition(.opacity.animation(.linear(duration: 0.1)))
          }
        }
      }
      .toggleStyle(.button)
      Spacer()
      Button {
        contentSpeed.increase()
      } label: {
        switch contentSpeed {
        case .normal:
          Image(braveSystemName: "leo.1x")
            .transition(.opacity.animation(.linear(duration: 0.1)))
        case .fast:
          Image(braveSystemName: "leo.1.5x")
            .transition(.opacity.animation(.linear(duration: 0.1)))
        case .faster:
          Image(braveSystemName: "leo.2x")
            .transition(.opacity.animation(.linear(duration: 0.1)))
        }
      }
      Spacer()
      Button { } label: {
        Image(braveSystemName: "leo.sleep.timer")
      }
      Spacer()
      Button { } label: {
        Image(braveSystemName: "leo.fullscreen.on")
      }
    }
    .buttonStyle(.spring(scale: 0.85))
    .foregroundStyle(.primary)
    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
  }
}

struct MediaScrubber: View {
  @Binding var currentTime: Int /*Duration<Seconds>*/
  var totalDuration: Int /*Duration<Seconds>*/
  @Binding var isScrubbing: Bool
  
  @State private var isShowingTotalTime: Bool = false
  
  @GestureState private var isScrubbingState: Bool = false
  @State private var resumePlayingAfterPan = false
  
  @ScaledMetric private var barHeight = 2
  @ScaledMetric private var thumbSize = 12
  
  @available(iOS, introduced: 14.0, obsoleted: 16.0, message: "Use FormatStyle")
  private var timeFormatter: DateComponentsFormatter {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = [.dropLeading, .pad]
    return formatter
  }
  
  var currentValueLabel: Text {
    if #available(iOS 16.0, *) {
      return Text(Duration.seconds(currentTime), format: .time(pattern: .minuteSecond))
    } else {
      return Text(timeFormatter.string(from: DateComponents(second: currentTime))!)
    }
  }
  
  var remainingTimeLabel: Text {
    if #available(iOS 16.0, *) {
      let value = Duration.seconds(totalDuration - currentTime).formatted(.time(pattern: .minuteSecond))
      return Text("-\(value)")
    } else {
      return Text("-\(timeFormatter.string(from: DateComponents(second: totalDuration - currentTime))!)")
    }
  }
  
  var totalTimeLabel: Text {
    if #available(iOS 16.0, *) {
      return Text(Duration.seconds(totalDuration), format: .time(pattern: .minuteSecond))
    } else {
      return Text(timeFormatter.string(from: DateComponents(second: totalDuration))!)
    }
  }
  
  var body: some View {
    VStack {
      Color.white.opacity(0.3)
        .frame(height: barHeight)
        .clipShape(RoundedRectangle(cornerRadius: barHeight / 2))
        .overlay {
          // Active value
          GeometryReader { proxy in
            Color.white
              .frame(width: min(proxy.size.width, CGFloat(currentTime) / CGFloat(totalDuration) * proxy.size.width), alignment: .leading)
              .clipShape(RoundedRectangle(cornerRadius: barHeight / 2))
              .animation(.linear(duration: 0.1), value: currentTime)
          }
        }
        .padding(.vertical, (thumbSize - barHeight) / 2)
        .overlay {
          // Thumb
          GeometryReader { proxy in
            Color.white
              .clipShape(Circle())
              .shadow(radius: 4)
              .frame(width: thumbSize, height: thumbSize)
              .scaleEffect(isScrubbing ? 1.5 : 1)
              .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isScrubbing)
              .offset(x: min(proxy.size.width, (CGFloat(currentTime) / CGFloat(totalDuration) * proxy.size.width)) - (thumbSize / 2))
              .animation(.linear(duration: 0.1), value: currentTime)
              .gesture(
                DragGesture(minimumDistance: 0)
                  .updating($isScrubbingState, body: { _, state, _ in
                    state = true
                  })
                  .onChanged { state in
                    currentTime = max(0, min(totalDuration, Int((state.location.x / proxy.size.width) * CGFloat(totalDuration))))
                  }
              )
          }
        }
      HStack {
        currentValueLabel
        Spacer()
        Button {
          isShowingTotalTime.toggle()
        } label: {
          Group {
            if isShowingTotalTime {
              totalTimeLabel
            } else {
              remainingTimeLabel
            }
          }
          .transition(.move(edge: .trailing).combined(with: .opacity))
        }
        .tint(.white)
      }
      .font(.footnote)
    }
    .padding(.vertical)
    .onChange(of: isScrubbingState) { newValue in
      isScrubbing = newValue
    }
    .accessibilityRepresentation {
      Slider(
        value: Binding(get: { CGFloat(currentTime) }, set: { currentTime = Int($0) }),
        in: 0.0...CGFloat(totalDuration),
        step: 1
      ) {
        Text("Current Media Time") // TODO: Localize
      } minimumValueLabel: {
        currentValueLabel
      } maximumValueLabel: {
        totalTimeLabel
      }
    }
  }
}

struct VideoControls_PreviewProvider: PreviewProvider {
  static var previews: some View {
    MediaControls(title: "Top 10 things to do with Brave")
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(white: 0.1))
  }
}
