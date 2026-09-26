//
//  TableViewBacking.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/18/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: TableViewBacking
@MainActor
public class TableViewBacking : NSObject {

	// MARK: Item
	@objc(TableViewBackingItem)
	class Item : NSObject {

		// MARK: Properties
				let	id :String
		@objc	let	object :Any

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		@objc(initWithID:object:)
		init(id :String, object :Any) {
			// Store
			self.id = id
			self.object = object
		}
	}

	// MARK: Properties
	@objc			var	count :Int { self.itemIDsSorted.count }
	@objc			var	objects :[Any] { self.itemIDsSorted.map({ self.itemByItemID[$0]!.object }) }

	@objc			var	compareItemsProc
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

			private	var	itemByItemID = [String : Item]()

			private	var	itemIDs = [String]() { didSet { self.itemIDsSorted = self.itemIDs } }
			private	var	itemIDsSorted = [String]()

			private	var	sortDescriptors = [NSSortDescriptor]()

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func itemID(at index :Int) -> String { self.itemIDsSorted[index] }

	//------------------------------------------------------------------------------------------------------------------
	public func index(of itemID :String) -> Int? { self.itemIDsSorted.firstIndex(of: itemID) }

	//------------------------------------------------------------------------------------------------------------------
	@objc(setItems:)
	func set(items :[Item]) {
		// Reset
		self.itemByItemID.removeAll()
		self.itemIDs.removeAll()

		// Add
		add(items: items)
	}

	//------------------------------------------------------------------------------------------------------------------
	@objc(addItems:)
	func add(items :[Item]) {
		// Update
		self.itemByItemID += Dictionary(items.map({ ($0.id, $0) }))
		self.itemIDs += items.map({ $0.id })

		// Check if have sorting
		if !self.sortDescriptors.isEmpty {
			// Update sorting
			updateSorting()
		}

		// Note content updated
		noteContentUpdated()
	}

	//------------------------------------------------------------------------------------------------------------------
	@objc(removeItems:)
	func remove(items :[Item]) {
		// Setup
		let	itemIDs = items.map({ $0.id })

		// Update
		self.itemByItemID.removeValues(forKeys: itemIDs)
		self.itemIDs -= itemIDs

		// Note content updated
		noteContentUpdated()
	}

	//------------------------------------------------------------------------------------------------------------------
	func object(for itemID :String) -> Any { self.itemByItemID[itemID]!.object }

	//------------------------------------------------------------------------------------------------------------------
	@objc(objectsFor:)
	func objects(for itemIDs :[String]) -> [Any] { itemIDs.map({ self.itemByItemID[$0]!.object }) }

	//------------------------------------------------------------------------------------------------------------------
	@objc(setSortDescriptors:)
	func set(sortDescriptors :[NSSortDescriptor]) {
		// Store
		self.sortDescriptors = sortDescriptors

		// Check if now have sorting
		if !self.sortDescriptors.isEmpty {
			// Update sorting
			updateSorting()
		} else {
			// Restore given order
			self.itemIDsSorted = self.itemIDs
		}

		// Note content updated
		noteContentUpdated()
	}

	// MARK: Subclass methods
	//------------------------------------------------------------------------------------------------------------------
	func noteContentUpdated() {}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func updateSorting() {
		// Sort
		self.itemIDsSorted =
				self.itemIDsSorted
						.map({ self.itemByItemID[$0]! })
						.sorted(by: { self.compareItemsProc($0, $1, self.sortDescriptors) })
						.map({ $0.id })
	}
}
