//
//  SQLiteInnerJoin.swift
//  Media Tools
//
//  Created by Stevo on 11/19/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: SQLiteInnerJoin
public class SQLiteInnerJoin {

	// MARK: Properties
	private(set)	var	string :String

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ table :SQLiteTable, tableColumn :SQLiteTableColumn, to otherTable :SQLiteTable,
			otherTableColumn :SQLiteTableColumn? = nil) {
		// Setup
		self.string = ""
		_ = and(table, tableColumn: tableColumn, to: otherTable, otherTableColumn: otherTableColumn)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func and(_ table :SQLiteTable, tableColumn :SQLiteTableColumn, to otherTable :SQLiteTable,
			otherTableColumn :SQLiteTableColumn? = nil) -> Self {
		// Append
		self.string +=
				" INNER JOIN `\(otherTable.name)` ON " +
						"`\(otherTable.name)`.`\(otherTableColumn?.name ?? tableColumn.name)` = " +
						"`\(table.name)`.`\(tableColumn.name)`"

		return self
	}
}
