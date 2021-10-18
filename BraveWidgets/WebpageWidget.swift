// Copyright 2020 The Brave Authors. All rights reserved.
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import WidgetKit
import SwiftUI
import WebKit

struct WebpageWidgetEntry: TimelineEntry {
    var date: Date
    var title: String?
    var url: String
    var image: UIImage?
}

let previewURL = URL(string: "https://www.brave.com")!

struct WebpageWidgetProvider: TimelineProvider {
    typealias Entry = WebpageWidgetEntry
    func getSnapshot(in context: Context, completion: @escaping (WebpageWidgetEntry) -> Void) {
        pageHandler.image(for: previewURL, size: context.displaySize) { image, title in
            completion(.init(date: Date(), title: title, url: previewURL.absoluteString, image: image))
        }
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WebpageWidgetEntry>) -> Void) {
        pageHandler.image(for: previewURL, size: context.displaySize) { image, title in
            completion(.init(entries: [.init(date: Date(), title: title, url: previewURL.absoluteString, image: image)], policy: .never))
        }
    }
    func placeholder(in context: Context) -> WebpageWidgetEntry {
        .init(date: Date(), title: "", url: "", image: nil)
    }
    
    private let pageHandler = PageHandler()
}

private class PageHandler: NSObject, WKNavigationDelegate {
    var webView: WKWebView?
    var finished: ((UIImage?, String?) -> Void)?
    var size: CGSize = .zero

    func image(for url: URL, size: CGSize, completion: @escaping (UIImage?, String?) -> Void) {
        self.size = size
        self.finished = completion
        let webView = WKWebView(frame: CGRect(size: size))
        webView.navigationDelegate = self
        webView.load(URLRequest(url: url))
        self.webView = webView
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
//        let config = WKSnapshotConfiguration()
//        config.rect = CGRect(size: size)
        webView.takeSnapshot(with: nil) { [weak self] image, error in
            self?.finished?(image, webView.title)
        }
    }
}

struct WebpageWidgetView: View {
    var entry: WebpageWidgetEntry
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(alignment: .leading) {
                if let title = entry.title {
                    Text(verbatim: title)
                        .font(.footnote)
                        .bold()
                        .lineLimit(1)
                        .foregroundColor(.primary)
                }
                //                    Text(verbatim: entry.url)
                //                        .font(.footnote)
                //                        .foregroundColor(.secondary)
                //                        .lineLimit(1)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground)
                            .clipShape(ContainerRelativeShape())
                            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1))
            .overlay(ContainerRelativeShape().strokeBorder(Color.black.opacity(0.1)))
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            Group {
                if let image = entry.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    EmptyView()
                }
            }
        )
    }
}

struct WebpageWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WebpageWidget", provider: WebpageWidgetProvider(), content: { entry in
            WebpageWidgetView(entry: entry)
        })
        .configurationDisplayName("Webpage Preview")
        .description("Display a preview of a web page")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct WebpageWidget_Previews: PreviewProvider {
    static var previews: some View {
        WebpageWidgetView(
            entry: .init(date: Date(), title: "Issues · brave/brave-ios", url: "https://github.com/brave/brave-ios/issues", image: UIImage())
        )
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
