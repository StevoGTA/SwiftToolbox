//
//  TreeViewBacking.swift
//  Swift Toolbox
//
//  Created by Stevo on 5/11/21.
//  Copyright © 2021 Stevo Brock. All rights reserved.
//

import Foundation

/*
	Need to add filtering
	Need to add asynchronous loading
*/

//----------------------------------------------------------------------------------------------------------------------
// MARK: TreeViewBacking
class TreeViewBacking {

	// MARK: Types
	typealias ChildTreeItemsProc = (_ treeItem :TreeItem) -> [TreeItem]

	typealias HasChildTreeItemsProc = (_ treeItem :TreeItem) -> Bool
	typealias LoadChildTreeItemsProc =
				(_ treeItem :TreeItem, _ completionProc :(_ treeItems :[TreeItem]) -> Void) -> Void

	typealias CompareTreeItemsProc = (_ treeItem1 :TreeItem, _ treeItem2 :TreeItem) -> Bool

	// MARK: Info
	private class Info {

		// MARK: Properties
		var	childTreeItemsProc :ChildTreeItemsProc?

		var	hasChildTreeItemsProc :HasChildTreeItemsProc?
		var	loadChildTreeItemsProc :LoadChildTreeItemsProc?

		var	compareTreeItemsProc :CompareTreeItemsProc = { _,_ in false }

		var	removeViewItemIDsProc :(_ viewItemIDs :[String]) -> Void = { _ in }
		var	noteItemsProc :(_ items :[Item]) -> Void = { _ in }
	}

	// MARK: Item
	private class Item {

		// MARK: Properties
						let	treeItem :TreeItem
						let	viewItemID :String

#if os(iOS)
						let	indentationLevel :Int
#endif

		private(set)	var	childViewItemIDs = [String]()

		private			let	info :Info

		private			var	needsReload = true
		private			var	reloadInProgress = false

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
#if os(iOS)
		init(treeItem :TreeItem, viewItemID :String = UUID().base64EncodedString, indentationLevel :Int, info :Info) {
			// Store
			self.indentationLevel = indentationLevel

			self.treeItem = treeItem
			self.viewItemID = viewItemID

			self.info = info
		}
#else
		init(treeItem :TreeItem, viewItemID :String = UUID().base64EncodedString, info :Info) {
			// Store
			self.treeItem = treeItem
			self.viewItemID = viewItemID

			self.info = info
		}
#endif

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		func noteNeedsReload() { self.needsReload = true }

		//--------------------------------------------------------------------------------------------------------------
		func reloadChildItems() {
			// Check if needs reload
			guard self.needsReload && !self.reloadInProgress else { return }
			self.reloadInProgress = true

			// Remove existing items
			self.info.removeViewItemIDsProc(self.childViewItemIDs)
			self.childViewItemIDs.removeAll()

			// Check how to reload child items
			if let childTreeItemsProc = self.info.childTreeItemsProc {
				// Get child tree items
				let	childTreeItems = childTreeItemsProc(self.treeItem).sorted(by: self.info.compareTreeItemsProc)
#if os(iOS)
				let	childItems =
							childTreeItems.map({
									Item(treeItem: $0, indentationLevel: self.indentationLevel + 1, info: self.info) })
#else
				let	childItems = childTreeItems.map({ Item(treeItem: $0, info: self.info) })
#endif
				self.info.noteItemsProc(childItems)
				self.childViewItemIDs = childItems.map({ $0.viewItemID })

				// Done
				self.needsReload = false
				self.reloadInProgress = false
			} else {
				// Load child tree items
			}
		}
	}

	// MARK: Properties
	static			let	rootViewItemID = "ROOT"

					var	childTreeItemsProc :ChildTreeItemsProc? {
								get { self.info.childTreeItemsProc }
								set { self.info.childTreeItemsProc = newValue }
							}

					var	hasChildTreeItemsProc :HasChildTreeItemsProc? {
								get { self.info.hasChildTreeItemsProc }
								set { self.info.hasChildTreeItemsProc = newValue }
							}
					var	loadChildTreeItemsProc :LoadChildTreeItemsProc? {
								get { self.info.loadChildTreeItemsProc }
								set { self.info.loadChildTreeItemsProc = newValue }
							}

					var	compareTreeItemsProc :CompareTreeItemsProc {
								get { self.info.compareTreeItemsProc }
								set { self.info.compareTreeItemsProc = newValue }
							}

			private	let	info = Info()

			private	var	itemMap = [/* viewItemID */ String : Item]()
			private	var	topLevelViewItemIDs = [String]()

			private	var	rootItem :Item? { self.itemMap[type(of: self).rootViewItemID] }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init() {
		// Setup
		self.info.removeViewItemIDsProc = { [unowned self] in self.itemMap.removeValues(forKeys: $0) }
		self.info.noteItemsProc = { [unowned self] in $0.forEach() { self.itemMap[$0.viewItemID] = $0 } }
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func set(rootTreeItem :TreeItem) {
		// Setup
#if os(iOS)
		let	item =
					Item(treeItem: rootTreeItem, viewItemID: type(of: self).rootViewItemID, indentationLevel: -1,
							info: self.info)
#else
		let	item = Item(treeItem: rootTreeItem, viewItemID: type(of: self).rootViewItemID, info: self.info)
#endif
		self.itemMap = [item.viewItemID : item]
		self.topLevelViewItemIDs.removeAll()
	}

	//------------------------------------------------------------------------------------------------------------------
	func set(topLevelTreeItems :[TreeItem]) {
		// Setup
		self.itemMap.removeAll()
		self.topLevelViewItemIDs.removeAll()

		add(topLevelTreeItems: topLevelTreeItems)
	}

	//------------------------------------------------------------------------------------------------------------------
	func add(topLevelTreeItems :[TreeItem]) {
		// Iterate
		topLevelTreeItems.forEach() {
			// Setup
#if os(iOS)
			let	item = Item(treeItem: $0, indentationLevel: 0, info: self.info)
#else
			let	item = Item(treeItem: $0, info: self.info)
#endif

			// Store
			self.itemMap[item.viewItemID] = item
			self.topLevelViewItemIDs.append(item.viewItemID)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func topLevelTreeItems() -> [TreeItem] { self.topLevelViewItemIDs.map({ self.itemMap[$0]!.treeItem }) }

	//------------------------------------------------------------------------------------------------------------------
	func treeItem(for viewItemID :String) -> TreeItem { self.itemMap[viewItemID]!.treeItem }

	//------------------------------------------------------------------------------------------------------------------
	func treeItems(for viewItemIDs :[String]) -> [TreeItem] { viewItemIDs.map({ self.itemMap[$0]!.treeItem }) }

	//------------------------------------------------------------------------------------------------------------------
	func hasChildren(for viewItemID :String) -> Bool {
		// Setup
		let	item = self.itemMap[viewItemID]!

		// Check if have proc
		if let hasChildTreeItemsProc = self.hasChildTreeItemsProc {
			// Query proc
			return hasChildTreeItemsProc(item.treeItem)
		} else {
			// Reload
			item.reloadChildItems()

			return !item.childViewItemIDs.isEmpty
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func childCount(for viewItemID :String) -> Int {
		// Setup
		let	item = self.itemMap[viewItemID]

		// Check situation
		if (viewItemID == type(of: self).rootViewItemID) && (item == nil) {
			// Requesting root item, but no root item
			return self.topLevelViewItemIDs.count
		} else {
			// Reload
			item!.reloadChildItems()

			return item!.childViewItemIDs.count
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func childViewItemID(for viewItemID :String, index :Int) -> String {
		// Return child view itme ID
		self.itemMap[viewItemID]!.childViewItemIDs[index]
	}

#if os(iOS)
	//------------------------------------------------------------------------------------------------------------------
	func viewItemIDs(with expandedViewItemIDs :Set<String>) -> [String] {
		// Return view item IDs
		if let rootItem = self.rootItem {
			// Have root item
			rootItem.reloadChildItems()

			return rootItem
					.childViewItemIDs
					.flatMap({ self.childViewItemIDsDeep(for: self.itemMap[$0]!, with: expandedViewItemIDs) })
		} else {
			// Have top-level items
			return self.topLevelViewItemIDs
					.flatMap({ self.childViewItemIDsDeep(for: self.itemMap[$0]!, with: expandedViewItemIDs) })
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func indentationLevel(for viewItemID :String) -> Int { self.itemMap[viewItemID]!.indentationLevel }
#endif

	//------------------------------------------------------------------------------------------------------------------
	func noteNeedsReload(viewItemID :String) { self.itemMap[viewItemID]!.noteNeedsReload() }

	// MARK: Private methods
#if os(iOS)
	//--------------------------------------------------------------------------------------------------------------
	private func childViewItemIDsDeep(for item :Item, with expandedViewItemIDs :Set<String>) -> [String] {
		// Check if expanded
		if expandedViewItemIDs.contains(item.viewItemID) {
			// Reload
			item.reloadChildItems()

			return [item.viewItemID] +
					item.childViewItemIDs.flatMap(
							{ self.childViewItemIDsDeep(for: self.itemMap[$0]!, with: expandedViewItemIDs) })
		} else {
			// Just this level
			return [item.viewItemID]
		}
	}
#endif
}
