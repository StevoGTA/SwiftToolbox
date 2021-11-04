//
//  Tree.swift
//  Swift Toolbox
//
//  Created by Stevo on 4/22/21.
//  Copyright © 2021 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: TreeGroup
protocol TreeGroup : TreeItem {}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - TreeBuilder
class TreeBuilder<G : TreeGroup, GInfo : Any, I : TreeItem, IInfo : Any> {

	// MARK: Types
	typealias CreateGroupProc = (_ subPath :String, _ info :GInfo?, _ groups :[G]?, _ items :[I]?) -> G
	typealias CreateItemProc = (_ subPath :String, _ info :IInfo?) -> I

	// MARK: Tracker
	private class GroupTracker {

		// MARK: Properties
				var	info :GInfo?

		private	let	subPath :String

		private var	childGroupTrackers :[GroupTracker]?
		private	var	childItemInfos :[/* Name */ String : IInfo?]?

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(subPath :String, info :GInfo? = nil) {
			// Store
			self.subPath = subPath
			self.info = info
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		func add(_ groupTracker :GroupTracker) {
			// Setup
			self.childGroupTrackers = self.childGroupTrackers ?? [GroupTracker]()

			// Add
			self.childGroupTrackers!.append(groupTracker)
		}

		//--------------------------------------------------------------------------------------------------------------
		func add(_ subPath :String, with info :IInfo? = nil) {
			// Setup
			self.childItemInfos = self.childItemInfos ?? [String : IInfo?]()

			// Add
			self.childItemInfos![subPath.lastPathComponent!] = info
		}

		//--------------------------------------------------------------------------------------------------------------
		func createGroup(_ createGroupProc :CreateGroupProc, _ createItemProc :CreateItemProc?) -> G {
			// Create group
			return createGroupProc(self.subPath, self.info,
					self.childGroupTrackers?.map({ $0.createGroup(createGroupProc, createItemProc) }),
					self.childItemInfos?.map(
							{ createItemProc!(self.subPath.appending(pathComponent: $0.key), $0.value) }))
		}
	}

	// MARK: Properties
			var	rootGroup :G { self.groupTrackerMap[""]!.createGroup(self.createGroupProc, self.createItemProc) }

	private	let	createGroupProc :CreateGroupProc
	private	let	createItemProc :CreateItemProc?

	private	var	groupTrackerMap = [/* Path */ String : GroupTracker]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(createGroupProc :@escaping CreateGroupProc, createItemProc :CreateItemProc? = nil) {
		// Store
		self.createGroupProc = createGroupProc
		self.createItemProc = createItemProc

		// Create root group tracker
		self.groupTrackerMap[""] = GroupTracker(subPath: "")
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func addGroup(at subPath :String, with info :GInfo? = nil) {
		// Check if already have a GroupTracker
		if let groupTracker = self.groupTrackerMap[subPath] {
			// Have GroupTracker
			groupTracker.info = info
		} else {
			// Setup
			let	groupTracker = GroupTracker(subPath: subPath, info: info)
			let	folder = subPath.deletingLastPathComponent

			// Add group tracker
			self.groupTrackerMap[subPath] = groupTracker

			// Check if have GroupTracker for folder
			if self.groupTrackerMap[folder] == nil {
				// Add Group for parent
				addGroup(at: folder)
			}

			// Add to parent
			self.groupTrackerMap[folder]!.add(groupTracker)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func addItem(at path :String, with info :IInfo? = nil) {
		// Add item to parent group tracker
		self.groupTrackerMap[path.deletingLastPathComponent]!.add(path.lastPathComponent!, with: info)
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - GroupTreeBuilder
struct VoidTreeItem : TreeItem {}

class GroupTreeBuilder<G : TreeGroup> : TreeBuilder<G, String, VoidTreeItem, Void> {

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func rootGroup(for groupPaths :[String], createGroupProc :@escaping CreateGroupProc) -> G {
		// Setup
		let	treeBuilder = TreeBuilder<G, String, VoidTreeItem, Void>(createGroupProc: createGroupProc)
		groupPaths.sorted().forEach() { treeBuilder.addGroup(at: $0) }

		return treeBuilder.rootGroup
	}
}
