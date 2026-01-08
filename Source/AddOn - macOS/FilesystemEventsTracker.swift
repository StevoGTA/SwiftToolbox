//
//  FilesystemEventsTracker.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/13/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: FilesystemEventsTracker
public class FilesystemEventsTracker {

	// MARK: FolderInfo
	public struct FolderInfo {

		// MARK: Flags
		public struct Flags : OptionSet, Sendable {

			// MARK: Properties
			static	public	let	created = Flags(rawValue: 1 << 0)
			static	public	let	removed = Flags(rawValue: 1 << 1)
			static	public	let	renamed = Flags(rawValue: 1 << 2)
			static	public	let	modifiedContent = Flags(rawValue: 1 << 3)
			static	public	let	modifiedInodeMetadata = Flags(rawValue: 1 << 4)
			static	public	let	modifiedFinderInfo = Flags(rawValue: 1 << 5)
			static	public	let	modifiedOwner = Flags(rawValue: 1 << 6)
			static	public	let	modifiedExtendedAttributes = Flags(rawValue: 1 << 7)

			static	public	let	mustScanChildren = Flags(rawValue: 1 << 8)

					public	let	rawValue :Int

			// MARK: Lifecycle methods
			public init(rawValue :Int) { self.rawValue = rawValue }
		}

		// MARK: Properties
		public	let	folder :Folder
		public	let	eventID :FSEventStreamEventId
		public	let	flags :Flags
	}

	// MARK: FileInfo
	public struct FileInfo {

		// MARK: Flags
		public struct Flags : OptionSet, Sendable {

			// MARK: Properties
			static	public	let	created = Flags(rawValue: 1 << 0)
			static	public	let	removed = Flags(rawValue: 1 << 1)
			static	public	let	renamed = Flags(rawValue: 1 << 2)
			static	public	let	modifiedContent = Flags(rawValue: 1 << 3)
			static	public	let	modifiedInodeMetadata = Flags(rawValue: 1 << 4)
			static	public	let	modifiedFinderInfo = Flags(rawValue: 1 << 5)
			static	public	let	modifiedOwner = Flags(rawValue: 1 << 6)
			static	public	let	modifiedExtendedAttributes = Flags(rawValue: 1 << 7)

					public	let	rawValue :Int

			// MARK: Lifecycle methods
			public init(rawValue :Int) { self.rawValue = rawValue }
		}

		// MARK: Properties
		public	let	file :File
		public	let	eventID :FSEventStreamEventId
		public	let	flags :Flags
	}

	public typealias FoldersProc = (_ folderInfos :[FolderInfo]) -> Void
	public typealias FilesProc = (_ fileInfos :[FileInfo]) -> Void

	// MARK: Properties
	public	var	latestEventID :FSEventStreamEventId { FSEventStreamGetLatestEventId(self.eventStreamRef) }

	private	let	foldersProc :FoldersProc
	private	let	filesProc :FilesProc?

	private	var	eventStreamRef :FSEventStreamRef!

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ folders :[Folder], since eventID :FSEventStreamEventId? = nil, eventLatency: TimeInterval = 0.0,
			foldersProc :@escaping FoldersProc, filesProc :FilesProc? = nil) {
		// Store
		self.foldersProc = foldersProc
		self.filesProc = filesProc

		// Setup
		let	eventStreamCallback :FSEventStreamCallback =
					{ eventStreamRef, contextInfo, eventCount, eventPaths, eventFlags, eventIDs in
						// Setup
						guard let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] else { return }

						let	filesystemEventsTracker = unsafeBitCast(contextInfo, to: FilesystemEventsTracker.self)

						// Iterate all events
						var	folderInfos = [FolderInfo]()
						var	fileInfos = [FileInfo]()
						for i in 0..<eventCount {
							// Setup
							let	thisEventFlags = Int(eventFlags[i])
							
							// Check for special flags
							guard (thisEventFlags & kFSEventStreamEventFlagHistoryDone) == 0 else {
								// History done
								continue;
							}
							guard (thisEventFlags & kFSEventStreamEventFlagRootChanged) == 0 else {
								// Root changed
								continue;
							}
							guard (thisEventFlags & kFSEventStreamEventFlagMount) == 0 else {
								// Root changed
								continue;
							}
							guard (thisEventFlags & kFSEventStreamEventFlagUnmount) == 0 else {
								// Root changed
								continue;
							}

							// Check event type
							if (filesystemEventsTracker.filesProc == nil) ||
									((thisEventFlags & kFSEventStreamEventFlagItemIsFile) == 0) {
								// Folder/Symlink/Hard link
								var	folderFlags = FolderInfo.Flags()
								if (thisEventFlags & kFSEventStreamEventFlagItemCreated) != 0 {
									// Created
									folderFlags.insert(.created)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemRemoved) != 0 {
									// Removed
									folderFlags.insert(.removed)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemInodeMetaMod) != 0 {
									// Modified inode metadata
									folderFlags.insert(.modifiedInodeMetadata)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemRenamed) != 0 {
									// Renamed
									folderFlags.insert(.renamed)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemModified) != 0 {
									// Modified content
									folderFlags.insert(.modifiedContent)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemFinderInfoMod) != 0 {
									// Modified Extended Attributes
									folderFlags.insert(.modifiedFinderInfo)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemChangeOwner) != 0 {
									// Modified Extended Attributes
									folderFlags.insert(.modifiedOwner)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemXattrMod) != 0 {
									// Modified Extended Attributes
									folderFlags.insert(.modifiedExtendedAttributes)
								}
								if (thisEventFlags & kFSEventStreamEventFlagMustScanSubDirs) != 0 {
									// Must scan children
									folderFlags.insert(.mustScanChildren)
								}

								// Add info
								folderInfos.append(
										FolderInfo(folder: Folder(URL(fileURLWithPath: paths[i])), eventID: eventIDs[i],
												flags: folderFlags))
							} else {
								// File
								var	fileFlags = FileInfo.Flags()
								if (thisEventFlags & kFSEventStreamEventFlagItemCreated) != 0 {
									// Created
									fileFlags.insert(.created)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemRemoved) != 0 {
									// Removed
									fileFlags.insert(.removed)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemInodeMetaMod) != 0 {
									// Modified inode metadata
									fileFlags.insert(.modifiedInodeMetadata)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemRenamed) != 0 {
									// Renamed
									fileFlags.insert(.renamed)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemModified) != 0 {
									// Modified content
									fileFlags.insert(.modifiedContent)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemFinderInfoMod) != 0 {
									// Modified Extended Attributes
									fileFlags.insert(.modifiedFinderInfo)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemChangeOwner) != 0 {
									// Modified Extended Attributes
									fileFlags.insert(.modifiedOwner)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemXattrMod) != 0 {
									// Modified Extended Attributes
									fileFlags.insert(.modifiedExtendedAttributes)
								}

								// Add info
								fileInfos.append(
										FileInfo(file: File(URL(fileURLWithPath: paths[i])), eventID: eventIDs[i],
												flags: fileFlags))
							}
						}

						// Call procs
						if !folderInfos.isEmpty {
							// Call proc
							filesystemEventsTracker.foldersProc(folderInfos.sorted(by: { $0.eventID < $1.eventID }))
						}
						if !fileInfos.isEmpty {
							// Call proc
							filesystemEventsTracker.filesProc?(fileInfos.sorted(by: { $0.eventID < $1.eventID }))
						}
					}

		var	eventStreamContext =
					FSEventStreamContext(version: 0, info: nil, retain: nil, release: nil, copyDescription: nil)
		eventStreamContext.info = Unmanaged.passUnretained(self).toOpaque()

		var	eventStreamCreateFlags = kFSEventStreamCreateFlagUseCFTypes
		if self.filesProc != nil {
			// Interested in file events
			eventStreamCreateFlags |= kFSEventStreamCreateFlagFileEvents
		}

		self.eventStreamRef =
				FSEventStreamCreate(kCFAllocatorDefault, eventStreamCallback, &eventStreamContext,
						(folders.map({ $0.path })) as CFArray,
						eventID ?? FSEventStreamEventId(kFSEventStreamEventIdSinceNow), eventLatency,
						FSEventStreamCreateFlags(eventStreamCreateFlags))
		FSEventStreamSetDispatchQueue(self.eventStreamRef, DispatchQueue.global(qos: .background))
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
		// Stop and cleanup
		FSEventStreamStop(self.eventStreamRef)
		FSEventStreamInvalidate(self.eventStreamRef)
		FSEventStreamRelease(self.eventStreamRef)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func start() {
		// Start
		FSEventStreamStart(self.eventStreamRef)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func stop() {
		// Stop
		FSEventStreamStop(self.eventStreamRef)
	}
}
