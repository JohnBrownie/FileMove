//
//  ViewController.swift
//  FileMove
//
//  Created by John Brownie on 10/12/19.
//  Copyright © 2019 John Brownie. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
	var sourceURL: URL?
	var destinationURL: URL?
	var logText = ""

	@IBOutlet var sourceFileButton: NSButton!
	@IBOutlet var sourceFilePath: NSPathControl!
	@IBOutlet var destinationButton: NSButton!
	@IBOutlet var destinationPath: NSPathControl!
	@IBOutlet var moveButton: NSButton!
	@IBOutlet var logField: NSTextField!
	
	override func viewDidLoad() {
		super.viewDidLoad()

		// Do any additional setup after loading the view.
		logField.stringValue = ""
	}

	override var representedObject: Any? {
		didSet {
		// Update the view, if already loaded.
		}
	}

	@IBAction func setSourceFile(_ sender: Any) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseDirectories = false
		openPanel.canChooseFiles = true
		openPanel.allowsMultipleSelection = false
		openPanel.beginSheetModal(for: self.view.window!) { (response) in
			if response == .OK {
				self.sourceURL = openPanel.url
				self.sourceFilePath.url = self.sourceURL
			}
		}
	}
	
	@IBAction func setDestination(_ sender: Any) {
		let openPanel = NSOpenPanel()
		openPanel.canChooseDirectories = true
		openPanel.canChooseFiles = false
		openPanel.allowsMultipleSelection = false
		openPanel.beginSheetModal(for: self.view.window!) { (response) in
			if response == .OK {
				self.destinationURL = openPanel.url
				self.destinationPath.url = self.destinationURL
			}
		}
	}
	
	@IBAction func moveFile(_ sender: Any) {
		if let source = sourceURL, var destination = destinationURL {
			destination.appendPathComponent(source.lastPathComponent)
			logText += "Move \(source.path) to \(destination.path)\n"
			logField.stringValue = logText
			FileOperations.move(from: source, to: destination) { (success, theError) in
				if !success {
					NSApp.presentError(theError!)
				}
			}
		}
	}
}

