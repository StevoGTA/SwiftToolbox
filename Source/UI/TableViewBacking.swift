//
//  TableViewBacking.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/18/25.
//  Copyright © 2025 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: TableViewBacking
public class TableViewBacking : NSObject {

	// MARK: Item
	@objc(TableViewBackingItem)
	class Item : NSObject {

		// MARK: Properties
		let	id :String
		let	object :Any

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
	private	var	itemByItemID = [String : Item]()

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func set(items :[Item]) {
		// Store
		self.itemByItemID = Dictionary(items.map({ ($0.id, $0) }))

		// Note content updated
		noteContentUpdated()
	}

	//------------------------------------------------------------------------------------------------------------------
	func add(items :[Item]) {
		// Store
		self.itemByItemID += Dictionary(items.map({ ($0.id, $0) }))

		// Note content updated
		noteContentUpdated()
	}

	// MARK: Subclass methods
	//------------------------------------------------------------------------------------------------------------------
	func noteContentUpdated() {}
}
