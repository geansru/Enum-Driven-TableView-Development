/// Copyright (c) 2018 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import UIKit

class MainViewController: UIViewController {
  
  // MARK: - Private types
  
  enum State {
    case loading
    case populated([Recording])
    case empty
    case paging([Recording], next: Int)
    case error(Error)
  }
  
  // MARK: - IBOutlet's
  
  @IBOutlet private weak var tableView: UITableView!
  @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
  @IBOutlet private weak var loadingView: UIView!
  @IBOutlet private weak var emptyView: UIView!
  @IBOutlet private weak var errorLabel: UILabel!
  @IBOutlet private weak var errorView: UIView!
  
  // MARK: - Private properties
  
  private let searchController = UISearchController(searchResultsController: nil)
  private let networkingService = NetworkingService()
  private let darkGreen = UIColor(red: 11/255, green: 86/255, blue: 14/255, alpha: 1)
  
  private var recordings: [Recording] {
    switch state {
    case .populated(let records),
         .paging(let records, next: _):
      return records
    
    case .empty,
         .error,
         .loading:
      return []
    }
  }
  
  private var state: State = .loading {
    didSet {
      setFooterView()
      tableView.reloadData()
    }
  }
  
  // MARK: - Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Chirper"
    activityIndicator.color = darkGreen
    prepareNavigationBar()
    prepareSearchBar()
    prepareTableView()
    loadRecordings()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    searchController.searchBar.becomeFirstResponder()
  }
  
  // MARK: - Loading recordings
  
  @objc private func loadRecordings() {
    state = .loading

    load(page: 1)
  }
  
  private func load(page: Int) {
    let query = searchController.searchBar.text
    networkingService.fetchRecordings(matching: query, page: page) { [weak self] response in
      
      guard let `self` = self else { return }
      
      self.searchController.searchBar.endEditing(true)
      self.update(response: response)
    }
  }

  private func update(response: RecordingsResult) {
    if let error = response.error {
      state = .error(error)
      return
    }
    
    guard let newRecords = response.recordings, !newRecords.isEmpty else {
      state = .empty
      return
    }
    var allRecords = recordings
    allRecords.append(contentsOf: newRecords)
    if response.hasMorePages {
      state = .paging(allRecords, next: response.nextPage)
    }
    else {
      state = .populated(newRecords)
    }
  }
  
  // MARK: - View Configuration
  
  private func setFooterView() {
    switch state {
    case .loading,
         .paging:
      tableView.tableFooterView = loadingView
      
    case .error(let error):
      errorLabel.text = error.localizedDescription
      tableView.tableFooterView = errorView
      
    case .empty:
      tableView.tableFooterView = emptyView
      
    case .populated:
      tableView.tableFooterView = nil
    }
  }
  
  private func prepareSearchBar() {
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.delegate = self
    searchController.searchBar.autocapitalizationType = .none
    searchController.searchBar.autocorrectionType = .no
    
    searchController.searchBar.tintColor = .white
    searchController.searchBar.barTintColor = .white
    
    let whiteTitleAttributes = [NSAttributedStringKey.foregroundColor.rawValue: UIColor.white]
    let textFieldInSearchBar = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
    textFieldInSearchBar.defaultTextAttributes = whiteTitleAttributes
    
    navigationItem.searchController = searchController
    searchController.searchBar.becomeFirstResponder()
  }
  
  private func prepareNavigationBar() {
    navigationController?.navigationBar.barTintColor = darkGreen
    
    let whiteTitleAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
    navigationController?.navigationBar.titleTextAttributes = whiteTitleAttributes
  }
  
  private func prepareTableView() {
    tableView.dataSource = self
    
    let nib = UINib(nibName: BirdSoundTableViewCell.NibName, bundle: .main)
    tableView.register(nib, forCellReuseIdentifier: BirdSoundTableViewCell.ReuseIdentifier)
  }
  
}

// MARK: -

extension MainViewController: UISearchBarDelegate {
  
  func searchBar(_ searchBar: UISearchBar,
                 selectedScopeButtonIndexDidChange selectedScope: Int) {
  }
  
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    NSObject.cancelPreviousPerformRequests(withTarget: self,
                                           selector: #selector(loadRecordings),
                                           object: nil)
    
    perform(#selector(loadRecordings), with: nil, afterDelay: 0.5)
  }
  
}

extension MainViewController: UITableViewDataSource {
  
  func tableView(_ tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    return recordings.count
  }
  
  func tableView(_ tableView: UITableView,
                 cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
    guard let cell = tableView.dequeueReusableCell(
      withIdentifier: BirdSoundTableViewCell.ReuseIdentifier)
      as? BirdSoundTableViewCell else {
        return UITableViewCell()
    }
    
    cell.load(recording: recordings[indexPath.row])
    
    if case .paging(_, let nextPage) = state, indexPath.row == recordings.count - 1 {
      load(page: nextPage)
    }
    
    return cell
  }
}

