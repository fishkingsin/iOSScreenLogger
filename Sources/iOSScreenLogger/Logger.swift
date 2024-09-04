//
//  Logger.swift
//  NMG News
//
//  Created by Joey Sun on 2024/8/26.
//
import Foundation
import UIKit

internal struct Log {
    let title: String
    let content: String
    let type: LogType
}

public enum LogType: String {
    case all = "All"
    case API = "API"
    case tracking = "Tracking"
}

public class Logger: NSObject {
    public var debug: Bool = true
    public static let sharedManager = Logger()

    fileprivate var floatingWindow: UIWindow?

    fileprivate lazy var loggerView: UIView = {
        let loggerView = UIView()
        loggerView.translatesAutoresizingMaskIntoConstraints = false
        loggerView.backgroundColor = UIColor.white
        return loggerView
    }()
    
    fileprivate lazy var showButton: UIButton = {
        let showButton = DragButtonView(type: .system)
        showButton.translatesAutoresizingMaskIntoConstraints = false
        showButton.titleLabel?.textAlignment = .center
        showButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        showButton.setTitle("Logger", for: .normal)
//        showButton.addTarget(self, action: #selector(showButtonDidPress(_:)), for: .touchUpInside)
        showButton.isKeepBounds = true
        showButton.forbidenEnterStatusBar = true
        showButton.fatherIsController = true
        showButton.forbidenEnterStatusBar = true
        showButton.clickDragViewBlock = { [weak self] btn in
            guard let self = self else { return }
            self.showButtonDidPress(btn)
        }
        showButton.layer.borderWidth = 1
        showButton.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        showButton.backgroundColor = UIColor(white: 0.7, alpha: 1)
        showButton.setTitleColor(UIColor.black, for: .normal)
        return showButton
    }()
    fileprivate lazy var closeButton: UIButton = {
        // Close Button
        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("Close", for: .normal)
        closeButton.backgroundColor = UIColor.red
        closeButton.addTarget(self, action: #selector(closeButtonDidPress(_:)), for: .touchUpInside)
        closeButton.setTitleColor(UIColor.black, for: .normal)
        return closeButton
    }()

    // View controller
    fileprivate lazy var navVC: UINavigationController = {
        let navVC = UINavigationController(rootViewController: self.vc)
        navVC.navigationBar.barTintColor = UIColor.clear
        navVC.navigationBar.isTranslucent = true
        navVC.navigationBar.setBackgroundImage(UIImage(), for: UIBarMetrics.default)
        navVC.navigationBar.shadowImage = UIImage()
        navVC.view.backgroundColor = UIColor.clear
        navVC.navigationBar.tintColor = UIColor.black
        navVC.navigationBar.barStyle = .blackTranslucent
        return navVC
    }()
    fileprivate lazy var vc: LoggerListViewController = {
        let controller = LoggerListViewController()
        return controller
    }()
    let dateFormatter = DateFormatter()

    func printLog(title: String, text: String, type: LogType) {
        let log = Log(title: title, content: text, type: type)
        vc.logs.insert(log, at: 0)
    }

    override init() {
        super.init()
        DispatchQueue.main.async {
            self.initialize()
        }
    }
    // Initialize
    private func initialize() {
        dateFormatter.dateFormat = "HH:mm:ss"
        guard let windowScene = UIApplication.shared.keyWindow else { return }
        floatingWindow = windowScene
        commonViewInit()
    }

    fileprivate func commonViewInit() {
        // Subview addings
        floatingWindow?.addSubview(loggerView)
        floatingWindow?.addSubview(closeButton)
        floatingWindow?.addSubview(showButton)
        loggerView.layer.zPosition = 1000
        closeButton.layer.zPosition = 1000
        showButton.layer.zPosition = 1000

        if floatingWindow != nil {
            // View Constraints
            floatingWindow?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[showButton(==85)]|", options: [], metrics: nil, views: ["showButton": showButton]))
            floatingWindow?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[closeButton]|", options: [], metrics: nil, views: ["closeButton": closeButton]))
            floatingWindow?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[loggerView]|", options: [], metrics: nil, views: ["loggerView": loggerView]))

            floatingWindow?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[loggerView][closeButton(45)]|", options: [], metrics: nil, views: ["loggerView": loggerView, "closeButton": closeButton]))
            floatingWindow?.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[showButton(==35)]-135-|", options: [], metrics: nil, views: ["showButton": showButton]))
        }

        // Initial state
        showLogButton(show: true)

        loggerView.addSubview(navVC.view)
        navVC.view.frame = loggerView.frame
        let _ = vc.view
    }

    public func showLogButton(show isShow: Bool = true) {
        showButton.isHidden = !isShow
        loggerView.isHidden = isShow
        closeButton.isHidden = isShow
        if isShow {
            floatingWindow?.bringSubviewToFront(showButton)
            floatingWindow?.bringSubviewToFront(loggerView)
            floatingWindow?.bringSubviewToFront(closeButton)
        }
    }

    @objc func showButtonDidPress(_ sender: UIButton) {
        floatingWindow?.topAnchor.constraint(equalTo: loggerView.topAnchor, constant: floatingWindow?.safeAreaInsets.top ?? 0)

        navVC.view.setNeedsUpdateConstraints()
        navVC.view.setNeedsLayout()
        navVC.view.layoutIfNeeded()

        vc.view.setNeedsUpdateConstraints()
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()

        showLogButton(show: false)
    }

    @objc func closeButtonDidPress(_ sender: UIButton) {
        showLogButton(show: true)
    }

    public func log(title: String, content: String, type: LogType) {
        DispatchQueue.main.async {
            self.hideAllLogView()
            if self.debug {
                self.vc.log(title: "\(self.dateFormatter.string(from: Date())) \(title)", content: content, type: type)
            }
        }
    }

    private func hideAllLogView() {
        if !debug {
            showButton.isHidden = true
            loggerView.isHidden = true
            closeButton.isHidden = true
        }
    }
}

internal class LoggerListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // State

    func getAdditionalInsetIfThereIsAny() -> UIEdgeInsets {
        if #available(iOS 11.0, *) {
            if let navController = self.navigationController {
                return navController.view.safeAreaInsets
            } else {
                return self.view.safeAreaInsets
            }
        } else {
            return UIEdgeInsets.zero
        }
    }

    var logs = [Log]() {
        didSet {
            filteredLogs = logs.filter { (log) -> Bool in
                if self.currentLogType == .all {
                    return true
                }
                return log.type == self.currentLogType
            }
        }
    }

    fileprivate var currentLogType: LogType = .all {
        didSet {
            title = "\(currentLogType.rawValue) Logs"
            filteredLogs = logs.filter { (log) -> Bool in
                if self.currentLogType == .all {
                    return true
                }
                return log.type == self.currentLogType
            }
        }
    }

    fileprivate var filteredLogs = [Log]() {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
            }
        }
    }

    // UI
    fileprivate weak var segmentControl: UISegmentedControl!
    fileprivate weak var tableView: UITableView!
    fileprivate weak var clearButton: UIButton!
    fileprivate weak var searchTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.clipsToBounds = true
        view.backgroundColor = UIColor.clear

        title = "All Logs"
        if let navgationBar = navigationController?.navigationBar {
            navgationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 17)]
        }

        let segmentControl = UISegmentedControl(items: ["All", "API", "Tracking"])
        segmentControl.selectedSegmentIndex = 0
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        segmentControl.tintColor = UIColor.white
        segmentControl.addTarget(self, action: #selector(LoggerListViewController.segmentControlValueChanged(_:)), for: .valueChanged)

        let searchTextField = UITextField()
        searchTextField.translatesAutoresizingMaskIntoConstraints = false
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.borderStyle = .roundedRect
        searchTextField.backgroundColor = .white
        searchTextField.delegate = self

        // Tableview
        let tableView = UITableView(frame: .zero)
        tableView.backgroundColor = UIColor.clear
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "logtableviewcell")

        // Clear Button
        let clearButton = UIButton(type: .system)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.setTitle("Clear All logs", for: .normal)
        clearButton.backgroundColor = UIColor.blue
        clearButton.addTarget(self, action: #selector(LoggerListViewController.clearButtonDidPress(_:)), for: .touchUpInside)
        clearButton.titleLabel?.textColor = UIColor.black

        clearButton.titleLabel?.textColor = UIColor.black

        view.addSubview(segmentControl)
        view.addSubview(tableView)
        view.addSubview(clearButton)
        view.addSubview(searchTextField)

        DispatchQueue.main.async {
            let topSafeAreaInset: CGFloat = UIApplication.shared.keyWindow?.safeAreaInsets.top == 0 ? 44 : 88
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(8)-[segmentControl]-(8)-|", options: [], metrics: nil, views: ["segmentControl": segmentControl]))

            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(8)-[searchTextField]-(8)-|", options: [], metrics: nil, views: ["searchTextField": searchTextField]))

            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[tableView]-|", options: [], metrics: nil, views: ["tableView": tableView]))
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[clearButton]|", options: [], metrics: nil, views: ["clearButton": clearButton]))
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(\(topSafeAreaInset))-[segmentControl]-(8)-[searchTextField(35)][tableView][clearButton(45)]-|", options: [], metrics: nil, views: ["segmentControl": segmentControl, "searchTextField": searchTextField, "tableView": tableView, "clearButton": clearButton]))
        }

        self.segmentControl = segmentControl
        self.tableView = tableView
        self.clearButton = clearButton
        self.searchTextField = searchTextField
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "all", style: .plain, target: self, action: #selector(allLogs))
    }

    @objc private func allLogs(){
        DispatchQueue.global().async {
            var content = ""
            self.filteredLogs.forEach {
                content += $0.content
                content += "\n"
            }
            let log = Log(title: "All", content: content, type: self.currentLogType)
            DispatchQueue.main.async {
                let vc = LoggerDetailViewController(log: log)
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if #available(iOS 11.0, *) {
            _ = self.view.topAnchor.constraint(equalTo: self.segmentControl.topAnchor, constant: self.view.safeAreaInsets.top)
        } else {
            _ = view.topAnchor.constraint(equalTo: segmentControl.topAnchor, constant: topLayoutGuide.length)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        segmentControl.isHidden = true
        tableView.isHidden = true
        clearButton.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        segmentControl.isHidden = false
        tableView.isHidden = false
        clearButton.isHidden = false
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < filteredLogs.count {
            let log = filteredLogs[indexPath.row]

            let vc = LoggerDetailViewController(log: log)

            navigationController?.pushViewController(vc, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredLogs.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "logtableviewcell", for: indexPath)

        cell.selectionStyle = .none
        cell.textLabel?.numberOfLines = 0
        cell.contentView.backgroundColor = UIColor.clear
        cell.backgroundColor = UIColor.clear

        if indexPath.row < filteredLogs.count {
            let log = filteredLogs[indexPath.row]
            cell.textLabel?.text = log.title
            if log.title.contains("Response: ") {
                do {
                    let expression = try NSRegularExpression(pattern: "ERROR")
                    let matches = expression.matches(in: log.title, options: [], range: NSRange(location: 0, length: log.title.count))
                    if !matches.isEmpty {
                        cell.textLabel?.textColor = .red
                    } else {
                        cell.textLabel?.textColor = .green
                    }
                } catch {
                    cell.textLabel?.textColor = .green
                }

            } else if log.title.contains("Request: ") {
                cell.textLabel?.textColor = .systemBlue
            } else if log.title.contains("Track ") {
                cell.textLabel?.textColor = .black
            } else {
                cell.textLabel?.textColor = UIColor.black
            }
        }

        return cell
    }

    public func log(title: String, content: String, type: LogType) {
        let log = Log(title: title, content: content, type: type)
        logs.insert(log, at: 0)
    }

    @objc func clearButtonDidPress(_ sender: UIButton) {
        logs.removeAll()
    }

    @objc func segmentControlValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            currentLogType = .all
        case 1:
            currentLogType = .API
        case 2:
            currentLogType = .tracking
        default:
            currentLogType = .all
        }
    }

    func filterLogsByTextField() {
        let seStr: String = searchTextField.text ?? ""
        filteredLogs = logs.filter { (log) -> Bool in
            if self.currentLogType == .all {
                return containSearch(str: log.title, containStr: seStr)
            }
            return log.type == self.currentLogType && containSearch(str: log.title, containStr: seStr)
        }
    }

    func containSearch(str: String, containStr: String?) -> Bool {
        guard let cStr = containStr, cStr != "" else {
            return true
        }
        return str.lowercased().contains(cStr.lowercased())
    }
}

extension LoggerListViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        filterLogsByTextField()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
}

internal class LoggerDetailViewController: UIViewController {
    // State
    let log: Log

    private enum Constants {
        static let searchTextFieldKey = "_searchField"
        static let searchBarCancelButtonKey = "cancelButton"
        static let defaultHeaderText = "Default"
    }

    public private(set) lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.autocapitalizationType = .none
        searchBar.delegate = self
        return searchBar
    }()

    public var rangeArr = [NSRange]()
    public var rangeIndex: Int = -1

    // UI
    fileprivate weak var textView: UITextView!
    fileprivate let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.lineBreakMode = .byWordWrapping
        label.backgroundColor = .clear
        label.textColor = UIColor.black
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        return label
    }()

    init(log: Log) {
        self.log = log

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.clipsToBounds = true
        view.backgroundColor = UIColor.white

        navigationItem.titleView = titleLabel
        titleLabel.text = log.title

        // Text View
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.backgroundColor = UIColor.clear
        textView.textColor = UIColor.black
        textView.isEditable = false
        textView.contentInsetAdjustmentBehavior = .never

        view.addSubview(textView)
        view.addSubview(searchBar)

        self.textView = textView

        let topSafeAreaInset: CGFloat = UIApplication.shared.keyWindow?.safeAreaInsets.top == 0 ? 44 : 88

        DispatchQueue.main.async {
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[searchBar]|", options: [], metrics: nil, views: ["searchBar": self.searchBar]))

            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[textView]|", options: [], metrics: nil, views: ["textView": textView]))
            self.view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-\(topSafeAreaInset)-[searchBar(40)]-[textView]|", options: [], metrics: nil, views: ["searchBar": self.searchBar,"textView": textView]))
        }

        updateStyling()

        if #available(iOS 11.0, *) {
            _ = self.view.topAnchor.constraint(equalTo: searchBar.topAnchor, constant: self.view.safeAreaInsets.top)
        } else {
            _ = view.topAnchor.constraint(equalTo: searchBar.topAnchor, constant: topLayoutGuide.length)
        }
        // Text
        textView.text = "\(log.content)"
    }

    private func updateStyling() {

        if #available(iOS 13.0, *) {
            searchBar.searchTextField.font = UIFont.systemFont(ofSize: 12)
            searchBar.searchTextField.textColor = UIColor.darkGray
            searchBar.searchTextField.backgroundColor = UIColor.white
        } else if let textField = getSearchBarTextField() {
            textField.font = UIFont.systemFont(ofSize: 12)
            textField.textColor = UIColor.darkGray
            textField.backgroundColor = UIColor.black
        }

        searchBar.searchBarStyle = .default
        searchBar.showsCancelButton = false
        searchBar.barTintColor = UIColor.white
        searchBar.placeholder = " 请输入关键字查找  "

        let cancelButton = searchBar.value(forKeyPath: Constants.searchBarCancelButtonKey) as? UIButton
        cancelButton?.tintColor = UIColor.black
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textView.isHidden = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        textView.isHidden = false
    }
}

extension LoggerDetailViewController: UISearchBarDelegate {
    fileprivate func getSearchBarTextField() -> UITextField? {
        searchBar.value(forKey: Constants.searchTextFieldKey) as? UITextField
    }

    // return NO to not become first responder
    public func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        true
    }

    // called when text changes (including clear)
    public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchBarFilter(keyWords: searchText)
    }

    // called when cancel button pressed
    public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBarFilter(keyWords: "")
        view.endEditing(true)
    }

    public func searchBarFilter(keyWords: String?) {
        let attributeString = NSMutableAttributedString(string: textView.text ?? "")
        attributeString.addAttribute(.foregroundColor, value: UIColor.black, range: NSRange(location: 0, length: attributeString.string.count))
        if let keyWords = keyWords, !keyWords.isEmpty, let title = titleLabel.text, !title.isEmpty {
            let rangeArr = attributeString.rangeArr(of: keyWords)
            self.rangeArr = rangeArr
            for range in rangeArr {
                attributeString.addAttribute(.foregroundColor, value: UIColor.red, range: range)
            }
            if !rangeArr.isEmpty {
                rangeIndex = 0
                textView.scrollRangeToVisible(rangeArr[0])
            } else {
                rangeIndex = -1
            }
        }
        textView.attributedText = attributeString
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if !rangeArr.isEmpty {
            rangeIndex += 1
            if rangeIndex < rangeArr.count {
                textView.scrollRangeToVisible(rangeArr[rangeIndex])
            } else {
                textView.scrollRangeToVisible(rangeArr[0])
                rangeIndex = -1
            }
        } else {
            rangeIndex = -1
        }
    }
}

extension Logger {
    func printResponseLog(response: HTTPURLResponse, data: Data?, error: Error?) {
        var text = ""
        text += "\n========== Receive Response ==========\n"
        var title = "No Title"
        if let url = response.url {
            text += "\n Request URL:\n\(url)"
            title = "Status: (\(response.statusCode)), "

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm:ss"

            let component = url.absoluteString.split(separator: "?")
            if component.count == 2 {
                title += "Response: \(component.first!) (\(dateFormatter.string(from: Date())))"
            } else {
                title += "Response: \(url) (\(dateFormatter.string(from: Date())))"
            }
        }

        if let error = error {
            text += "\nFound Error:\n\(error.localizedDescription)"
        } else {
            text += "\n\nResponse Code:\n\(response.statusCode)"
            if !response.allHeaderFields.isEmpty {
                text += "\n\nHeader from response:"
                for (key, value) in response.allHeaderFields {
                    text += "\n\(key): \(value)"
                }
            } else {
                text += "\n\nNo Header from response"
            }

            if let data = data,
                let aJson =
                WXJSJsonConvert.convertJson(String(data: data, encoding: String.Encoding.utf8)) {
                guard let prettyJsonData = try? JSONSerialization.data(withJSONObject: aJson, options: .prettyPrinted) else { return }
                guard let jsonString = String(data: prettyJsonData, encoding: String.Encoding.utf8) else { return }

                text += "\n\nResponse:\n\(jsonString)"
            }
        }

        text += "\n\n==========End Of Response==========\n"
        Logger.sharedManager.printLog(title: title, text: text, type: .API)
    }
}

extension NSMutableAttributedString {
   

     func range(of str: String) -> NSRange {
        if str == "" {
            return NSRange(location: 0, length: 0)
        }
        var string = self.string
        var tempRange = NSRange(location: 0, length: 0)

        //  多次出现 只返回最后一次出现的  range
        while true {
            let range: NSRange = (string as NSString).range(of: str)
            if range.location == NSNotFound {
                if countOccurencesOf(str) != 0 {
                    //  获取最后一次出现位置
                    tempRange = NSRange(location: tempRange.location + str.count * (countOccurencesOf(str) - 1), length: tempRange.length)
                    return tempRange
                }
                return tempRange
            } else {
                string = (string as NSString).replacingCharacters(in: range, with: "")
                tempRange = range
            }
        }
    }

    // MARK: -  字符串范围 多次出现 返回数组  [NSRange]

    func rangeArr(of str: String) -> [NSRange] {
        if str == "" {
            return [NSRange(location: 0, length: 0)]
        }
        var rangeArr = [NSRange]()
        var string = self.string
        var tempRange = NSRange(location: 0, length: 0)

        var count = countOccurencesOf(str)
        while count > 0 {
            let range: NSRange = (string as NSString).range(of: str)
            if range.location == NSNotFound {
                tempRange = NSRange(location: tempRange.location + str.count * (count - 1), length: tempRange.length)
            } else {
                tempRange = range
                var replacrStr = ""
                for _ in str {
                    replacrStr += " "
                }
                string = (string as NSString).replacingCharacters(in: range, with: replacrStr)
            }
            rangeArr.append(tempRange)
            count -= 1
        }
        return rangeArr
    }

    //  出现的次数
     func countOccurencesOf(_ searchString: String?) -> Int {
        if (searchString?.count ?? 0) == 0 || string.isEmpty {
            return 0
        }
        let strCount: Int = string.count - string.replacingOccurrences(of: searchString ?? "", with: "").count
        return strCount / (searchString?.count ?? 0)
    }
}
