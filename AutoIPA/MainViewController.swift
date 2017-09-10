//
//  MainViewController.swift
//  AutoIPA
//
//  Created by Michael on 2017/8/4.
//  Copyright © 2017年 Michael Inc. All rights reserved.
//

import Cocoa
import RealmSwift

struct Environment {
    var name: String!
    init(name: String) {
        self.name = name
    }
}

class MainViewController: NSViewController {
    
    @IBOutlet weak var debugRadioButton: NSButton!
    @IBOutlet weak var releaseRadioButton: NSButton!
    @IBOutlet weak var packagingButton: NSButton!
    
    @IBOutlet weak var scriptPathField: NSTextField!
    @IBOutlet weak var outputPathField: NSTextField!
    @IBOutlet weak var shellLogTextView: NSTextView!

    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var removeButton: NSButton!
    @IBOutlet weak var editButton: NSButton!
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    var env = Environment(name: "Debug")
    let realm = try! Realm()
    let projects = try! Realm().objects(Project.self)
    var currProject: Project?
    var lastSelectedRow = -1
    
    var task = Process()
    
    static let ScriptPathKey = "scriptPath"
    static let OutputPathKey = "outputPath"
    static let LastSelectedRowKey = "lastSelectedRow"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.shellLogTextView.isEditable = false
        // Do any additional setup after loading the view.
        let sp = UserDefaults.standard.string(forKey: MainViewController.ScriptPathKey)
        if sp != nil {
            self.scriptPathField.stringValue = sp!
        } else {
            let bundlePath = Bundle.main.path(forResource: "ipa-build", ofType: nil, inDirectory: nil)
            self.scriptPathField.stringValue = bundlePath ?? ""
        }
        let op = UserDefaults.standard.string(forKey: MainViewController.OutputPathKey)
        if op != nil {
            self.outputPathField.stringValue = op!
        }
        self.lastSelectedRow = UserDefaults.standard.integer(forKey: MainViewController.LastSelectedRowKey)
        
        self.check()
    }
    
    override func viewWillAppear() {
        self.setSelectRow()
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    //MARK: 其他
    
    func setSelectRow() {
        if self.lastSelectedRow < self.projects.count-1 {
            self.tableView.selectRowIndexes([self.lastSelectedRow], byExtendingSelection: true)
        } else {
            self.tableView.selectRowIndexes([self.projects.count-1], byExtendingSelection: true)
        }
    }
    
    func check() {
        if currProject != nil {
            self.editButton.isEnabled = true
            self.removeButton.isEnabled = true
        } else {
            self.editButton.isEnabled = false
            self.removeButton.isEnabled = false
        }
        if self.scriptPathField.stringValue.isEmpty || self.currProject == nil || self.tableView.selectedRow < 0 {
            self.packagingButton.isEnabled = false
        } else {
            self.packagingButton.isEnabled = true
        }
    }
    
    func executeOver() {
        if self.currProject != nil {
            self.packagingButton.isEnabled = true
        } else {
            self.packagingButton.isEnabled = false
        }
        self.packagingButton.title = "开始打包"
        self.progressIndicator.isHidden = true
        self.progressIndicator.stopAnimation(nil)
        self.shellLogTextView.scrollToEndOfDocument(nil)
    }
    
    func executeShell()  {
        print("🍎 Start...")
        
        self.task = Process()
        
        task.launchPath = self.scriptPathField.stringValue
        task.arguments = [self.currProject!.path, "-e", self.env.name, "-o", self.outputPathField.stringValue]
        let pipe = Pipe()
        task.standardOutput = pipe
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                // Update your view with the new text here
                DispatchQueue.main.async {
                    self.shellLogTextView.string = self.shellLogTextView.string! + line
                    self.shellLogTextView.scrollToEndOfDocument(nil)
                }
            } else {
                print("🍎 Error decoding data: \(pipe.availableData)")
            }
        }
        task.terminationHandler = { task in
            print("🍎 Execute script finished.")
            DispatchQueue.main.async {
                self.executeOver()
            }
        }
        
        // 延迟检查是否执行正常，有可能选择的脚本错误
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if !self.task.isRunning {
                if (self.shellLogTextView.string?.isEmpty)! {
                    self.shellLogTextView.string = "打包出错，请检查脚本是否正确"
                }
                self.executeOver()
            }
        }
        
        task.launch()
    }
    
    //MARK: 按钮事件
    
    @IBAction func chooseEnvEvent(_ sender: AnyObject) {
        if sender.isEqual(self.debugRadioButton) {
            self.env.name = "Debug"
        }
        else if sender.isEqual(self.releaseRadioButton) {
            self.env.name = "Release"
        }
    }
    
    @IBAction func startPackageEvent(_ sender: Any) {
        if self.task.isRunning {
            return;
        }
        print("🍎 开始打包...")
        if self.scriptPathField.stringValue.isEmpty {
            print("🍎 请选择脚本路径")
            return
        }
        
        self.shellLogTextView.string = ""
        self.packagingButton.isEnabled = false
        self.packagingButton.title = "打包中..."
        self.progressIndicator.isHidden = false
        self.progressIndicator.startAnimation(nil)
        
        self.executeShell()
        
/*
        // 延迟操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            
        }
        // 异步执行
        DispatchQueue.global().async {
            
        }
        // 主线程执行
        DispatchQueue.main.async {
         
        }
 */
    }
    
    @IBAction func openPanelEvent(_ sender: NSButton) {
        if self.task.isRunning {
            return;
        }
        
        var canChooseFiles = true
        var field: NSTextField? = nil
        var key: String? = nil
        
        if sender.tag == 0 {
            key = MainViewController.ScriptPathKey
            field = self.scriptPathField
        }
        else if sender.tag == 4 {
            canChooseFiles = false
            key = MainViewController.OutputPathKey
            field = self.outputPathField
        }
        
        let openPanel = NSOpenPanel();
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = !canChooseFiles
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = canChooseFiles
        openPanel.beginSheetModal(for: self.view.window!) { (result) in
            if result == NSFileHandlingPanelOKButton {
                let filePath = openPanel.urls[0].path
                field?.stringValue = filePath;
                // cache the path
                if key != nil {
                    UserDefaults.standard.setValue(filePath, forKey: key!)
                }
            }
        }
    }
    
    @IBAction func showEditViewEvent(_ sender: NSButton) {
        if self.task.isRunning {
            return;
        }
        
        let row = self.tableView.selectedRow
        if sender.tag == 3 && row < 0 {
            return
        }
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let editWindowController = storyboard.instantiateController(withIdentifier: "EditWindow") as! NSWindowController
        
        if let editWindow = editWindowController.window {
            let editViewController = editWindow.contentViewController as! EditViewController
            if sender.tag == 1 {
                editViewController.delegate = self
                editViewController.type = OperationType.Add
            }
            else if sender.tag == 3 {
                editViewController.delegate = self
                editViewController.currProject = self.currProject
                editViewController.type = OperationType.Edit
            }
            
            let application = NSApplication.shared()
            application.runModal(for: editWindow)
            editWindow.close()
        }
    }
    
    @IBAction func removeEvent(_ sender: NSButton) {
        if self.task.isRunning {
            return;
        }
        
        let alert = NSAlert()
        alert.messageText = "删除项目"
        alert.informativeText = "你确定要删除这个项目吗?"
        alert.addButton(withTitle: "删除")
        alert.addButton(withTitle: "取消")
        alert.beginSheetModal(for: self.view.window!) { (modalResponse) in
            if modalResponse == NSAlertFirstButtonReturn {
                let row = self.tableView.selectedRow
                if row >= 0 {
                    try! self.realm.write {
                        self.realm.delete(self.projects[row])
                    }
                    
                    self.tableView.reloadData()
                    self.currProject = nil
                    self.check()
                    self.tableView.selectRowIndexes([self.projects.count-1], byExtendingSelection: true)
                }
            }
        }
    }
}

extension MainViewController: EditViewControllerDelegate {
    func didSave(name: String, path: String, type: OperationType) {
        switch type {
            case .Add:
                let pro = Project()
                pro.name = name
                pro.path = path
                
                // 新增
                try! self.realm.write {
                    self.realm.add(pro)
                    self.tableView.reloadData()
                    self.check()
                    self.setSelectRow()
                }
            case .Edit:
                // 更新
                try! self.realm.write {
                    self.currProject?.name = name
                    self.currProject?.path = path
                    self.tableView.reloadData()
                    self.check()
                    self.setSelectRow()
                    
                }
            case .Display:
                return
        }
    }
}

extension MainViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.projects.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.projects[row]
    }
}

extension MainViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        if self.task.isRunning {
            return false
        } else {
            return true
        }
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let row = self.tableView.selectedRow
        if row >= 0 {
            self.currProject = self.projects[row]
            self.lastSelectedRow = row
            UserDefaults.standard.setValue(row, forKey: MainViewController.LastSelectedRowKey)
        } else {
            self.currProject = nil;
        }
        self.check()
    }
}

extension MainViewController: NSTextFieldDelegate {
    
}
