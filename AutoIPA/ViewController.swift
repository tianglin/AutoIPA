//
//  ViewController.swift
//  AutoIPA
//
//  Created by Michael on 2017/8/4.
//  Copyright © 2017年 Michael Inc. All rights reserved.
//

import Cocoa

//enum Project {
//    case Ghome
//    case Gkeeper
//}

struct Environment {
    var name: String!
    init(name: String) {
        self.name = name
    }
}

class ViewController: NSViewController {
    
    @IBOutlet weak var debugRadioButton: NSButton!
    @IBOutlet weak var releaseRadioButton: NSButton!
    
    @IBOutlet weak var ghomeRadioButton: NSButton!
    @IBOutlet weak var gkeeperRadioButton: NSButton!
    
    @IBOutlet weak var scriptPathField: NSTextField!
    @IBOutlet weak var projectPathField: NSTextField!
    @IBOutlet weak var outputPathField: NSTextField!
    @IBOutlet weak var shellLogTextView: NSTextView!

    var env = Environment(name: "Debug")
    var currProject: Project?
    
    static let GhomePath = "/Users/ddkj007/Documents/gemdale/git/New_GHome_APP_iOS"
    static let GkeeperPath = "/Users/ddkj007/Documents/gemdale/git/GKeeper_APP_iOS"
    static let ScriptPathKey = "scriptPath"
    static let OutputPathKey = "outputPath"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.debugRadioButton.state = NSOnState
        self.ghomeRadioButton.state = NSOnState
        // Do any additional setup after loading the view.
        let sp = UserDefaults.standard.string(forKey: ViewController.ScriptPathKey)
        if sp != nil {
            self.scriptPathField.stringValue = sp!
        }
        
        let op = UserDefaults.standard.string(forKey: ViewController.OutputPathKey)
        if op != nil {
            self.outputPathField.stringValue = op!
        }
        
        self.projectPathField.stringValue = ViewController.GhomePath
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    func getProjectPath() -> String? {
        return ""
    }
    
    @IBAction func chooseEnvEvent(_ sender: AnyObject) {
        if sender.isEqual(self.debugRadioButton) {
            self.env.name = "Debug"
        }
        else if sender.isEqual(self.releaseRadioButton) {
            self.env.name = "Release"
        }
    }
    
    @IBAction func chooseProjectEvent(_ sender: AnyObject) {
        
    }
    
    @IBAction func startPackageEvent(_ sender: Any) {
        print("开始打包...")
        if self.scriptPathField.stringValue.isEmpty {
            print("请选择脚本路径")
            return;
        }
        
        DispatchQueue.global().async {
            self.executeShell()
        }
    }
    
    func executeShell()  {
        print("正在打包...")
        
        let task = Process()
        task.launchPath = self.scriptPathField.stringValue
        task.arguments = [self.getProjectPath()!, "-e", self.env.name, "-o", self.outputPathField.stringValue]
        let pipe = Pipe()
        task.standardOutput = pipe
        // Get the data
        let outHandle = pipe.fileHandleForReading
        outHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: String.Encoding.utf8) {
                // Update your view with the new text here
//                print("New ouput: \(line)")
                DispatchQueue.main.async {
                    self.shellLogTextView.string = self.shellLogTextView.string! + line
                    self.shellLogTextView.scrollToEndOfDocument(nil)
                }
            } else {
                print("Error decoding data: \(pipe.availableData)")
            }
        }
        // Launch the task
        task.launch()
    }
    
    @IBAction func openPanelEvent(_ sender: NSButton) {
        
        var canChooseFiles = true
        var key: String = ""
        var field: NSTextField? = nil
        
        if sender.tag == 0 {
            key = ViewController.ScriptPathKey
            field = self.scriptPathField
        }
        else if sender.tag == 1 {
            canChooseFiles = false
            key = ViewController.OutputPathKey
            field = self.outputPathField
        }
        
        let openPanel = NSOpenPanel();
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = canChooseFiles
        openPanel.beginSheetModal(for: self.view.window!) { (result) in
            if result == NSFileHandlingPanelOKButton {
                let filePath = openPanel.urls[0].path
                field?.stringValue = filePath;
                // 缓存
                UserDefaults.standard.setValue(filePath, forKey: key)
            }
        }
    }
    
}

