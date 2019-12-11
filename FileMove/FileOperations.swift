//
//  FileOperations.swift
//  FileMove
//
//  Created by John Brownie on 10/12/19.
//  Copyright © 2019 John Brownie. All rights reserved.
//

import Foundation

let toolName = "FileMoverTool"

// Recipe 6-1 from The Swift Developer's Cookbook
public protocol ExplanatoryErrorType: Error, CustomDebugStringConvertible {
	var reason: String {get}
	var debugDescription: String {get}
}

public extension ExplanatoryErrorType {
	var debugDescription: String {
		return "\(type(of: self)): \(reason)"
	}
}

public struct FMError: ExplanatoryErrorType {
	public let reason: String
}

public struct FMErrorCode: ExplanatoryErrorType {
	public let reason: String
	public let code: Int
}

let kErrorDomain = "org.sil.FileMove"
let errorFileOperationError = FMErrorCode(reason: "File operation error", code: 1)

struct FileOperations {
	static func move(from source: URL, to destination: URL, completion handler:((Bool, NSError?) -> Void)) {
		let fileManager = FileManager.default
		do {
			try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
			// Necessary while the bug noted below is present
			if fileManager.fileExists(atPath: destination.path) {
				try fileManager.removeItem(at: destination)
			}
			try fileManager.moveItem(at: source, to: destination)
			/// DANGER WILL ROBINSON -- the above call can fail to return an
			/// error when the file is not copied.  radar filed and
			/// closed as a DUPLICATE OF 30350792 which is still open.
			/// As a result I must verify that the copied file exists
			if !fileManager.fileExists(atPath: destination.path) {
				// Copy failed
				authenticatedMove(from: source, to: destination, completion: handler)
			}
			handler(true, nil)
		}
		catch let theError as NSError {
			if theError.code == NSFileWriteNoPermissionError {
				// No permission, so we try authenticated
				authenticatedMove(from: source, to: destination, completion: handler)
			}
			else {
				handler(false, theError)
			}
		}
		catch {
			handler(false, NSError(domain: kErrorDomain, code: errorFileOperationError.code, userInfo: [NSLocalizedDescriptionKey: error.localizedDescription]))
		}
	}
	
	static func authenticatedMove(from source: URL, to destination: URL, completion handler:((Bool, NSError?) -> Void)) {
		if let toolPath = Bundle.main.url(forAuxiliaryExecutable: toolName)?.path {
			let sourcePath = source.path
			let destPath = destination.path
			let scriptString = "do shell script quoted form of \"\(toolPath)\" & \" \" & quoted form of \"\(sourcePath)\" & \" \" & quoted form of \"\(destPath)\" with administrator privileges"
			let appleScript = NSAppleScript(source: scriptString)
			var errorDict: NSDictionary? = NSDictionary()
			_ = appleScript?.executeAndReturnError(&errorDict)
			handler(true, nil)
		}
		else {
			handler(false, NSError(domain: kErrorDomain, code: errorFileOperationError.code, userInfo: [NSLocalizedDescriptionKey: errorFileOperationError.localizedDescription]))
		}
	}
}
