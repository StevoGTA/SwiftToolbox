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
				case integer(size :Int?, default :Int?)

				// REAL values are real numbers with decimal values that use 8-byte floats.
				case real(default :Float?)

				// TEXT is used to store character data. The maximum length of TEXT is unlimited. SQLite supports
				//	various character encodings.
				case text(size :Int?, default :String?)

				// BLOB stands for a binary large object that can be used to store any kind of data. The maximum size
				//	of BLOBs is unlimited
				case blob
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
	let	name :String
	let	kind :Kind
	let	options :[Options]

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ name :String, _ kind :Kind, _ options :[Options]) {
		// Store
		self.name = name
		self.kind = kind
		self.options = options
	}
}
