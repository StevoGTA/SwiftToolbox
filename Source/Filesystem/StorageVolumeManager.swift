//
//  StorageVolumeManager.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/16/24.
//  Copyright © 2024 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: Notifications
public extension NSNotification.Name {
	/*
		Sent when the StorageVolumeManager has been informed that a StorageVolume has appeared
			object is StorageVolumeManager
			userInfo contains the folowing keys:
				url: URL of unmounted volume
				storageVolume: StorageVolumeManager.StorageVolume
	*/
	static	let	storageVolumeManagerStorageVolumeMounted =
						Notification.Name("storageVolumeManagerStorageVolumeMounted")

	/*
		Sent when the StorageVolumeManager has been informed that a StorageVolume has been unmounted
			object is StorageVolumeManager
			userInfo contains the folowing keys:
				url: URL of unmounted volume
	*/
	static	let	storageVolumeManagerStorageVolumeUnmounted =
						Notification.Name("storageVolumeManagerStorageVolumeUnmounted")
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - StorageVolumeManager
public class StorageVolumeManager {

	// MARK: StorageVolume
	public struct StorageVolume {

		// MARK: Properties
		public	let	url :URL

		public	let	availableCapacity :Int64?
		public	let	totalCapacity :Int64?
		public	let	isInternal :Bool?
		public	let	localizedFormatDescription :String?
		public	let	localizedName :String?

		public	var	displayName :String {
							// Get localized name
							if let localizedName = self.localizedName {
								// Have localized name
								return "\(localizedName) (\(self.url.path))"
							} else {
								// Don't have localized name
								return "\(self.url)"
							}
						}
		public	var	usedCapacity :Int64? {
							// Get info
							if let availableCapacity = self.availableCapacity, let totalCapacity = self.totalCapacity {
								// Have info
								return totalCapacity - availableCapacity
							} else {
								// Don't have info
								return nil
							}
						}

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
	}

	// MARK: Properties
	static	public	let	shared = StorageVolumeManager()

			public	var	mountedStorageVolumes :[StorageVolume] {
								// Get mounted volume URLs
								return (FileManager.default.mountedVolumeURLs(
												includingResourceValuesForKeys:self.urlResourceKeys,
												options: [.skipHiddenVolumes]) ?? [])
										.map({ ($0, try? $0.resourceValues(forKeys: Set(self.urlResourceKeys))) })
										.filter({ $0.1 != nil })
										.map({ StorageVolume($0.0, $0.1!) })
							}
			public	var	externalMountedStorageVolumes :[StorageVolume]
							{ self.mountedStorageVolumes.filter({ !($0.isInternal ?? false) }) }

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
		// Register notifications
		NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didMountNotification)
				{ [unowned self] notification in
					// Get info
					let	userInfo = notification.userInfo
					let	url = userInfo![NSWorkspace.volumeURLUserInfoKey] as! URL
					guard let resourceValues = try? url.resourceValues(forKeys: Set(self.urlResourceKeys)) else
							{ return }

					// Post notification
					NotificationCenter.default.post(name: .storageVolumeManagerStorageVolumeMounted, object: self,
							userInfo: ["url": url, "storageVolume": StorageVolume(url, resourceValues)])
				}
		NSWorkspace.shared.notificationCenter.addObserver(forName: NSWorkspace.didUnmountNotification)
				{ [unowned self] notification in
					// Get info
					let	userInfo = notification.userInfo
					let	url = userInfo![NSWorkspace.volumeURLUserInfoKey] as! URL

					// Post notification
					NotificationCenter.default.post(name: .storageVolumeManagerStorageVolumeUnmounted, object: self,
							userInfo: ["url": url])
				}
	}
}
