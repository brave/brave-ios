// Copyright 2022 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import SwiftUI
import CoreData
import Shared
import BraveUI
import DesignSystem
import BraveShared
import Data

private struct PlaylistRedactedHeaderView: View {
  @Observable var title: String?
  @Observable var creatorName: String?
  
  var body: some View {
    HStack(alignment: .center) {
      VStack(alignment: .leading) {
        Text(title ?? "PlaylistTitlePlaceholder" /* Placeholder */)
          .font(.title3)
          .fontWeight(.medium)
          .foregroundColor(Color(.bravePrimary))
          .multilineTextAlignment(.leading)
          .redacted(reason: title == nil ? .placeholder : [])
          .shimmer(title == nil)
        
        Text(creatorName ?? "CreatorName" /* Placeholder */)
          .font(.footnote)
          .foregroundColor(Color(.braveLabel))
          .multilineTextAlignment(.leading)
          .redacted(reason: creatorName == nil ? .placeholder : [])
          .shimmer(creatorName == nil)
      }
      
      Spacer()
      
      Button("+ Add" /* Placeholder */, action: {})
        .buttonStyle(BraveFilledButtonStyle(size: .normal))
        .disabled(true)
        .redacted(reason: .placeholder)
        .shimmer(true)
    }
    .padding()
    .frame(height: 80.0, alignment: .center)
    .background(Color(.braveBackground))
    .environment(\.colorScheme, .dark)
  }
}

private struct PlaylistCellRedactedView: View {
  @Observable var thumbnail: UIImage?
  @Observable var title: String?
  @Observable var subtitle: String?
  
  var body: some View {
    HStack(alignment: .center) {
      Image(uiImage: UIImage())
        .resizable()
        .background(Color.black)
        .frame(width: 64.0 * 1.47, height: 64.0, alignment: .center)
        .aspectRatio(contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 5.0, style: .continuous))
        .overlay(
          VStack {
            Image(uiImage: thumbnail ?? UIImage())
              .resizable()
              .aspectRatio(1.0, contentMode: .fit)
              .clipShape(RoundedRectangle(cornerRadius: 3.0, style: .continuous))
          }.padding(), alignment: .center
        )
        .shimmer(thumbnail == nil)
      
      VStack(alignment: .leading) {
        Text(title ?? "Placeholder Title - Placeholder Title Longer")
          .font(.callout)
          .fontWeight(.medium)
          .foregroundColor(Color(.bravePrimary))
          .multilineTextAlignment(.leading)
          .redacted(reason: title == nil ? .placeholder : [])
          .shimmer(title == nil)
        
        Text(subtitle ?? "Placeholder SubTitle")
          .font(.callout)
          .foregroundColor(Color(.bravePrimary))
          .multilineTextAlignment(.leading)
          .redacted(reason: subtitle == nil ? .placeholder : [])
          .shimmer(subtitle == nil)
        
        if subtitle == nil {
          Text("00:00")
            .font(.footnote)
            .foregroundColor(Color(.secondaryBraveLabel))
            .multilineTextAlignment(.leading)
            .redacted(reason: .placeholder)
            .shimmer(true)
        }
      }
      
      Spacer()
    }
    .padding()
    .frame(height: 80.0, alignment: .center)
    .background(Color(.braveBackground))
    .environment(\.colorScheme, .dark)
  }
}

class PlaylistRedactedHeader: UITableViewHeaderFooterView {
  private let hostingController = UIHostingController(rootView: PlaylistRedactedHeaderView())
  
  override init(reuseIdentifier: String?) {
    super.init(reuseIdentifier: reuseIdentifier)
    
    contentView.addSubview(hostingController.view)
    hostingController.view.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func setTitle(title: String?) {
    hostingController.rootView.title = title
  }
  
  func setCreatorName(creatorName: String?) {
    hostingController.rootView.creatorName = creatorName
  }
}

class PlaylistCellRedacted: UITableViewCell {
  private var faviconRenderer: FavIconImageRenderer?
  private let hostingController = UIHostingController(rootView: PlaylistCellRedactedView())
  
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    
    contentView.addSubview(hostingController.view)
    hostingController.view.snp.makeConstraints {
      $0.edges.equalToSuperview()
    }
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  func loadThumbnail(for url: URL) {
    faviconRenderer = FavIconImageRenderer()
    faviconRenderer?.loadIcon(siteURL: url, persistent: false) { [weak self] image in
      self?.hostingController.rootView.thumbnail = image
    }
  }
  
  func setTitle(title: String?) {
    hostingController.rootView.title = title
  }
  
  func setSubtitle(subtitle: String?) {
    hostingController.rootView.subtitle = subtitle
  }
}
