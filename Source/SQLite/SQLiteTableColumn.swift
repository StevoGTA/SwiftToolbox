//
//  SQLiteTableColumn.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/23/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: SQLiteTableColumn
public struct SQLiteTableColumn : Equatable {

	// MARK: Kind
	public	enum Kind {
				// Values
				// INTEGER values are whole numbers (either positive or negative).
				case integer

				// REAL values are real numbers with decimal values that use 8-byte floats.
				case real

				// TEXT is used to store character data. The maximum length of TEXT is unlimited. SQLite supports
				//	various character encodings.
				case text

				// BLOB stands for a binary large object that can be used to store any kind of data. The maximum size
				//	of BLOBs is unlimited
				case blob

				// Dates (not built-in bytes, but we handle)
				//	See https://sqlite.org/lang_datefunc.html
				case dateISO8601FractionalSecondsAutoSet	// YYYY-MM-DDTHH:MM:SS.SSS (will auto set on insert/replace)
				case dateISO8601FractionalSecondsAutoUpdate	// YYYY-MM-DDTHH:MM:SS.SSS (will auto update on insert/replace)

				// Properties
				var	isInteger :Bool {
							// Switch self
							switch self {
								case .integer:	return true
								default:		return false
							}
						}
				var	isReal :Bool {
							// Switch self
							switch self {
								case .real:	return true
								default:	return false
							}
						}
				var	isText :Bool {
							// Switch self
							switch self {
								case .text:										return true
								case .dateISO8601FractionalSecondsAutoSet:		return true
								case .dateISO8601FractionalSecondsAutoUpdate:	return true
								default:										return false
							}
						}
				var	isBlob :Bool {
							// Switch self
							switch self {
								case .blob:	return true
								default:	return false
							}
						}
			}

	// MARK: Options
	public	enum Options {
				case primaryKey
				case autoincrement
				case notNull
				case unique
				case check
			}

	// Types
	public typealias Reference =
						(tableColumn :SQLiteTableColumn, referencedTable :SQLiteTable,
								referencedTableColumn :SQLiteTableColumn)

	// MARK: Properties
	static	let	all = SQLiteTableColumn("*", .integer)
	static	let	rowID = SQLiteTableColumn("rowid", .integer)

			let	name :String
			let	kind :Kind
			let	options :[Options]
			let	defaultValue :Any?

	// MARK: Equatable methods
	//------------------------------------------------------------------------------------------------------------------
	static public func == (lhs: SQLiteTableColumn, rhs: SQLiteTableColumn) -> Bool { lhs.name == rhs.name }

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func dateISO8601FractionalSecondsAutoSet(_ name :String) -> SQLiteTableColumn {
		// Return info
		return SQLiteTableColumn(name, .dateISO8601FractionalSecondsAutoSet, [.notNull],
				"strftime('%Y-%m-%dT%H:%M:%f', 'now', 'localtime')")
	}

	//------------------------------------------------------------------------------------------------------------------
	static func dateISO8601FractionalSecondsAutoUpdate(_ name :String) -> SQLiteTableColumn {
		// Return info
		return SQLiteTableColumn(name, .dateISO8601FractionalSecondsAutoUpdate, [.notNull],
				"strftime('%Y-%m-%dT%H:%M:%f', 'now', 'localtime')")
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ name :String, _ kind :Kind, _ options :[Options] = [], _ defaultValue :Any? = nil) {
		// Store
		self.name = name
		self.kind = kind
		self.options = options
		self.defaultValue = defaultValue
	}
}
