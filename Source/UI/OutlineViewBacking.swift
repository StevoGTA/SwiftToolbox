//
//  OutlineViewBacking.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/18/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: OutlineViewBacking
@MainActor
public class OutlineViewBacking : NSObject {

	// MARK: Item
	@objc(OutlineViewBackingItem)
	class Item : NSObject {

		// MARK: Properties
				let	id :String
		@objc	let	object :Any
				let	childCount :Int

				var	needsReload = true

				var	childItemIDs = [String]() { didSet { self.childItemIDsSorted = self.childItemIDs } }
				var	childItemIDsSorted = [String]()

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		@objc(initWithID:object:childCount:)
		init(id :String, object :Any, childCount :Int = 0) {
			// Store
			self.id = id
			self.object = object
			self.childCount = childCount
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		fileprivate func reset() {
			// Reset
			self.childItemIDs.removeAll()
			self.childItemIDsSorted.removeAll()
		}
	}

	// MARK: Properties
	@objc			var	topLevelObjects :[Any] { self.topLevelItemIDsSorted.map({ self.itemByItemID[$0]!.object }) }

	@objc			var	compareObjectsProc
								:(_ item1 :Item, _ item2 :Item, _ sortDescriptors :[NSSortDescriptor]) -> Bool =
								{
									// Iterate sort descriptors
									for sortDescriptor in $2 {
										// Compare
										switch sortDescriptor.compare($0, to: $1) {
											case .orderedAscending:		return sortDescriptor.ascending
											case .orderedDescending:	return !sortDescriptor.ascending
											case .orderedSame:			break
										}
									}

									return false
								}
	@objc			var	reloadChildItemsProc :(_ object :Any) -> [Item] = { _ in [] }

			private	var	itemByItemID = [String : Item]()

			private	var	topLevelItemIDs = [String]() { didSet { self.topLevelItemIDsSorted = self.topLevelItemIDs } }
			private	var	topLevelItemIDsSorted = [String]()

			private	var	sortDescriptors = [NSSortDescriptor]()

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func childCount(for itemID :String?) -> Int {
		// Return count
		return (itemID == nil) ? self.topLevelItemIDs.count : (self.itemByItemID[itemID!]?.childCount ?? 0)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func childItemID(for itemID :String?, at index :Int) -> String {
		// Check level
		if let itemID {
			// Child
			let	parentItem = self.itemByItemID[itemID]!
			if parentItem.needsReload {
				// Remove any current values
				self.itemByItemID.removeValues(forKeys: parentItem.childItemIDs)
				parentItem.childItemIDs.removeAll()

				// Reload
				let	childItems = self.reloadChildItemsProc(parentItem.object)

				// Update
				self.itemByItemID += Dictionary(childItems.map({ ($0.id, $0) }))
				parentItem.childItemIDs += childItems.map({ $0.id })
				parentItem.childItemIDsSorted = parentItem.childItemIDs

				// Check if have sorting
				if !self.sortDescriptors.isEmpty {
					// Sort
					updateSorting(itemIDs: &parentItem.childItemIDsSorted)
				}
			}

			return parentItem.childItemIDsSorted[index]
		} else {
			// Top-level
			return self.topLevelItemIDsSorted[index]
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	@objc(setItems:forParentItemID:)
	func set(items :[Item], for parentItemID :String? = nil) {
		// Check level
		if let parentItemID {
			// Child
			guard let parentItem = self.itemByItemID[parentItemID] else { return }

			// Update
			self.itemByItemID.removeValues(forKeys: parentItem.childItemIDs)
			parentItem.reset()
		} else {
			// Top level
			self.itemByItemID.removeAll()
			self.topLevelItemIDs.removeAll()
			self.topLevelItemIDsSorted.removeAll()
		}

		// Add
		add(items: items, to: parentItemID)
	}

	//------------------------------------------------------------------------------------------------------------------
	@objc(addItems:toParentItemID:)
	func add(items :[Item], to parentItemID :String? = nil) {
		// Check level
		if let parentItemID {
			// Child
			guard let parentItem = self.itemByItemID[parentItemID] else { return }

			// Update
			self.itemByItemID += Dictionary(items.map({ ($0.id, $0) }))
			parentItem.childItemIDs += items.map({ $0.id })
			parentItem.childItemIDsSorted = parentItem.childItemIDs

			// Check if have sorting
			if !self.sortDescriptors.isEmpty {
				// Update sorting
				updateSorting(itemIDs: &parentItem.childItemIDs)
			}
		} else {
			// Top-level
			self.itemByItemID += Dictionary(items.map({ ($0.id, $0) }))
			self.topLevelItemIDs += items.map({ $0.id })
			self.topLevelItemIDsSorted = self.topLevelItemIDs

			// Check if have sorting
			if !self.sortDescriptors.isEmpty {
				// Update sorting
				updateSorting(itemIDs: &self.topLevelItemIDsSorted)
			}
		}

		// Note content updated
		noteContentUpdated()
	}

	//------------------------------------------------------------------------------------------------------------------
	@objc(removeItems:fromParentItemID:)
	func remove(items :[Item], from parentItemID :String? = nil) {
		// Setup
		let	itemIDs = items.map({ $0.id })

		// Check level
		if let parentItemID {
			// Child
			guard let parentItem = self.itemByItemID[parentItemID] else { return }

			// Update
			self.itemByItemID.removeValues(forKeys: itemIDs)
			parentItem.childItemIDs -= itemIDs
			parentItem.childItemIDsSorted -= itemIDs
		} else {
			// Top-level
			items.forEach() { self.itemByItemID.removeValues(forKeys: self.itemByItemID[$0.id]?.childItemIDs ?? []) }
			self.itemByItemID.removeValues(forKeys: itemIDs)
			self.topLevelItemIDs -= itemIDs
			self.topLevelItemIDsSorted -= itemIDs
		}

		// Note content updated
		noteContentUpdated()
	}

	//------------------------------------------------------------------------------------------------------------------
	func object(for itemID :String) -> Any { self.itemByItemID[itemID]!.object }

	//------------------------------------------------------------------------------------------------------------------
	@objc(objectsFor:)
	func objects(for itemIDs :[String]) -> [Any] { itemIDs.map({ self.itemByItemID[$0]! }).map({ $0.object }) }

	//------------------------------------------------------------------------------------------------------------------
	@objc(setSortDescriptors:)
	func set(sortDescriptors :[NSSortDescriptor]) {
		// Store
		self.sortDescriptors = sortDescriptors

		// Check if hnow have sorting
		if !self.sortDescriptors.isEmpty {
			// Update Top-level items
			updateSorting(itemIDs: &self.topLevelItemIDsSorted)

			// Iterate all items looking for child items
			self.itemByItemID.values.forEach() {
				// Check if has chikd items
				if !$0.childItemIDs.isEmpty {
					// Sort child items
					updateSorting(itemIDs: &$0.childItemIDsSorted)
				}
			}

			// Note content updated
			noteContentUpdated()
		}
	}

	// MARK: Subclass methods
	//------------------------------------------------------------------------------------------------------------------
	func noteContentUpdated() {}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func updateSorting(itemIDs :inout [String]) {
		// Sort
		itemIDs =
				itemIDs
						.map({ self.itemByItemID[$0]! })
						.sorted(by: { self.compareObjectsProc($0, $1, self.sortDescriptors) })
						.map({ $0.id })
	}
}
