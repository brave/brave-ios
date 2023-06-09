// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import DesignSystem

struct VideoControls: View {
  var title: String
  
  @State private var value: Int = 68
  @State private var isPlaying: Bool = false
  @State private var isShuffleEnabled: Bool = false
  
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
      MediaScrubber(progress: $value, total: 1008)
      VStack(spacing: 24) {
        PlaybackControls(isPlaying: $isPlaying)
        ExtraControls(isShuffleEnabled: $isShuffleEnabled)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.horizontal, 24)
    .colorScheme(.dark)
    .onReceive(Timer.publish(every: 1, on: .main, in: .default).autoconnect(), perform: { _ in
      value += 1
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
    .foregroundStyle(.secondary)
    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
  }
}

struct ExtraControls: View {
  @Binding var isShuffleEnabled: Bool
  
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
      Menu {
        Button("1x") { }
        Button("2x") { }
        Button("4x") { }
      } label: {
        Image(braveSystemName: "leo.1x")
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
    .foregroundStyle(.secondary)
    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
  }
}

struct MediaScrubber: View {
  @Binding var progress: Int
  var total: Int
  
  @State private var isShowingTotalTime: Bool = false
  
  @GestureState private var isPanning: Bool = false
  
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
      return Text(Duration.seconds(progress), format: .time(pattern: .minuteSecond))
    } else {
      return Text(timeFormatter.string(from: DateComponents(second: progress))!)
    }
  }
  
  var remainingTimeLabel: Text {
    if #available(iOS 16.0, *) {
      let value = Duration.seconds(total - progress).formatted(.time(pattern: .minuteSecond))
      return Text("-\(value)")
    } else {
      return Text("-\(timeFormatter.string(from: DateComponents(second: total - progress))!)")
    }
  }
  
  var totalTimeLabel: Text {
    if #available(iOS 16.0, *) {
      return Text(Duration.seconds(total), format: .time(pattern: .minuteSecond))
    } else {
      return Text(timeFormatter.string(from: DateComponents(second: total))!)
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
              .frame(width: CGFloat(progress) / CGFloat(total) * proxy.size.width, alignment: .leading)
              .clipShape(RoundedRectangle(cornerRadius: barHeight / 2))
              .animation(.linear(duration: 0.1), value: progress)
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
              .scaleEffect(isPanning ? 1.5 : 1)
              .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPanning)
              .offset(x: (CGFloat(progress) / CGFloat(total) * proxy.size.width) - (thumbSize / 2))
              .animation(.linear(duration: 0.1), value: progress)
              .gesture(
                DragGesture(minimumDistance: 0)
                  .updating($isPanning, body: { _, state, _ in
                    state = true
                  })
                  .onChanged { state in
                    progress = max(0, min(total, Int((state.location.x / proxy.size.width) * CGFloat(total))))
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
    .accessibilityRepresentation {
      Slider(
        value: Binding(get: { CGFloat(progress) }, set: { progress = Int($0) }),
        in: 0.0...CGFloat(total),
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
    VideoControls(title: "Top 10 things to do with Brave")
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(white: 0.1))
  }
}
