//
//  StorageVolumeManager.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/16/24.
//  Copyright © 2024 Stevo Brock. All rights reserved.
//

import DiskArbitration

//----------------------------------------------------------------------------------------------------------------------
// MARK: StorageVolumeManager
public class StorageVolumeManager {

	// MARK: Notifications
	/*
		Sent when the StorageVolumeManager has been informed that a StorageVolume has appeared
			object is StorageVolumeManager
			userInfo contains the folowing keys:
				url: URL of unmounted volume
				storageVolume: StorageVolumeManager.StorageVolume
	*/
	static	public	let	storageVolumeMounted = Notification.Name("storageVolumeManagerStorageVolumeMounted")

	/*
		Sent when the StorageVolumeManager has been informed that a StorageVolume has been unmounted
			object is StorageVolumeManager
			userInfo contains the folowing keys:
				url: URL of unmounted volume
				storageVolume: StorageVolumeManager.StorageVolume
	*/
	static	public	let	storageVolumeUnmounted = Notification.Name("storageVolumeManagerStorageVolumeUnmounted")

	// MARK: StorageVolume
	public class StorageVolume {

		// MARK: Properties
		public		let	url :URL

		public		let	availableCapacity :Int64?
		public		let	totalCapacity :Int64?
		public		let	isInternal :Bool?
		public		let	localizedFormatDescription :String?
		public		let	localizedName :String?

		public		var	displayName :String {
								// Get localized name
								if let localizedName = self.localizedName {
									// Have localized name
									return "\(localizedName) (\(self.url.path))"
								} else {
									// Don't have localized name
									return "\(self.url)"
								}
							}
		public		var	usedCapacity :Int64? {
								// Get info
								if let availableCapacity = self.availableCapacity, let totalCapacity = self.totalCapacity {
									// Have info
									return totalCapacity - availableCapacity
								} else {
									// Don't have info
									return nil
								}
							}

		fileprivate	var	lockedMessage :String? {
								// Check situation
								if let id = self.messageByLockID.keys.first {
									// Have at least one lock
									return self.messageByLockID.value(for: id)
								} else if (self.lastMessageRemovalDate != nil) &&
										(Date().timeIntervalSince(self.lastMessageRemovalDate!) < 5.0) {
									// Last message was removed recently.  Let's give it a bit to ensure a new message
									//	doesn't appearbefore we're ready.
									return self.lastMessage
								} else {
									// No message
									return nil
								}
							}

		private		let	messageByLockID = LockingDictionary<String, String>()
		private		var	lastMessage :String?
		private		var	lastMessageRemovalDate :Date?

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(_ url :URL, _ urlResourceValues :URLResourceValues) {
			// Store
			self.url = url

			self.availableCapacity = Int64(urlResourceValues.volumeAvailableCapacity)
			self.totalCapacity = Int64(urlResourceValues.volumeTotalCapacity)
			self.isInternal = urlResourceValues.volumeIsInternal
			self.localizedFormatDescription = urlResourceValues.volumeLocalizedFormatDescription
			self.localizedName = urlResourceValues.volumeLocalizedName
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		public func addLock(message :String) -> String {
			// Setup
			let	id = UUID().base64EncodedString

			// Store
			self.messageByLockID.set(message, for: id)

			return id
		}

		//--------------------------------------------------------------------------------------------------------------
		public func removeLock(id :String) {
			// Update
			self.lastMessage = self.messageByLockID.value(for: id)
			self.lastMessageRemovalDate = Date()

			// Remove
			self.messageByLockID.remove(id)
		}
	}

	// MARK: Properties
	static	public	let	shared = StorageVolumeManager()

			public	var	mountedStorageVolumes :[StorageVolume] { self.storageVolumeByURL.values }
			public	var	externalMountedStorageVolumes :[StorageVolume]
							{ self.mountedStorageVolumes.filter({ !($0.isInternal ?? false) }) }

			private	let	daSession :DASession
			private	let	storageVolumeByURL = LockingDictionary<URL, StorageVolume>()
			private	let	urlResourceKeys :[URLResourceKey] =
							[
								.volumeAvailableCapacityKey,
								.volumeTotalCapacityKey,
								.volumeIsInternalKey,
								.volumeLocalizedFormatDescriptionKey,
								.volumeLocalizedNameKey,
							]

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {
		// Setup Disk Arbitration session
		self.daSession = DASessionCreate(kCFAllocatorDefault)!
		DASessionSetDispatchQueue(self.daSession, DispatchQueue.global())
		DARegisterDiskUnmountApprovalCallback(self.daSession, nil,
				{ disk, context -> Unmanaged<DADissenter>? in
					// Setup
					let	storageVolumeByURL =
								Unmanaged<LockingDictionary<URL, StorageVolume>>.fromOpaque(context!)
										.takeUnretainedValue()
					guard let description = DADiskCopyDescription(disk) as? [CFString : Any],
							let url = description[kDADiskDescriptionVolumePathKey] as? URL,
							let storageVolume = storageVolumeByURL.value(for: url)
						else { return nil }

					// Check for message
					if let message = storageVolume.lockedMessage {
						// Have message
						return Unmanaged.passRetained(
								DADissenterCreate(kCFAllocatorDefault, DAReturn(kDAReturnBusy), message as CFString))
					} else {
						// Don't have any message
						return nil
					}
				}, Unmanaged.passUnretained(self.storageVolumeByURL).toOpaque())

		// Collect current mounted Storage Volumes
		(FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys:self.urlResourceKeys,
						options: [.skipHiddenVolumes]) ?? [])
				.map({ ($0, try? $0.resourceValues(forKeys: Set(self.urlResourceKeys))) })
				.filter({ $0.1 != nil })
				.forEach({ self.storageVolumeByURL.set(StorageVolume($0.0, $0.1!), for: $0.0) })

		// Register notifications
		NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didMountNotification)
				{ [unowned self] notification in
					// Get info
					let	userInfo = notification.userInfo
					let	url = userInfo![NSWorkspace.volumeURLUserInfoKey] as! URL
					guard let resourceValues = try? url.resourceValues(forKeys: Set(self.urlResourceKeys)) else
							{ return }

					// Note StorageVolume
					let	storageVolume = StorageVolume(url, resourceValues)
					self.storageVolumeByURL.set(storageVolume, for: url)

					// Post notification
					NotificationCenter.default.post(name: type(of: self).storageVolumeMounted, object: self,
							userInfo: ["url": url, "storageVolume": storageVolume])
				}
		NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didUnmountNotification)
				{ [unowned self] notification in
					// Get info
					let	userInfo = notification.userInfo
					let	url = userInfo![NSWorkspace.volumeURLUserInfoKey] as! URL
					guard let storageVolume = self.storageVolumeByURL.value(for: url) else { return }

					// Note removed
					self.storageVolumeByURL.remove(url)

					// Post notification
					NotificationCenter.default.post(name: type(of: self).storageVolumeUnmounted, object: self,
							userInfo: ["url": url, "storageVolume": storageVolume])
				}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func externalMountedStorageVolume(for url :URL) -> StorageVolume? {
		// Return StorageVolume with URL that starts with the given URL
		return self.externalMountedStorageVolumes.first(where: { url.path.hasPrefix($0.url.path) })
	}
}
