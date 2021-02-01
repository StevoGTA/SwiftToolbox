//
//  SQLiteOrderBy.swift
//  Swift Toolbox
//
//  Created by Stevo on 7/23/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: SQLiteOrderBy
public class SQLiteOrderBy {

	// MARK: Types
	public enum Order {
		case ascending
		case descending
	}

	// MARK: Properties
	let	string :String

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, order :Order = .ascending) {
		// Setup
		self.string =
				" ORDER BY " +
						((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`") +
						((order == .ascending) ? " ASC" : " DESC")
	}
}
