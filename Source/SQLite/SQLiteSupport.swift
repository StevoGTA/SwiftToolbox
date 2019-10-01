//
//  SQLiteSupport.swift
//
//  Created by Stevo on 10/25/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

import Foundation
import SQLite3

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

//----------------------------------------------------------------------------------------------------------------------
// MARK: - SQLiteWhere
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
						" \(comparison) \"\(value)\""
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
						" \(comparison) \"\(value)\""

		return self
	}

	//------------------------------------------------------------------------------------------------------------------
	public func or(table :SQLiteTable? = nil, tableColumn :SQLiteTableColumn, comparison :String = "=", value :Any) ->
			Self {
		// Append
		self.string +=
				" OR " + ((table != nil) ? "`\(table!.name)`.`\(tableColumn.name)`" : "`\(tableColumn.name)`") +
						" \(comparison) \"\(value)\""

		return self
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - SQLiteStatementPerfomer
public struct SQLiteStatementPerfomer {

	// MARK: Properties
	static	private	let	SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
	static	private	let	SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

					var	lastInsertRowID :Int64 { return sqlite3_last_insert_rowid(self.database) }

			private	let	database :OpaquePointer
			private	let	lock = Lock()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(database :OpaquePointer) {
		// Store
		self.database = database
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func perform(statement string :String) {
		// Perform
		self.lock.perform() {
			// Setup
			var	statement :OpaquePointer? = nil
			defer { sqlite3_finalize(statement) }

			// Prepare
			guard sqlite3_prepare_v2(self.database, string, -1, &statement, nil) == SQLITE_OK else
					{ fatalError("SQLiteStatementPerfomer could not prepare query with \"\(string)\"") }

			// Perform
			guard sqlite3_step(statement) == SQLITE_DONE else
					{ fatalError("SQLiteStatementPerfomer could not perform query with \"\(string)\"") }
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func perform(statement string :String, values :[Any]) -> Int64 {
		// Perform
		return self.lock.perform() {
			// Setup
			var	statement :OpaquePointer? = nil
			defer { sqlite3_finalize(statement) }

			// Prepare
			guard sqlite3_prepare_v2(self.database, string, -1, &statement, nil) == SQLITE_OK else
					{ fatalError("SQLiteStatementPerfomer could not prepare query with \"\(string)\"") }

			// Bind values
			bind(values: values, to: statement!)

			// Execute
			guard sqlite3_step(statement) == SQLITE_DONE else
					{ fatalError("SQLiteStatementPerfomer could not perform query with \"\(string)\"") }

			return sqlite3_last_insert_rowid(self.database)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func perform(statement string :String, values :[Any]? = nil, resultsProc :(_ results :SQLiteResults) -> Void) {
		// Perform
		return self.lock.perform() {
			// Setup
			var	statement :OpaquePointer? = nil
			defer { sqlite3_finalize(statement) }

			// Prepare
			guard sqlite3_prepare_v2(self.database, string, -1, &statement, nil) == SQLITE_OK else
					{ fatalError("SQLiteStatementPerfomer could not prepare query with \"\(string)\"") }

			// Check for values
			if values != nil {
				// Bind values
				bind(values: values!, to: statement!)
			}

			// Call proc
			resultsProc(SQLiteResults(statement: statement!))
		}
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func bind(values :[Any], to statement :OpaquePointer) {
		// Bind values
		values.enumerated().forEach() {
			// Check value type
			if let int = $0.element as? Int {
				// Integer
				sqlite3_bind_int64(statement, Int32($0.offset + 1), Int64(int))
			} else if let int32 = $0.element as? Int32 {
				// Integer - 32
				sqlite3_bind_int(statement, Int32($0.offset + 1), int32)
			} else if let int64 = $0.element as? Int64 {
				// Integer - 64
				sqlite3_bind_int64(statement, Int32($0.offset + 1), int64)
			} else if let double = $0.element as? Double {
				// Real
				sqlite3_bind_double(statement, Int32($0.offset + 1), double)
			} else if let text = $0.element as? String {
				// Text
				sqlite3_bind_text(statement, Int32($0.offset + 1), text, -1, SQLiteStatementPerfomer.SQLITE_TRANSIENT)
			} else if let data = $0.element as? Data {
				// Blob
				sqlite3_bind_blob(statement, Int32($0.offset + 1), (data as NSData).bytes, Int32(data.count),
						SQLiteStatementPerfomer.SQLITE_STATIC)
			} else {
				// null
				sqlite3_bind_null(statement, Int32($0.offset + 1))
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - SQLiteResults
public class SQLiteResults {

	// MARK: Properties
	private	let	statement :OpaquePointer

	private	var	columnNameInfoMap = [/* column name */ String : /* index */ Int32]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(statement :OpaquePointer) {
		// Store
		self.statement = statement

		// Setup column name map
		for index in 0..<sqlite3_column_count(statement) {
			// Add to map
			let	columnName = String(cString: sqlite3_column_name(statement, index))
			self.columnNameInfoMap[columnName] = index
		}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func next() -> Bool { return sqlite3_step(self.statement) == SQLITE_ROW }

	//------------------------------------------------------------------------------------------------------------------
	public func integer<T : SignedInteger>(for tableColumn :SQLiteTableColumn) -> T? {
		// Preflight
		let	name = tableColumn.name
		guard case .integer(_, _) = tableColumn.kind else
			{ fatalError("SQLiteResults column type mismatch: \"\(name)\" is not the expected type of integer") }
		guard let index = self.columnNameInfoMap[name] else
			{ fatalError("SQLiteResults column key not found: \"\(name)\"") }

		return (sqlite3_column_type(self.statement, index) != SQLITE_NULL) ?
				T(sqlite3_column_int64(self.statement, index)) : nil
	}

	//------------------------------------------------------------------------------------------------------------------
	public func real(for tableColumn :SQLiteTableColumn) -> Double? {
		// Preflight
		let	name = tableColumn.name
		guard case .real(_) = tableColumn.kind else
			{ fatalError("SQLiteResults column type mismatch: \"\(name)\" is not the expected type of real") }
		guard let index = self.columnNameInfoMap[tableColumn.name] else
			{ fatalError("SQLiteResults column key not found: \"\(name)\"") }

		return (sqlite3_column_type(self.statement, index) != SQLITE_NULL) ?
				sqlite3_column_double(self.statement, index) : nil
	}

	//------------------------------------------------------------------------------------------------------------------
	public func text(for tableColumn :SQLiteTableColumn) -> String? {
		// Preflight
		let	name = tableColumn.name
		guard case .text(_, _) = tableColumn.kind else
			{ fatalError("SQLiteResults column type mismatch: \"\(name)\" is not the expected type of text") }
		guard let index = self.columnNameInfoMap[tableColumn.name] else
			{ fatalError("SQLiteResults column key not found: \"\(name)\"") }

		// Get value
		if let text = sqlite3_column_text(self.statement, index) {
			// Have value
			return String(cString: text)
		} else {
			// Don't have value
			return nil
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func blob(for tableColumn :SQLiteTableColumn) -> Data? {
		// Preflight
		let	name = tableColumn.name
		guard case .blob = tableColumn.kind else
			{ fatalError("SQLiteResults column type mismatch: \"\(name)\" is not the expected type of blob") }
		guard let index = self.columnNameInfoMap[tableColumn.name] else
			{ fatalError("SQLiteResults column key not found: \"\(name)\"") }

		// Get value
		if let blob = sqlite3_column_blob(self.statement, index) {
			// Have value
			return Data(bytes: blob, count: Int(sqlite3_column_bytes(self.statement, index)))
		} else {
			// Don't have value
			return nil
		}
	}
}
