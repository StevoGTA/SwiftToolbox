//
//  SQLiteTableColumn.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/23/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: SQLiteTableColumn
public struct SQLiteTableColumn {

	// MARK: Kind
	public	enum Kind {
				// Values
				// INTEGER values are whole numbers (either positive or negative). An integer can have variable sizes
				//	such as 1, 2, 3, 4, or 8 bytes.
				case integer
				case integer1
				case integer2
				case integer3
				case integer4
				case integer8

				// REAL values are real numbers with decimal values that use 8-byte floats.
				case real

				// TEXT is used to store character data. The maximum length of TEXT is unlimited. SQLite supports
				//	various character encodings.
				case text
				case textWith(size :Int)

				// BLOB stands for a binary large object that can be used to store any kind of data. The maximum size
				//	of BLOBs is unlimited
				case blob

				// Properties
				var	isInteger :Bool {
							// Switch self
							switch self {
								case .integer:	return true
								case .integer1:	return true
								case .integer2:	return true
								case .integer3:	return true
								case .integer4:	return true
								case .integer8:	return true
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
								case .text:			return true
								case .textWith(_):	return true
								default:			return false
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
	static	let	rowID = SQLiteTableColumn("rowid", .integer, [])

			let	name :String
			let	kind :Kind
			let	options :[Options]
			let	defaultValue :Any?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ name :String, _ kind :Kind, _ options :[Options], _ defaultValue :Any? = nil) {
		// Store
		self.name = name
		self.kind = kind
		self.options = options
		self.defaultValue = defaultValue
	}
}
