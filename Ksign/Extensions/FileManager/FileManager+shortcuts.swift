//
//  FileManager+shortcuts.swift
//  Feather
//
//  Created by samara on 8.05.2025.
//

import Foundation.NSFileManager

extension FileManager {
	
	func isFileFromFileProvider(at url: URL) -> Bool {
		if let resourceValues = try? url.resourceValues(forKeys: [.isUbiquitousItemKey, .fileResourceIdentifierKey]),
		   resourceValues.isUbiquitousItem == true {
			return true
		}
		
		let path = url.path
		if path.contains("/Library/CloudStorage/") || path.contains("/File Provider Storage/") {
			return true
		}
		
		return false
	}
	
	func removeFileIfNeeded(at url: URL) throws {
		if self.fileExists(atPath: url.path) {
			try self.removeItem(at: url)
		}
	}
	
	func moveFileIfNeeded(from sourceURL: URL, to destinationURL: URL) throws {
		if !self.fileExists(atPath: destinationURL.path) {
			try self.moveItem(at: sourceURL, to: destinationURL)
		}
	}
	
	func createDirectoryIfNeeded(at url: URL) throws {
		if !self.fileExists(atPath: url.path) {
			try self.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
		}
	}
	
	static func forceWrite(content: String, to filename: String) throws {
		let path = URL.documentsDirectory.appendingPathComponent(filename)
		try content.write(to: path, atomically: true, encoding: .utf8)
	}
	
	// FeatherTweak
	func moveAndStore(_ url: URL, with prepend: String, completion: @escaping (URL) -> Void) {
		let destination = _getDestination(url, with: prepend)
		
		try? createDirectoryIfNeeded(at: destination.temp)
		
		var didStartAccessing = false
		if isFileFromFileProvider(at: url) {
			didStartAccessing = url.startAccessingSecurityScopedResource()
		}
		
		defer {
			if didStartAccessing {
				url.stopAccessingSecurityScopedResource()
			}
		}
		
		do {
			var isDirectory: ObjCBool = false
			if self.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue {
				try self.copyItem(at: url, to: destination.dest)
				completion(destination.dest)
			} else {
				let fileData = try Data(contentsOf: url)
				try fileData.write(to: destination.dest)
				completion(destination.dest)
			}
		} catch {
			do {
				try self.copyItem(at: url, to: destination.dest)
				completion(destination.dest)
			} catch {
				print("Error in moveAndStore: \(error.localizedDescription)")
			}
		}
	}
	
	func deleteStored(_ url: URL, completion: @escaping (URL) -> Void) {
		try? FileManager.default.removeItem(at: url)
		completion(url)
	}
	
	// FeatherTweak
	private func _getDestination(_ url: URL, with prepend: String) -> (temp: URL, dest: URL) {
		let tempDir = self.temporaryDirectory.appendingPathComponent("\(prepend)_\(UUID().uuidString)", isDirectory: true)
		let destinationUrl = tempDir.appendingPathComponent(url.lastPathComponent)
		return (tempDir, destinationUrl)
	}
}
