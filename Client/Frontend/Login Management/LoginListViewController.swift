/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import SnapKit
import Storage
import Shared
import SwiftKeychainWrapper

private struct LoginListUX {
    static let rowHeight: CGFloat = 58
    static let searchHeight: CGFloat = 58
    static let selectionButtonFont = UIFont.systemFont(ofSize: 16)
    static let selectionButtonTextColor = UIColor.Photon.white100
    static let selectionButtonBackground = UIConstants.highlightBlue
    static let noResultsFont: UIFont = UIFont.systemFont(ofSize: 16)
    static let noResultsTextColor: UIColor = UIColor.Photon.grey40
}

private extension UITableView {
    var allIndexPaths: [IndexPath] {
        return (0..<self.numberOfSections).flatMap { sectionNum in
            (0..<self.numberOfRows(inSection: sectionNum)).map { IndexPath(row: $0, section: sectionNum) }
        }
    }
}

private let LoginCellIdentifier = "LoginCell"

class LoginListViewController: UIViewController {

    fileprivate lazy var loginSelectionController: ListSelectionController = {
        return ListSelectionController(tableView: self.tableView)
    }()

    fileprivate lazy var loginDataSource: LoginDataSource = {
        let dataSource = LoginDataSource()
        dataSource.dataObserver = self
        return dataSource
    }()

    fileprivate let profile: Profile

    fileprivate let searchView = SearchInputView()

    fileprivate var activeLoginQuery: Deferred<Maybe<[Login]>>?

    fileprivate let loadingStateView = LoadingLoginsView()

    fileprivate var deleteAlert: UIAlertController?

    fileprivate lazy var selectionButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = LoginListUX.selectionButtonFont
        button.setTitle(Strings.loginListSelectAllButtonTitle, for: [])
        button.setTitleColor(LoginListUX.selectionButtonTextColor, for: [])
        button.backgroundColor = LoginListUX.selectionButtonBackground
        button.addTarget(self, action: #selector(tappedSelectionButton), for: .touchUpInside)
        return button
    }()

    fileprivate var selectionButtonHeightConstraint: Constraint?
    fileprivate var selectedIndexPaths = [IndexPath]()

    fileprivate let tableView = UITableView()
    
    weak var settingsDelegate: SettingsDelegate?

    init(profile: Profile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(remoteLoginsDidChange), name: .dataRemoteLoginChangesWereApplied, object: nil)
        notificationCenter.addObserver(self, selector: #selector(dismissAlertController), name: UIApplication.didEnterBackgroundNotification, object: nil)

        tableView.contentInsetAdjustmentBehavior = .never

        self.view.backgroundColor = UIColor.Photon.white100
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(beginEditing))

        self.title = Strings.loginListScreenTitle

        searchView.delegate = self
        tableView.register(LoginTableViewCell.self, forCellReuseIdentifier: LoginCellIdentifier)

        view.addSubview(searchView)
        view.addSubview(tableView)
        view.addSubview(loadingStateView)
        view.addSubview(selectionButton)

        loadingStateView.isHidden = true

        searchView.snp.makeConstraints { make in
            make.top.equalTo(view.safeArea.top)
            make.leading.trailing.equalTo(self.view)
            make.height.equalTo(LoginListUX.searchHeight)
        }

        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchView.snp.bottom)
            make.leading.trailing.equalTo(self.view)
            make.bottom.equalTo(self.selectionButton.snp.top)
        }

        selectionButton.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalTo(self.view)
            make.top.equalTo(self.tableView.snp.bottom)
            make.bottom.equalTo(self.view)
            selectionButtonHeightConstraint = make.height.equalTo(0).constraint
        }

        loadingStateView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.accessibilityIdentifier = "Login List"
        tableView.dataSource = loginDataSource
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.delegate = self
        tableView.tableFooterView = UIView()

        KeyboardHelper.defaultHelper.addDelegate(self)

        searchView.isEditing ? loadLogins(searchView.inputField.text) : loadLogins()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.loginDataSource.emptyStateView.searchBarHeight = searchView.frame.height
        self.loadingStateView.searchBarHeight = searchView.frame.height
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    fileprivate func toggleDeleteBarButton() {
        // Show delete bar button item if we have selected any items
        if loginSelectionController.selectedCount > 0 {
            if navigationItem.rightBarButtonItem == nil {
                navigationItem.rightBarButtonItem = UIBarButtonItem(title: Strings.deleteLoginButtonTitle, style: .plain, target: self, action: #selector(tappedDelete))
                navigationItem.rightBarButtonItem?.tintColor = UIColor.Photon.red50
            }
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    fileprivate func toggleSelectionTitle() {
        if loginSelectionController.selectedCount == loginDataSource.count {
            selectionButton.setTitle(Strings.loginListDeselectAllButtonTitle, for: [])
        } else {
            selectionButton.setTitle(Strings.loginListSelectAllButtonTitle, for: [])
        }
    }

    // Wrap the SQLiteLogins method to allow us to cancel it from our end.
    fileprivate func queryLogins(_ query: String) -> Deferred<Maybe<[Login]>> {
        let deferred = Deferred<Maybe<[Login]>>()
        profile.logins.searchLoginsWithQuery(query) >>== { logins in
            deferred.fillIfUnfilled(Maybe(success: logins.asArray()))
            succeed()
        }
        return deferred
    }
}

// MARK: - Selectors
private extension LoginListViewController {
    @objc func remoteLoginsDidChange() {
        DispatchQueue.main.async {
            self.loadLogins()
        }
    }

    @objc func dismissAlertController() {
        self.deleteAlert?.dismiss(animated: false, completion: nil)
    }

    func loadLogins(_ query: String? = nil) {
        loadingStateView.isHidden = false

        // Fill in an in-flight query and re-query
        activeLoginQuery?.fillIfUnfilled(Maybe(success: []))
        activeLoginQuery = queryLogins(query ?? "")
        activeLoginQuery! >>== self.loginDataSource.setLogins
    }

    @objc func beginEditing() {
        navigationItem.rightBarButtonItem = nil
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelSelection))
        selectionButtonHeightConstraint?.update(offset: UIConstants.toolbarHeight)
        self.view.layoutIfNeeded()
        tableView.setEditing(true, animated: true)
    }

    @objc func cancelSelection() {
        // Update selection and select all button
        loginSelectionController.deselectAll()
        toggleSelectionTitle()
        selectionButtonHeightConstraint?.update(offset: 0)
        self.view.layoutIfNeeded()

        tableView.setEditing(false, animated: true)
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(beginEditing))
    }

    @objc func tappedDelete() {
        profile.logins.hasSyncedLogins().uponQueue(.main) { yes in
            self.deleteAlert = UIAlertController.deleteLoginAlertWithDeleteCallback({ [unowned self] _ in
                // Delete here
                let guidsToDelete = self.loginSelectionController.selectedIndexPaths.map { indexPath in
                    self.loginDataSource.loginAtIndexPath(indexPath)!.guid
                }

                self.profile.logins.removeLoginsWithGUIDs(guidsToDelete).uponQueue(.main) { _ in
                    self.cancelSelection()
                    self.loadLogins()
                }
            }, hasSyncedLogins: yes.successValue ?? true)

            self.present(self.deleteAlert!, animated: true, completion: nil)
        }
    }

    @objc func tappedSelectionButton() {
        // If we haven't selected everything yet, select all
        if loginSelectionController.selectedCount < loginDataSource.count {
            // Find all unselected indexPaths
            let unselectedPaths = tableView.allIndexPaths.filter { indexPath in
                return !loginSelectionController.indexPathIsSelected(indexPath)
            }
            loginSelectionController.selectIndexPaths(unselectedPaths)
            unselectedPaths.forEach { indexPath in
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            }
        }

        // If everything has been selected, deselect all
        else {
            loginSelectionController.deselectAll()
            tableView.allIndexPaths.forEach { indexPath in
                self.tableView.deselectRow(at: indexPath, animated: true)
            }
        }

        toggleSelectionTitle()
        toggleDeleteBarButton()
    }
}

// MARK: - LoginDataSourceObserver
extension LoginListViewController: LoginDataSourceObserver {
    func loginSectionsDidUpdate() {
        loadingStateView.isHidden = true
        tableView.reloadData()
        activeLoginQuery = nil
        navigationItem.rightBarButtonItem?.isEnabled = loginDataSource.count > 0
        restoreSelectedRows()
    }
    
    func restoreSelectedRows() {
        for path in self.loginSelectionController.selectedIndexPaths {
            tableView.selectRow(at: path, animated: false, scrollPosition: .none)
        }
    }
}

// MARK: - UITableViewDelegate
extension LoginListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // Force the headers to be hidden
        return 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return LoginListUX.rowHeight
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            loginSelectionController.selectIndexPath(indexPath)
            toggleSelectionTitle()
            toggleDeleteBarButton()
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            let login = loginDataSource.loginAtIndexPath(indexPath)!
            let detailViewController = LoginDetailViewController(profile: profile, login: login)
            detailViewController.settingsDelegate = settingsDelegate
            navigationController?.pushViewController(detailViewController, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            loginSelectionController.deselectIndexPath(indexPath)
            toggleSelectionTitle()
            toggleDeleteBarButton()
        }
    }
}

// MARK: - KeyboardHelperDelegate
extension LoginListViewController: KeyboardHelperDelegate {

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillShowWithState state: KeyboardState) {
        let coveredHeight = state.intersectionHeightForView(tableView)
        tableView.contentInset.bottom = coveredHeight
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardDidShowWithState state: KeyboardState) {
    }

    func keyboardHelper(_ keyboardHelper: KeyboardHelper, keyboardWillHideWithState state: KeyboardState) {
        tableView.contentInset.bottom = 0
    }
}

// MARK: - SearchInputViewDelegate
extension LoginListViewController: SearchInputViewDelegate {

    @objc func searchInputView(_ searchView: SearchInputView, didChangeTextTo text: String) {
        loadLogins(text)
    }

    @objc func searchInputViewBeganEditing(_ searchView: SearchInputView) {
        // Trigger a cancel for editing
        cancelSelection()

        // Hide the edit button while we're searching
        navigationItem.rightBarButtonItem = nil
        loadLogins()
    }

    @objc func searchInputViewFinishedEditing(_ searchView: SearchInputView) {
        // Show the edit after we're done with the search
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(beginEditing))
        loadLogins()
    }
}

/// Controller that keeps track of selected indexes
fileprivate class ListSelectionController: NSObject {

    fileprivate unowned let tableView: UITableView

    var selectedIndexPaths = [IndexPath]()

    var selectedCount: Int {
        return selectedIndexPaths.count
    }

    init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
    }

    func selectIndexPath(_ indexPath: IndexPath) {
        selectedIndexPaths.append(indexPath)
    }

    func indexPathIsSelected(_ indexPath: IndexPath) -> Bool {
        return selectedIndexPaths.contains(indexPath) { path1, path2 in
            return path1.row == path2.row && path1.section == path2.section
        }
    }

    func deselectIndexPath(_ indexPath: IndexPath) {
        guard let foundSelectedPath = (selectedIndexPaths.filter { $0.row == indexPath.row && $0.section == indexPath.section }).first,
            let indexToRemove = selectedIndexPaths.firstIndex(of: foundSelectedPath) else {
            return
        }

        selectedIndexPaths.remove(at: indexToRemove)
    }

    func deselectAll() {
        selectedIndexPaths.removeAll()
    }

    func selectIndexPaths(_ indexPaths: [IndexPath]) {
        selectedIndexPaths += indexPaths
    }
}

protocol LoginDataSourceObserver: class {
    func loginSectionsDidUpdate()
}

/// Data source for handling LoginData objects from a Cursor
class LoginDataSource: NSObject, UITableViewDataSource {

    var count: Int = 0

    weak var dataObserver: LoginDataSourceObserver?

    fileprivate let emptyStateView = NoLoginsView()

    fileprivate var sections = [Character: [Login]]() {
        didSet {
            assert(Thread.isMainThread, "Must be assigned to from the main thread or else data will be out of sync with reloadData.")
            self.dataObserver?.loginSectionsDidUpdate()
        }
    }

    fileprivate var titles = [Character]()

    fileprivate func loginsForSection(_ section: Int) -> [Login]? {
        let titleForSectionIndex = titles[section]
        return sections[titleForSectionIndex]
    }

    func loginAtIndexPath(_ indexPath: IndexPath) -> Login? {
        let titleForSectionIndex = titles[indexPath.section]
        return sections[titleForSectionIndex]?[indexPath.row]
    }

    @objc func numberOfSections(in tableView: UITableView) -> Int {
        let numOfSections = sections.count
        if numOfSections == 0 {
            tableView.backgroundView = emptyStateView
            tableView.separatorStyle = .none
        } else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
        return numOfSections
    }

    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return loginsForSection(section)?.count ?? 0
    }

    @objc func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable:next force_cast
        let cell = tableView.dequeueReusableCell(withIdentifier: LoginCellIdentifier, for: indexPath) as! LoginTableViewCell
        let login = loginAtIndexPath(indexPath)!
        cell.style = .noIconAndBothLabels
        cell.updateCellWithLogin(login)
        return cell
    }

    @objc func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return titles.map { String($0) }
    }

    @objc func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return titles.firstIndex(of: Character(title)) ?? 0
    }

    @objc func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return String(titles[section])
    }

    func setLogins(_ logins: [Login]) {
        // NB: Make sure we call the callback on the main thread so it can be synced up with a reloadData to
        //     prevent race conditions between data/UI indexing.
        return computeSectionsFromLogins(logins).uponQueue(.main) { result in
            guard let (titles, sections) = result.successValue else {
                self.count = 0
                self.titles = []
                self.sections = [:]
                return
            }

            self.count = logins.count
            self.titles = titles
            self.sections = sections
        }
    }

    fileprivate func computeSectionsFromLogins(_ logins: [Login]) -> Deferred<Maybe<([Character], [Character: [Login]])>> {
        guard logins.count > 0 else {
            return deferMaybe( ([Character](), [Character: [Login]]()) )
        }

        var domainLookup = [GUID: (baseDomain: String?, host: String?, hostname: String)]()
        var sections = [Character: [Login]]()
        var titleSet = Set<Character>()

        // Small helper method for using the precomputed base domain to determine the title/section of the
        // given login.
        func titleForLogin(_ login: Login) -> Character {
            // Fallback to hostname if we can't extract a base domain.
            let titleString = domainLookup[login.guid]?.baseDomain?.uppercased() ?? login.hostname
            return titleString.first ?? Character("")
        }

        // Rules for sorting login URLS:
        // 1. Compare base domains
        // 2. If bases are equal, compare hosts
        // 3. If login URL was invalid, revert to full hostname
        func sortByDomain(_ loginA: Login, loginB: Login) -> Bool {
            guard let domainsA = domainLookup[loginA.guid],
                  let domainsB = domainLookup[loginB.guid] else {
                return false
            }

            guard let baseDomainA = domainsA.baseDomain,
                  let baseDomainB = domainsB.baseDomain,
                  let hostA = domainsA.host,
                let hostB = domainsB.host else {
                return domainsA.hostname < domainsB.hostname
            }

            if baseDomainA == baseDomainB {
                return hostA < hostB
            } else {
                return baseDomainA < baseDomainB
            }
        }

        return deferDispatchAsync(DispatchQueue.global(qos: DispatchQoS.userInteractive.qosClass)) {
            // Precompute the baseDomain, host, and hostname values for sorting later on. At the moment
            // baseDomain() is a costly call because of the ETLD lookup tables.
            logins.forEach { login in
                domainLookup[login.guid] = (
                    login.hostname.asURL?.baseDomain,
                    login.hostname.asURL?.host,
                    login.hostname
                )
            }

            // 1. Temporarily insert titles into a Set to get duplicate removal for 'free'.
            logins.forEach { titleSet.insert(titleForLogin($0)) }

            // 2. Setup an empty list for each title found.
            titleSet.forEach { sections[$0] = [Login]() }

            // 3. Go through our logins and put them in the right section.
            logins.forEach { sections[titleForLogin($0)]?.append($0) }

            // 4. Go through each section and sort.
            sections.forEach { sections[$0] = $1.sorted(by: sortByDomain) }

            return deferMaybe( (Array(titleSet).sorted(), sections) )
        }
    }
}

/// Empty state view when there is no logins to display.
fileprivate class NoLoginsView: UIView {

    // We use the search bar height to maintain visual balance with the whitespace on this screen. The
    // title label is centered visually using the empty view + search bar height as the size to center with.
    var searchBarHeight: CGFloat = 0 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = LoginListUX.noResultsFont
        label.textColor = LoginListUX.noResultsTextColor
        label.text = Strings.loginListNoLoginTitle
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
    }

    fileprivate override func updateConstraints() {
        super.updateConstraints()
        titleLabel.snp.remakeConstraints { make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).offset(-(searchBarHeight / 2))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// View to display to the user while we are loading the logins
fileprivate class LoadingLoginsView: UIView {

    var searchBarHeight: CGFloat = 0 {
        didSet {
            setNeedsUpdateConstraints()
        }
    }

    lazy var indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .gray)
        indicator.hidesWhenStopped = false
        return indicator
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(indicator)
        backgroundColor = UIColor.Photon.white100
        indicator.startAnimating()
    }

    fileprivate override func updateConstraints() {
        super.updateConstraints()
        indicator.snp.remakeConstraints { make in
            make.centerX.equalTo(self)
            make.centerY.equalTo(self).offset(-(searchBarHeight / 2))
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
