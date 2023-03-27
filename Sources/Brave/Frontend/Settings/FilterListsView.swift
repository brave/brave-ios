// Copyright 2023 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import Strings
import Data
import DesignSystem
import BraveUI

/// A view showing enabled and disabled community filter lists
struct FilterListsView: View {
  @ObservedObject private var filterListDownloader = FilterListResourceDownloader.shared
  
  var body: some View {
    List {
      Section {
        ForEach($filterListDownloader.filterLists) { $filterList in
          Toggle(isOn: $filterList.isEnabled) {
            VStack(alignment: .leading) {
              Text(filterList.entry.title)
                .foregroundColor(Color(.bravePrimary))
              Text(filterList.entry.desc)
                .font(.caption)
                .foregroundColor(Color(.secondaryBraveLabel))
            }
          }.toggleStyle(SwitchToggleStyle(tint: .accentColor))
            .listRowBackground(Color(.secondaryBraveGroupedBackground))
        }
      } header: {
        Text(Strings.filterListsDescription)
          .textCase(.none)
      }
      
    }
    .listBackgroundColor(Color(UIColor.braveGroupedBackground))
    .navigationTitle(Strings.filterLists)
  }
}

#if DEBUG
struct FilterListsView_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      FilterListsView()
    }
    .previewLayout(.sizeThatFits)
  }
}
#endif
