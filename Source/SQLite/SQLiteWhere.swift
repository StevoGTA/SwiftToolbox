//
//  SQLiteWhere.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/23/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: SQLiteWhere
public class SQLiteWhere {

	// MARK: Properties
	private(set)	var	string :String
	private(set)	var	values :[Any]?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, comparison :String = "=", value :Any) {
		// Setup
		self.string =
				" WHERE " + ((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`") +
						" \(comparison) ?"
		self.values = [value]
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, values :[Any]) {
		// Setup
		self.string =
				" WHERE " + ((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`") +
						" IN (" + String(combining: Array(repeating: "?", count: values.count), with: ",") + ")"
		self.values = values
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func and(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, comparison :String = "=", value :Any) ->
			Self {
		// Append
		self.string +=
				" AND " + ((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`") +
						" \(comparison) ?"
		self.values = (self.values ?? []) + [value]

		return self
	}

	//------------------------------------------------------------------------------------------------------------------
	public func or(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, comparison :String = "=", value :Any) ->
			Self {
		// Append
		self.string +=
				" OR " + ((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`") +
						" \(comparison) ?"
		self.values = (self.values ?? []) + [value]

		return self
	}
}
