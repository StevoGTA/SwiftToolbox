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
	static	private			let	variablePlaceholder = "##VARIABLEPLACEHOLDER##"

			private(set)	var	string :String
			private(set)	var	values :[Any]?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, comparison :String = "=", value :Any) {
		// Setup
		self.string = " WHERE " + ((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`")
		append(comparison: comparison, with: value)
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, values :[Any]) {
		// Setup
		self.string =
				" WHERE " + ((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`") +
						" IN (\(SQLiteWhere.variablePlaceholder))"
		self.values = values
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func forEachValueGroup(chunkSize :Int, _ proc :(_ string :String, _ values :[Any]?) throws -> Void)
			rethrows {
		// Chunk values
		try self.values?.forEachChunk(chunkSize: chunkSize) {
			// Call proc
			try proc(
					self.string.replacingOccurrences(of: SQLiteWhere.variablePlaceholder,
							with: String(combining: Array(repeating: "?", count: $0.count), with: ",")),
					$0)
 		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func and(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, comparison :String = "=", value :Any) ->
			Self {
		// Append
		self.string += " AND " + ((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`")
		append(comparison: comparison, with: value)

		return self
	}

	//------------------------------------------------------------------------------------------------------------------
	public func and(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, values :[Any]) -> Self {
		// Append
		self.string +=
				" WHERE " + ((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`") +
						" IN (\(SQLiteWhere.variablePlaceholder))"
		self.values = values

		return self
	}

	//------------------------------------------------------------------------------------------------------------------
	public func or(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, comparison :String = "=", value :Any) ->
			Self {
		// Append
		self.string += " OR " + ((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`")
		append(comparison: comparison, with: value)

		return self
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func append(comparison :String, with value :Any) {
		// Check value type
		if case Optional<Any>.none = value {
			// Value is NULL
			if comparison == "=" {
				// IS NULL
				self.string += " IS NULL"
			} else if comparison == "!=" {
				// IS NOT NULL
				self.string += " IS NOT NULL"
			} else {
				// Unsupported NULL comparison
				fatalError("SQLiteWhere could not prepare NULL value comparison \(comparison)")
			}
		} else {
			// Actual value
			self.string += " \(comparison) ?"
			self.values = (self.values ?? []) + [value]
		}
	}
}
