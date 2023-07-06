// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import SwiftUI
import DesignSystem
import Favicon

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

struct ControlView: View {
  var title: String
  var publisherSource: URL?
  
  @State private var currentTime: Int = 68
  @State private var totalDuration: Int = 1008
  @State private var isPlaying: Bool = false
  @State private var isScrubbing: Bool = false
  @State private var isShuffleEnabled: Bool = false
  @State private var contentSpeed: ContentSpeed = .normal
  @State private var stopPlaybackDate: Date?
  @State private var isPlaybackStopInfoPresented: Bool = false
  @State private var resumePlayingAfterScrub: Bool = false
  
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @Environment(\.interfaceOrientation) private var orientation
  
  private var timeFormatter: DateComponentsFormatter {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute, .second]
    formatter.zeroFormattingBehavior = [.dropLeading, .pad]
    return formatter
  }
  
  var body: some View {
    VStack {
      HStack(spacing: 8) {
        Color.white
          .opacity(0.1)
          .frame(width: 20, height: 20)
          .overlay {
            FaviconImage(url: publisherSource)
          }
          .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        Text(title.isEmpty ? "No Item Selected" : title)
          .font(.body.weight(.semibold))
          .opacity(title.isEmpty ? 0 : 1)
          .lineLimit(1)
        Spacer()
        HStack(spacing: 24) {
          if UIDevice.isPhone && orientation.isLandscape {
            Button { } label: {
              Label("Enter Picture-in-Picture", braveSystemImage: "leo.picture.in-picture")
                .labelStyle(.iconOnly)
            }
          }
          Button { } label: {
            Image(braveSystemName: "leo.airplay.video")
          }
        }
        .buttonStyle(.spring(backgroundStyle: Color.white))
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      MediaScrubber(currentTime: $currentTime, totalDuration: totalDuration, isScrubbing: $isScrubbing)
      VStack(spacing: 24) {
        if (UIDevice.isPhone && orientation.isPortrait) || (UIDevice.isIpad && horizontalSizeClass == .compact) {
          HStack {
            PlaybackControls(isPlaying: $isPlaying)
              .imageScale(.large)
          }
          HStack {
            LeadingExtraControls(isShuffleEnabled: $isShuffleEnabled, contentSpeed: $contentSpeed)
            Spacer()
            TrailingExtraControls(stopPlaybackDate: $stopPlaybackDate, isPlaybackStopInfoPresented: $isPlaybackStopInfoPresented)
          }
        } else {
          HStack {
            LeadingExtraControls(isShuffleEnabled: $isShuffleEnabled, contentSpeed: $contentSpeed)
            Spacer()
            PlaybackControls(isPlaying: $isPlaying)
            Spacer()
            TrailingExtraControls(stopPlaybackDate: $stopPlaybackDate, isPlaybackStopInfoPresented: $isPlaybackStopInfoPresented)
          }
        }
      }
      .foregroundStyle(Color.white.opacity(0.75))
      .dynamicTypeSize(...DynamicTypeSize.accessibility3)
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
        currentTime += 1
      }
    })
    .overlayPreferenceValue(SleepTimerBoundsPrefKey.self, { value in
      if isPlaybackStopInfoPresented, let stopPlaybackDate, let value = value.last {
        GeometryReader { proxy in
          HStack {
            Group {
              if #available(iOS 16.0, *) {
                Text(timerInterval: .now...stopPlaybackDate, countsDown: true, showsHours: true)
              } else {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                  Text(timeFormatter.string(from: DateComponents(second: Int(stopPlaybackDate.timeIntervalSince1970 - context.date.timeIntervalSince1970)))!)
                }
              }
            }
            .foregroundStyle(Color(.braveLabel))
            .font(.body.monospacedDigit())
            .padding(.horizontal, 12)
            Button {
              
            } label: {
              Image(braveSystemName: "leo.pause.outline")
            }
            Button {
              self.stopPlaybackDate = nil
              isPlaybackStopInfoPresented = false
            } label: {
              Image(braveSystemName: "leo.close")
            }
          }
          .foregroundStyle(Color(.braveBlurple))
          .padding(8)
          .background(Material.thin)
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
          .position(x: proxy[value].midX, y: proxy[value].midY - (proxy[value].height * 2))
        }
        .background {
          Color.clear
            .contentShape(Rectangle())
            .onTapGesture {
              isPlaybackStopInfoPresented = false
            }
        }
        .transition(.scale(scale: 0.2, anchor: .bottom).combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.7)))
      }
    })
  }
}

private struct SleepTimerBoundsPrefKey: PreferenceKey {
  typealias Value = [Anchor<CGRect>]
  static var defaultValue: Value = []
  static func reduce(value: inout Value, nextValue: () -> Value) {
    value.append(contentsOf: nextValue())
  }
}

struct PlaybackControls: View {
  @Binding var isPlaying: Bool
  
  private var playButtonTransition: AnyTransition {
    .scale.combined(with: .opacity).animation(.spring(response: 0.3, dampingFraction: 0.7))
  }
  
  var body: some View {
    Group {
      Button { } label: {
        Label("Previous Item", braveSystemImage: "leo.start.outline")
      }
      Spacer()
      Button { } label: {
        Label("Step Back", braveSystemImage: "leo.rewind.15")
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
            Label("Pause", braveSystemImage: "leo.pause.filled")
              .labelStyle(.iconOnly)
              .transition(playButtonTransition)
          } else {
            Label("Play", braveSystemImage: "leo.play.filled")
              .labelStyle(.iconOnly)
              .transition(playButtonTransition)
          }
        }
      })
      .toggleStyle(.button)
      .foregroundStyle(Color.white)
      .font(.title)
      Spacer()
      Button { } label: {
        Label("Step Forward", braveSystemImage: "leo.forward.15")
      }
      Spacer()
      Button { } label: {
        Label("Next Item", braveSystemImage: "leo.end.outline")
      }
    }
    .buttonStyle(.spring(scale: 0.85, backgroundStyle: Color.white))
    .labelStyle(.iconOnly)
  }
}

struct LeadingExtraControls: View {
  @Binding var isShuffleEnabled: Bool
  @Binding var contentSpeed: ContentSpeed
  
  var body: some View {
    Group {
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
    }
    .buttonStyle(.spring(scale: 0.85, backgroundStyle: Color.white))
    .labelStyle(.iconOnly)
  }
}

struct TrailingExtraControls: View {
  @Binding var stopPlaybackDate: Date?
  @Binding var isPlaybackStopInfoPresented: Bool
  
  var body: some View {
    Group {
      if let _ = stopPlaybackDate {
        Button {
          isPlaybackStopInfoPresented = true
        } label: {
          Label("Sleep Timer", braveSystemImage: "leo.sleep.timer")
        }
        .anchorPreference(key: SleepTimerBoundsPrefKey.self, value: .bounds, transform: { [$0] })
      } else {
        Menu {
          Section {
            Button {
              stopPlaybackDate = .now.addingTimeInterval(10 * 60)
            } label: {
              Text("10 minutes")
            }
            Button {
              stopPlaybackDate = .now.addingTimeInterval(20 * 60)
            } label: {
              Text("20 minutes")
            }
            Button {
              stopPlaybackDate = .now.addingTimeInterval(30 * 60)
            } label: {
              Text("30 minutes")
            }
            Button {
              stopPlaybackDate = .now.addingTimeInterval(60 * 60)
            } label: {
              Text("1 hour")
            }
          } header: {
            Text("Stop Playback In…")
          }
        } label: {
          Label("Sleep Timer", braveSystemImage: "leo.sleep.timer")
        }
      }
      Spacer()
      Button { } label: {
        Label("Fullscreen", braveSystemImage: "leo.fullscreen.on")
      }
    }
    .buttonStyle(.spring(scale: 0.85, backgroundStyle: Color.white))
    .labelStyle(.iconOnly)
  }
}

struct MediaScrubber: View {
  @Binding var currentTime: Int /*Duration<Seconds>*/
  var totalDuration: Int /*Duration<Seconds>*/
  @Binding var isScrubbing: Bool
  
  @State private var isShowingTotalTime: Bool = false
  
  @GestureState private var isScrubbingState: Bool = false
  
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
      let value = Text(Duration.seconds(totalDuration - currentTime), format: .time(pattern: .minuteSecond))
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

#if DEBUG
struct VideoControls_PreviewProvider: PreviewProvider {
  static var previews: some View {
    ControlView(title: "Blah Bleh a Bluh Blah Blue", publisherSource: nil)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(white: 0.1))
      .observingOrientation()
  }
}
#endif

private struct FaviconImage: View {
  let url: URL?
  @State private var image: UIImage?
  
  init(url: URL?) {
    self.url = url
  }
  
  var body: some View {
    Image(uiImage: image ?? UIImage())
      .resizable()
      .aspectRatio(contentMode: .fit)
      .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
      .task {
        do {
          if let url {
            image = try await FaviconFetcher.loadIcon(url: url, persistent: true).image
          }
        } catch {}
      }
      .id(url)
  }
}
