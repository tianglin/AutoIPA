//
//  EditController.swift
//  AutoIPA
//
//  Created by Michael on 2017/8/10.
//  Copyright © 2017年 Michael Inc. All rights reserved.
//

import Cocoa

enum OperationType {
    case Add
    case Edit
    case Display
}

protocol EditViewControllerDelegate: NSObjectProtocol {
    func didSave(name: String, path: String, type: OperationType)
}

class EditViewController: NSViewController {

    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var pathField: NSTextField!
    
    weak var delegate: EditViewControllerDelegate?
    var type: OperationType = OperationType.Add
    
    var currProject: Project? {
        didSet {
            nameField.stringValue = (currProject?.name)!
            pathField.stringValue = (currProject?.path)!
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        switch self.type {
            case .Add:
                self.view.window?.title = "新增"
            case .Edit:
                self.view.window?.title = "编辑"
            default:
                self.view.window?.title = "详情"
        }
        
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @IBAction func selectPathEvent(_ sender: NSButton) {
        let openPanel = NSOpenPanel();
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = false
        openPanel.canChooseFiles = false
        openPanel.beginSheetModal(for: self.view.window!) { (result) in
            if result == NSFileHandlingPanelOKButton {
                let filePath = openPanel.urls[0].path
                self.pathField?.stringValue = filePath;
            }
        }
    }
    
    @IBAction func saveEvent(_ sender: NSButton) {
        if !self.nameField.stringValue.isEmpty && !self.pathField.stringValue.isEmpty {
            self.delegate?.didSave(name: self.nameField.stringValue, path:self.pathField.stringValue, type: self.type)
        }
        
        NSApplication.shared().stopModal()
    }
}
