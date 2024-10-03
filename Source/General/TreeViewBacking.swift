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
public class TreeViewBacking : NSObject {

	// MARK: Types
	public typealias ChildTreeItemsProc = (_ treeItem :TreeItem) -> [TreeItem]

	public typealias HasChildTreeItemsProc = (_ treeItem :TreeItem) -> Bool
	public typealias LoadChildTreeItemsProc =
				(_ treeItem :TreeItem, _ completionProc :(_ treeItems :[TreeItem]) -> Void) -> Void

	public typealias CompareTreeItemsProc = (_ treeItem1 :TreeItem, _ treeItem2 :TreeItem) -> Bool

	// MARK: Info
	private class Info {

		// MARK: Properties
		var	childTreeItemsProc :ChildTreeItemsProc?

		var	hasChildTreeItemsProc :HasChildTreeItemsProc?
		var	loadChildTreeItemsProc :LoadChildTreeItemsProc?

		var	compareTreeItemsProc :CompareTreeItemsProc = { _,_ in false }

		var	removeItemIDsProc :(_ itemIDs :[String]) -> Void = { _ in }
		var	noteItemsProc :(_ items :[Item]) -> Void = { _ in }
	}

	// MARK: Item
	private class Item {

		// MARK: Properties
						let	treeItem :TreeItem
						let	id :String

#if os(iOS)
						let	indentationLevel :Int
#endif

		private(set)	var	childItemIDs = [String]()

		private			let	info :Info

		private			var	needsReload = true
		private			var	reloadInProgress = false

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
#if os(iOS)
		init(treeItem :TreeItem, id :String = UUID().base64EncodedString, indentationLevel :Int, info :Info) {
			// Store
			self.indentationLevel = indentationLevel

			self.treeItem = treeItem
			self.id = id

			self.info = info
		}
#else
		init(treeItem :TreeItem, id :String = UUID().base64EncodedString, info :Info) {
			// Store
			self.treeItem = treeItem
			self.id = id

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
			self.info.removeItemIDsProc(self.childItemIDs)
			self.childItemIDs.removeAll()

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
				self.childItemIDs = childItems.map({ $0.id })

				// Done
				self.needsReload = false
				self.reloadInProgress = false
			} else {
				// Load child tree items
			}
		}
	}

	// MARK: Properties
	static	public	let	rootItemID = "ROOT"

			public	var	rootTreeItem :TreeItem? { self.rootItem?.treeItem }
			public	var	loadedTreeItems :[TreeItem] { self.itemByID.values.map({ $0.treeItem }) }

			public	var	childTreeItemsProc :ChildTreeItemsProc? {
								get { self.info.childTreeItemsProc }
								set { self.info.childTreeItemsProc = newValue }
							}

			public	var	hasChildTreeItemsProc :HasChildTreeItemsProc? {
								get { self.info.hasChildTreeItemsProc }
								set { self.info.hasChildTreeItemsProc = newValue }
							}
			public	var	loadChildTreeItemsProc :LoadChildTreeItemsProc? {
								get { self.info.loadChildTreeItemsProc }
								set { self.info.loadChildTreeItemsProc = newValue }
							}

			public	var	compareTreeItemsProc :CompareTreeItemsProc {
								get { self.info.compareTreeItemsProc }
								set { self.info.compareTreeItemsProc = newValue }
							}

			private	let	info = Info()

			private	var	itemByID = [String : Item]()
			private	var	topLevelItemIDs = [String]()

			private	var	rootItem :Item? { self.itemByID[type(of: self).rootItemID] }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	override init() {
		// Do super
		super.init()

		// Setup
		self.info.removeItemIDsProc = { [unowned self] in self.itemByID.removeValues(forKeys: $0) }
		self.info.noteItemsProc = { [unowned self] in $0.forEach() { self.itemByID[$0.id] = $0 } }
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func set(rootTreeItem :TreeItem) {
		// Setup
#if os(iOS)
		let	item = Item(treeItem: rootTreeItem, id: type(of: self).rootItemID, indentationLevel: -1, info: self.info)
#else
		let	item = Item(treeItem: rootTreeItem, id: type(of: self).rootItemID, info: self.info)
#endif
		self.itemByID = [item.id : item]
		self.topLevelItemIDs.removeAll()
	}

	//------------------------------------------------------------------------------------------------------------------
	public func set(topLevelTreeItems :[TreeItem]) {
		// Setup
		self.itemByID.removeAll()
		self.topLevelItemIDs.removeAll()

		add(topLevelTreeItems: topLevelTreeItems)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func add(topLevelTreeItems :[TreeItem]) {
		// Iterate
		topLevelTreeItems.forEach() {
			// Setup
#if os(iOS)
			let	item = Item(treeItem: $0, indentationLevel: 0, info: self.info)
#else
			let	item = Item(treeItem: $0, info: self.info)
#endif

			// Store
			self.itemByID[item.id] = item
			self.topLevelItemIDs.append(item.id)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func topLevelTreeItems() -> [TreeItem] { self.topLevelItemIDs.map({ self.itemByID[$0]!.treeItem }) }

	//------------------------------------------------------------------------------------------------------------------
	public func treeItem(for itemID :String) -> TreeItem { self.itemByID[itemID]!.treeItem }

	//------------------------------------------------------------------------------------------------------------------
	public func treeItems(for itemIDs :[String]) -> [TreeItem] { itemIDs.map({ self.itemByID[$0]!.treeItem }) }

	//------------------------------------------------------------------------------------------------------------------
	public func hasChildren(of itemID :String) -> Bool {
		// Setup
		let	item = self.itemByID[itemID]!

		// Check if have proc
		if let hasChildTreeItemsProc = self.hasChildTreeItemsProc {
			// Query proc
			return hasChildTreeItemsProc(item.treeItem)
		} else {
			// Reload
			item.reloadChildItems()

			return !item.childItemIDs.isEmpty
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func childCount(of itemID :String) -> Int {
		// Setup
		let	item = self.itemByID[itemID]

		// Check situation
		if (itemID == type(of: self).rootItemID) && (item == nil) {
			// Requesting root item, but no root item
			return self.topLevelItemIDs.count
		} else {
			// Reload
			item!.reloadChildItems()

			return item!.childItemIDs.count
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func childItemID(of itemID :String, index :Int) -> String { self.itemByID[itemID]!.childItemIDs[index] }

#if os(iOS)
	//------------------------------------------------------------------------------------------------------------------
	public func itemIDs(with expandedItemIDs :Set<String>) -> [String] {
		// Return item IDs
		if let rootItem = self.rootItem {
			// Have root item
			rootItem.reloadChildItems()

			return rootItem
					.childItemIDs
					.flatMap({ self.childItemIDsDeep(for: self.itemByID[$0]!, with: expandedItemIDs) })
		} else {
			// Have top-level items
			return self.topLevelItemIDs
					.flatMap({ self.childItemIDsDeep(for: self.itemByID[$0]!, with: expandedItemIDs) })
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func indentationLevel(for itemID :String) -> Int { self.itemByID[itemID]!.indentationLevel }
#endif

	//------------------------------------------------------------------------------------------------------------------
	public func noteNeedsReload(itemID :String) { self.itemByID[itemID]!.noteNeedsReload() }

	// MARK: Private methods
#if os(iOS)
	//--------------------------------------------------------------------------------------------------------------
	private func childItemIDsDeep(of item :Item, with expandedItemIDs :Set<String>) -> [String] {
		// Check if expanded
		if expandedItemIDs.contains(item.id) {
			// Reload
			item.reloadChildItems()

			return [item.id] +
					item.childItemIDs.flatMap({ self.childItemIDsDeep(for: self.itemByID[$0]!, with: expandedItemIDs) })
		} else {
			// Just this level
			return [item.id]
		}
	}
#endif
}
