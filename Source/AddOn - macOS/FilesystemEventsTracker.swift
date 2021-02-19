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

	// MARK: Types
	public struct FolderFlags : OptionSet {

		// MARK: Properties
		static	public	let	mustScanChildren = FolderFlags(rawValue: 1 << 0)

				public	let	rawValue :Int

		// MARK: Lifecycle methods
		public init(rawValue :Int) { self.rawValue = rawValue }
	}

	public struct FolderInfo {

		// MARK: Properties
		public	let	folder :Folder
		public	let	eventID :FSEventStreamEventId
		public	let	flags :FolderFlags
	}

	public struct FileFlags : OptionSet {

		// MARK: Properties
		static	public	let	created = FileFlags(rawValue: 1 << 0)
		static	public	let	removed = FileFlags(rawValue: 1 << 1)
		static	public	let	renamed = FileFlags(rawValue: 1 << 2)
		static	public	let	modified = FileFlags(rawValue: 1 << 3)
		static	public	let	extendedAttributesModified = FileFlags(rawValue: 1 << 4)

				public	let	rawValue :Int

		// MARK: Lifecycle methods
		public init(rawValue :Int) { self.rawValue = rawValue }
	}

	public struct FileInfo {

		// MARK: Properties
		public	let	file :File
		public	let	eventID :FSEventStreamEventId
		public	let	flags :FileFlags
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
	public init(_ folders :[Folder],
			since eventID :FSEventStreamEventId = FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
			eventLatency: TimeInterval = 0.0, foldersProc :@escaping FoldersProc, filesProc :FilesProc? = nil) {
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
								var	folderFlags = FolderFlags()
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
								var	fileFlags = FileFlags()
								if (thisEventFlags & kFSEventStreamEventFlagItemCreated) != 0 {
									// Created
									fileFlags.insert(.created)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemRemoved) != 0 {
									// Removed
									fileFlags.insert(.removed)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemRenamed) != 0 {
									// Renamed
									fileFlags.insert(.renamed)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemModified) != 0 {
									// Modified
									fileFlags.insert(.modified)
								}
								if (thisEventFlags & kFSEventStreamEventFlagItemXattrMod) != 0 {
									// Extended Attributes Modified
									fileFlags.insert(.extendedAttributesModified)
								}

								// Add info
								fileInfos.append(
										FileInfo(file: File(URL(fileURLWithPath: paths[i])), eventID: eventIDs[i],
												flags: fileFlags))
							}
						}

						// Call procs
						if !folderInfos.isEmpty { filesystemEventsTracker.foldersProc(folderInfos) }
						if !fileInfos.isEmpty { filesystemEventsTracker.filesProc?(fileInfos) }
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
						(folders.map({ $0.path })) as CFArray, eventID, eventLatency,
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
