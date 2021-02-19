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
							var	values :[Any]? { self.valuesInternal?.flatMap({ $0 }) }

			private			var	valuesInternal :[[Any]]?

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
		self.valuesInternal = [values]
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func forEachValueGroup(groupSize :Int, _ proc :(_ string :String, _ values :[Any]?) throws -> Void)
			rethrows {
		// Check if need to group
		if !self.string.contains(SQLiteWhere.variablePlaceholder) {
			// Perform
			try proc(self.string, self.values)
		} else {
			// Group
			var	preValueGroupValues = [Any]()
			var	valueGroup = [Any]()
			var	postValueGroupValues = [Any]()
			self.valuesInternal?.forEach() {
				// Check count
				if $0.count == 1 {
					// Single value
					if valueGroup.isEmpty {
						// Pre
						preValueGroupValues += $0
					} else {
						// Post
						postValueGroupValues += $0
					}
				} else {
					// Value group
					valueGroup = $0
				}
			}

			// Check if need to group
			let	allValues = preValueGroupValues + valueGroup + postValueGroupValues
			if allValues.count < groupSize {
				// Can perform as a single group
				try proc(
						self.string
							.replacingOccurrences(of: SQLiteWhere.variablePlaceholder,
									with: String(combining: Array(repeating: "?", count: max(valueGroup.count, 1)),
											with: ",")),
						allValues)
			} else {
				// Must perform in groups
				try valueGroup.forEachChunk(
						chunkSize: groupSize - preValueGroupValues.count - postValueGroupValues.count) {
							// Setup
							let	values = preValueGroupValues + $0 + postValueGroupValues

							// Call proc
							try proc(
									self.string.replacingOccurrences(of: SQLiteWhere.variablePlaceholder,
											with: String(combining: Array(repeating: "?", count: $0.count), with: ",")),
									values)
						}
			}
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
		self.valuesInternal = [values]

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
			self.valuesInternal = (self.valuesInternal ?? []) + [[value]]
		}
	}
}
