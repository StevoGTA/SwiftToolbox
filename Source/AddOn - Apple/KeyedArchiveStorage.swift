//
//  NSKeyedArchiveStorage.swift
//  Stevo Brock
//
//  Created by Stevo on 8/21/15.
//  Copyright © 2015 Stevo Brock. All rights reserved.
//

#if os(iOS)
	import UIKit
#else
	import AppKit
#endif

//----------------------------------------------------------------------------------------------------------------------
// MARK: KeyedArchiveStorage
class KeyedArchiveStorage {

	// MARK: Object
	class Object {

		// MARK: Properties
		var	didChangeProc :() -> Void = {}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		func notifyChanged() {
			// Call proc
			didChangeProc()
		}
	}

	// MARK: Enums
	enum StorageLocation {
		case libraryFolderByBundleName
	}

	// MARK: Properties
	private	let	storageFile :File

	private	var	storageTimer :Timer?
	private	var	storageDelay :TimeInterval
	private	var	notificationObserver :Any!

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(storageFilename :String, storageLocation :StorageLocation) throws {
		// Setup
		switch storageLocation {
			case .libraryFolderByBundleName:
				// Get info
				let	storageFolder =
							FileManager.default
								.folder(for: .libraryDirectory)
								.folder(withSubPath: Bundle.main.bundleName)
				try FileManager.default.create(storageFolder)

				self.storageFile = storageFolder.file(withSubPath: storageFilename)
		}
		
		self.storageDelay = 5.0

		// Attempt to load
		load()
		
		// Register notifications
		let	willTerminateNotificationProc :(_ notification :Notification) -> Void = { [unowned self] _ in
					// Check if needs storage
					if self.storageTimer != nil {
						// Save
						try? self.save();
					}
				}
#if os(iOS)
		self.notificationObserver =
				NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification,
						using: willTerminateNotificationProc)
#else
		self.notificationObserver =
				NotificationCenter.default.addObserver(forName: NSApplication.willTerminateNotification,
						using: willTerminateNotificationProc)
#endif
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
		// Clean up
		NotificationCenter.default.removeObserver(self.notificationObserver)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func notifyChanged() { restartStorageTimer() }
	
	//------------------------------------------------------------------------------------------------------------------
	func set(info :[String: Any]) { preconditionFailure("This method must be overridden") }

	//------------------------------------------------------------------------------------------------------------------
	func info() -> [String: Any] { preconditionFailure("This method must be overridden") }

	//------------------------------------------------------------------------------------------------------------------
	func register(_ object :Object) {
		// Setup didChangeProc
		object.didChangeProc = { [unowned self] in self.restartStorageTimer() }
	}
	
	//------------------------------------------------------------------------------------------------------------------
	func register(_ objects :[Object]) {
		// Setup didChangeProc
		objects.forEach() { $0.didChangeProc = { [unowned self] in self.restartStorageTimer() } }
	}
	
	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func load() {
		// Attempt to load
		if let data = try? FileReader.contentsAsData(of: self.storageFile),
				let info = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [String : Any] {
			// Setup
			set(info: info!)
		}
	}
	
	//------------------------------------------------------------------------------------------------------------------
	private func save() throws {
		// Store
		let data = try NSKeyedArchiver.archivedData(withRootObject: info(), requiringSecureCoding: true)
		try FileWriter.setContents(of: self.storageFile, to: data)
	}
	
	//------------------------------------------------------------------------------------------------------------------
	private func restartStorageTimer() {
		// Check for existing timer
		if self.storageTimer != nil {
			//  Cancel
			self.storageTimer!.invalidate()
		}
		
		// Start timer
		self.storageTimer = Timer.scheduledTimer(timeInterval: self.storageDelay) { [weak self] _ in try? self?.save() }
	}
}
