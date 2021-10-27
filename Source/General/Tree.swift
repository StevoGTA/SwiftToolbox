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
	typealias CreateGroupProc = (_ name :String, _ info :GInfo?, _ groups :[G]?, _ items :[I]?) -> G
	typealias CreateItemProc = (_ name :String, _ info :IInfo?) -> I

	// MARK: Tracker
	private class GroupTracker {

		// MARK: Properties
		private	let	name :String
		private	let	info :GInfo?

		private var	childGroupTrackers :[GroupTracker]?
		private	var	childItemInfos :[(name :String, info :IInfo?)]?

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(name :String, info :GInfo? = nil) {
			// Store
			self.name = name
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
		func add(_ name :String, with info :IInfo? = nil) {
			// Setup
			self.childItemInfos = self.childItemInfos ?? [(name :String, info :IInfo?)]()

			// Add
			self.childItemInfos!.append((name, info))
		}

		//--------------------------------------------------------------------------------------------------------------
		func createGroup(_ createGroupProc :CreateGroupProc, _ createItemProc :CreateItemProc?) -> G {
			// Create group
			return createGroupProc(self.name, self.info,
					self.childGroupTrackers?.map({ $0.createGroup(createGroupProc, createItemProc) }),
					self.childItemInfos?.map({ createItemProc!($0.name, $0.info) }))
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
		self.groupTrackerMap[""] = GroupTracker(name: "")
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func addGroup(at path :String, with info :GInfo? = nil) {
		// Setup
		let	groupTracker = GroupTracker(name: path.lastPathComponent!, info: info)

		// Add group tracker
		self.groupTrackerMap[path] = groupTracker

		// Add to parent
		self.groupTrackerMap[path.deletingLastPathComponent]!.add(groupTracker)
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
		groupPaths.sorted().forEach() { treeBuilder.addGroup(at: $0, with: $0) }

		return treeBuilder.rootGroup
	}
}
