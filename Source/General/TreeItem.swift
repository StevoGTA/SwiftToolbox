//
//  TreeItem.swift
//  Swift Toolbox
//
//  Created by Stevo on 7/27/21.
//  Copyright © 2021 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: TreeGroup
public protocol TreeGroup : TreeItem {

	// MARK: Properties
	var	childTreeItems :[TreeItem] { get }
	var	hasChildTreeItems :Bool { get }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: TreeGroup extension
public extension TreeGroup {

	// MARK: Properties
	var	childTreeItemsDeep :[TreeItem]
			{ self.childTreeItems.flatMap({ [$0] + (($0 as? TreeGroup)?.childTreeItemsDeep ?? []) }) }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - TreeItem
public protocol TreeItem {}
