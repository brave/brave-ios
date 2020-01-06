// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import UIKit
import PDFKit

public class PDFViewer: UIView, PDFDocumentDelegate {
    private var currentPage = 0
    private var document: PDFDocument!
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
    private let pageView = PDFView()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        layoutViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func loadPdf(url: URL) {
        self.document = PDFDocument(url: url)!
        self.document.delegate = self
        pageView.displayMode = .singlePageContinuous
        pageView.displayDirection = .vertical
        pageView.autoScales = true
        pageView.document = document
        pageView.minScaleFactor = pageView.scaleFactorForSizeToFit
        pageView.maxScaleFactor = 3.0
    }
    
    public func loadPdf(data: Data) {
        self.document = PDFDocument(data: data)!
        self.document.delegate = self
        pageView.displayMode = .singlePageContinuous
        pageView.displayDirection = .vertical
        pageView.autoScales = true
        pageView.document = document
        pageView.minScaleFactor = pageView.scaleFactorForSizeToFit
        pageView.maxScaleFactor = 3.0
    }
    
    public func beginFinding(_ string: String) {
        document.cancelFindString()
        document.beginFindString(string, withOptions: .caseInsensitive)
    }
    
    public func endFinding() {
        document.cancelFindString()
    }
    
    private func findString(_ string: String) -> [PDFSelection] {
        return document.findString(string, withOptions: .caseInsensitive)
    }
    
    private func goToAndHighlightSelection(_ selection: PDFSelection?) {
        pageView.setCurrentSelection(selection, animate: true)
        
        selection?.color = .yellow
        pageView.highlightedSelections = [selection!]
        if let selection = selection {
            pageView.go(to: selection)
        }
    }
    
    private func highlight(_ searchTerms: [String]?) {
        if let searchTerms = searchTerms {
            searchTerms.forEach { term in
                let selections = document.findString(term, withOptions: [.caseInsensitive])
                selections.forEach({ $0.color = .yellow })
                pageView.highlightedSelections = selections
            }
        } else {
            pageView.highlightedSelections = nil
        }
    }
    
    private func layoutViews() {
        addSubview(blurView)
        addSubview(pageView)
        
        blurView.snp.makeConstraints({
            $0.edges.equalTo(self.snp.edges)
        })
        
        pageView.snp.makeConstraints({
            $0.edges.equalTo(self.snp.edges)
        })
    }
    
    private func thumbnail(for pageIndex: Int, size: CGSize) -> UIImage? {
        if let page = document.page(at: pageIndex) {
            return page.thumbnail(of: CGSize(width: size.width, height: size.height), for: .artBox)
        }
        return nil
    }
    
    // MARK: - Delegate
    private var searchFind = [PDFSelection]()
    
    public func didMatchString(_ instance: PDFSelection) {
        instance.color = .yellow
        searchFind.append(instance)
    }
    
    public func documentDidBeginDocumentFind(_ notification: Notification) {
        searchFind = []
    }
    
    public func documentDidEndDocumentFind(_ notification: Notification) {
        pageView.highlightedSelections = searchFind.isEmpty ? nil : searchFind
    }
}

