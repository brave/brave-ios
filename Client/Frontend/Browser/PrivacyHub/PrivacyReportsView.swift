/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftUI

struct PrivacyReportsView: View {
  
  let lastWeekMostFrequentTracker: (String, Int)?
  let lastWeekRiskiestWebsite: (String, Int)?
  let allTimeMostFrequentTracker: (String, Int)?
  let allTimeRiskiestWebsite: (String, Int)?
  
  var noData: Bool {
    return lastWeekMostFrequentTracker == nil
    && lastWeekRiskiestWebsite == nil
    && allTimeMostFrequentTracker == nil
    && allTimeRiskiestWebsite == nil
  }
  
  var body: some View {
    NavigationView {
      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: 16) {
          VStack {
            HStack(alignment: .top) {
              HStack {
                Image(systemName: "globe")
                Text("Get weekly privacy updates on tracker & ad blocking.")
                  .font(.headline)
              }
              Spacer()
              Image(systemName: "xmark")
            }
            .frame(maxWidth: .infinity)
            
            
            Button(action: {
              
            }, label: {
              Label("Turn on noticications", systemImage: "bell")
                .font(.callout)
            })
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
            // FIXME: This is iOS 15 only
            // .background(.ultraThinMaterial)
              .clipShape(Capsule())
          }
          .padding()
          .foregroundColor(Color.white)
          
          // FIXME: This is iOS 15 only
          .background(
            LinearGradient(
              gradient:
                Gradient(colors: [.init(.braveBlurple),
                                  .init(.braveInfoLabel)]),
              startPoint: .topLeading, endPoint: .bottomTrailing)
          )
          .cornerRadius(15)
          
          if noData {
            HStack {
              Image(systemName: "info.circle.fill")
              Text("Visit some websites to see data here.")
            }
            .foregroundColor(Color.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.braveInfoLabel))
            .cornerRadius(15)
          }
          
          VStack(alignment: .leading, spacing: 8) {
            Text("LAST WEEK")
              .font(.footnote.weight(.medium))
            
            HStack {
              Image(systemName: "hand.thumbsdown")
              VStack(alignment: .leading) {
                Text("MOST FREQUENT TRACKED & AD")
                  .font(.caption)
                  .foregroundColor(.init(.secondaryBraveLabel))
                if let lastWeekMostFrequentTracker = lastWeekMostFrequentTracker {
                  Group {
                    Text(lastWeekMostFrequentTracker.0)
                      .fontWeight(.medium) +
                    Text(" was blocked by Brave Shields on ") +
                    Text("\(lastWeekMostFrequentTracker.1)")
                      .fontWeight(.medium) +
                    Text(" times")
                  }
                  .font(.callout)
                  
                } else {
                  Text("No data to show yet.")
                    .foregroundColor(.init(.secondaryBraveLabel))
                }
              }
              Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.braveBackground))
            .cornerRadius(15)
            
            HStack {
              Image(systemName: "exclamationmark.triangle")
              VStack(alignment: .leading) {
                
                if let lastWeekRiskiestWebsite = lastWeekRiskiestWebsite {
                  Group {
                    Text(lastWeekRiskiestWebsite.0)
                      .fontWeight(.medium) +
                    Text(" had an average of ") +
                    Text("\(lastWeekRiskiestWebsite.1)")
                      .fontWeight(.medium) +
                    Text(" trackers & ads blocked per visit")
                  }
                  .font(.callout)
                } else {
                  Text("RISKIEST WEBSITE YOU VISITED")
                    .font(.caption)
                    .foregroundColor(Color(.secondaryBraveLabel))
                  Text("No data to show yet.")
                    .foregroundColor(Color(.secondaryBraveLabel))
                }
              }
              
              Spacer()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.braveBackground))
            .cornerRadius(15)
          }
          .fixedSize(horizontal: false, vertical: true)
          
          Divider()
          VStack(alignment: .leading, spacing: 8) {
            Text("ALL TIME")
              .font(.footnote.weight(.medium))
            
            HStack(spacing: 12) {
              VStack {
                Text("TRACKER & AD")
                  .font(.caption)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .foregroundColor(Color(.secondaryBraveLabel))
                
                if let allTimeMostFrequentTracker = allTimeMostFrequentTracker {
                  VStack(alignment: .leading) {
                    Text(allTimeMostFrequentTracker.0)
                    Text("\(allTimeMostFrequentTracker.1) sites")
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .font(.subheadline)
                  
                } else {
                  Text("No data to show yet.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryBraveLabel))
                }
              }
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color(.braveBackground))
              .cornerRadius(15)
              
              VStack {
                Text("WEBSITE")
                  .font(.caption)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .foregroundColor(Color(.secondaryBraveLabel))
                
                if let allTimeRiskiestWebsite = allTimeRiskiestWebsite {
                  VStack(alignment: .leading) {
                    Text(allTimeRiskiestWebsite.0)
                    Text("\(allTimeRiskiestWebsite.1) sites")
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .font(.subheadline)
                  
                } else {
                  Text("No data to show yet.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.subheadline)
                    .foregroundColor(Color(.secondaryBraveLabel))
                }
              }
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color(.braveBackground))
              .cornerRadius(15)
            }
          }
          .fixedSize(horizontal: false, vertical: true)
          
          Button(action: {
            
          }) {
            NavigationLink(destination: PrivacyReportAllTimeListsView()) {
              HStack {
                Text("All time lists")
                Image(systemName: "arrow.right")
              }
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .foregroundColor(Color(.braveLabel))
          }
          .overlay(
            RoundedRectangle(cornerRadius: 25)
              .stroke(Color(.braveLabel), lineWidth: 1))
          
          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .navigationTitle("Privacy report")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing, content: {
            Image(systemName: "xmark.circle.fill")
          })
        }
      }
      .background(Color(.secondaryBraveBackground))
    }
  }
}

#if DEBUG
struct PrivacyReports_Previews: PreviewProvider {
  static var previews: some View {
    let lastWeekMostFrequentTracker = ("google-analytics", 133)
    let lastWeekRiskiestWebsite = ("example.com", 13)
    let allTimeMostFrequentTracker = ("scary-analytics", 678)
    let allTimeRiskiestWebsite = ("scary.example.com", 554)
    
    Group {
      ContentView(lastWeekMostFrequentTracker: lastWeekMostFrequentTracker, lastWeekRiskiestWebsite: lastWeekRiskiestWebsite, allTimeMostFrequentTracker: allTimeMostFrequentTracker, allTimeRiskiestWebsite: allTimeRiskiestWebsite)
      ContentView(lastWeekMostFrequentTracker: lastWeekMostFrequentTracker, lastWeekRiskiestWebsite: lastWeekRiskiestWebsite, allTimeMostFrequentTracker: allTimeMostFrequentTracker, allTimeRiskiestWebsite: allTimeRiskiestWebsite)
        .preferredColorScheme(.dark)
    }
  }
}
#endif
