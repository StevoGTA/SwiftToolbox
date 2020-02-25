//
//  SQLiteWhere.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/23/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

/*
	The notion of some instances needing multiple groups while most instances are a single string/values may still need
		more massaging...
*/

//----------------------------------------------------------------------------------------------------------------------
// MARK: SQLiteWhere
public class SQLiteWhere {

	// MARK: Types
	typealias Group = (string :String, values :[Any]?)

	// MARK: Properties
			var	string :String { return self.groups.first!.string }
			var	values :[Any]? { return self.groups.first!.values }

	private	var	groups = [Group]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, comparison :String = "=", value :Any) {
		// Setup
		setup(with: " WHERE " + ((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`"),
				appending: comparison, with: value)
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, values :[Any]) {
		// Setup
		values.forEachChunk(chunkSize: Int(SQLITE_LIMIT_VARIABLE_NUMBER)) {
			// Append next group
			self.groups.append(
					(" WHERE " + ((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`") +
								" IN (" + String(combining: Array(repeating: "?", count: $0.count), with: ",") + ")",
						$0))
		}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func forEachGroup(_ proc :(_ string :String, _ values :[Any]?) throws -> Void) rethrows {
		// Iterate all groups
		try self.groups.forEach() { try proc($0.string, $0.values) }
	}

	//------------------------------------------------------------------------------------------------------------------
	public func and(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, comparison :String = "=", value :Any) ->
			Self {
		// Append
		setup(
				with:
						self.string + " AND " +
								((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`"),
				appending: comparison, with: value)

		return self
	}

	//------------------------------------------------------------------------------------------------------------------
	public func or(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, comparison :String = "=", value :Any) ->
			Self {
		// Append
		setup(
				with:
						self.string + " OR " +
								((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`"),
				appending: comparison, with: value)

		return self
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func setup(with string :String, appending comparison :String, with value :Any) {
		// Check value type
		if case Optional<Any>.none = value {
			// Value is nil
			if comparison == "=" {
				// IS NULL
				self.groups = [(string + " IS NULL", nil)]
			} else if comparison == "!=" {
				// IS NOT NULL
				self.groups = [(string + " IS NOT NULL", nil)]
			} else {
				fatalError("SQLiteWhere could not prepare nil value comparison \(comparison)")
			}
		} else {
			// Actual value
			self.groups = [(string + " \(comparison) ?", (self.groups.first?.values ?? []) + [value])]
		}
	}
}
