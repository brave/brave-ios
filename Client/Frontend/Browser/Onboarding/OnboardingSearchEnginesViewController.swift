// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import UIKit
import BraveShared
import Shared

private let log = Logger.browserLogger

class OnboardingSearchEnginesViewController: OnboardingViewController {
    
    let searchEngines: SearchEngines
    
    private var contentView: View {
        return view as! View // swiftlint:disable:this force_cast
    }
    
    override func loadView() {
        view = View()
    }
    
    override init(profile: Profile) {
        self.searchEngines = profile.searchEngines
        super.init(profile: profile)
        
        //super.init(nibName: nil, bundle: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView.searchEnginesTable.dataSource = self
        contentView.searchEnginesTable.delegate = self
        
        contentView.continueButton.addTarget(self, action: #selector(continueTapped), for: .touchDown)
        contentView.skipButton.addTarget(self, action: #selector(skipTapped), for: .touchDown)
    }
    
    @objc override func continueTapped() {
        guard let selectedRow = contentView.searchEnginesTable.indexPathForSelectedRow?.row,
            let selectedEngine = searchEngines.orderedEngines[safe: selectedRow]?.shortName else {
                return
            log.error("Failed to unwrap selected row or selected engine.")
        }
        
        searchEngines.setDefaultEngine(selectedEngine, forType: .standard)
        searchEngines.setDefaultEngine(selectedEngine, forType: .privateMode)
        
        delegate?.presentNextScreen(current: self)
    }
    
}

extension OnboardingSearchEnginesViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return SearchEngineCell.preferredHeight
    }
}

extension OnboardingSearchEnginesViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchEngines.orderedEngines.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = SearchEngineCell()
        
        guard let searchEngine = searchEngines.orderedEngines[safe: indexPath.row] else {
            log.error("Can't find search engine at index: \(indexPath.row)")
            assertionFailure()
            return cell
        }
        
        let defaultEngine = searchEngines.defaultEngine()
        
        cell.searchEngineName = searchEngine.shortName
        cell.searchEngineImage = searchEngine.image
        
        if searchEngine == defaultEngine {
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        }
        
        return cell
    }
}
