// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import WidgetKit
import SwiftUI
import Intents
import Shared
import BraveShared
import BraveUI

struct StatWidget: Widget {
    let kind: String = "StatWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: StatsConfigurationIntent.self, provider: StatProvider()) { entry in
            StatView(entry: entry)
        }
        .supportedFamilies([.systemSmall])
        .configurationDisplayName("Privacy Stat")
        .description("Displays a single privacy stat")
    }
}

struct StatEntry: TimelineEntry {
    var date: Date
    var statData: StatData
}

struct StatProvider: IntentTimelineProvider {
    typealias Intent = StatsConfigurationIntent
    typealias Entry = StatEntry
    
    func placeholder(in context: Context) -> Entry {
        StatEntry(date: Date(), statData: .init(name: "Placeholder Count", value: "100k"))
    }
    func getSnapshot(for configuration: Intent, in context: Context, completion: @escaping (Entry) -> Void) {
        let stat = configuration.statKind
        let entry = StatEntry(date: Date(), statData: .init(name: stat.name, value: stat.displayString, color: stat.valueColor))
        completion(entry)
    }
    func getTimeline(for configuration: Intent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let stat = configuration.statKind
        let entry = StatEntry(date: Date(), statData: .init(name: stat.name, value: stat.displayString, color: stat.valueColor))
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct PlaceholderStatView: View {
    var entry: StatEntry
    
    var body: some View {
        StatView(entry: entry)
            .redacted(reason: .placeholder)
    }
}

struct StatView: View {
    var entry: StatEntry
    
    @ScaledMetric private var fontSize: CGFloat = 40
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Spacer()
                Image("brave-icon-no-bg")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 24)
                    .unredacted()
            }
            Spacer()
            Text(verbatim: entry.statData.value)
                .font(.system(size: fontSize))
                .foregroundColor(Color(entry.statData.color))
            Text(verbatim: entry.statData.name)
                .font(.caption)
                .bold()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(red: 0.133, green: 0.145, blue: 0.161))
        .foregroundColor(Color(red: 0.761, green: 0.769, blue: 0.808))
    }
}

// MARK: - Previews

struct StatWidget_Previews: PreviewProvider {
    static var previews: some View {
        StatView(entry: StatEntry(date: Date(), statData: .init(name: "Ads & Trackers Blocked", value: "100k", color: UIColor.braveOrange)))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
        StatView(entry: StatEntry(date: Date(), statData: .init(name: "Placeholder Count", value: "100k", color: UIColor.braveOrange)))
            .redacted(reason: .placeholder)
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
