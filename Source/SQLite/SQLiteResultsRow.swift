//
//  SQLiteResultsRow.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/25/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

import Foundation
import SQLite3

//----------------------------------------------------------------------------------------------------------------------
// MARK: SQLiteResultsRow
public class SQLiteResultsRow {

	// MARK: Types
	public typealias ProcessValuesProc = (_ resultsRow :SQLiteResultsRow) throws -> Void

	// MARK: Properties
	private	let	statement :OpaquePointer

	private	var	columnNameMap = [/* column name */ String : /* index */ Int32]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(statement :OpaquePointer) {
		// Store
		self.statement = statement

		// Setup column name map
		for index in 0..<sqlite3_column_count(statement) {
			// Add to map
			let	columnName = String(cString: sqlite3_column_name(statement, index))
			self.columnNameMap[columnName] = index
		}
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func integer(for tableColumn :SQLiteTableColumn) -> Int64? {
		// Preflight
		let	name = tableColumn.name
		guard tableColumn.kind.isInteger else
			{ fatalError("SQLiteResultsRow column kind mismatch: \"\(name)\" is not the expected type of integer") }
		guard let index = self.columnNameMap[name] else
			{ fatalError("SQLiteResultsRow column not found: \"\(name)\"") }

		return (sqlite3_column_type(self.statement, index) != SQLITE_NULL) ?
				sqlite3_column_int64(self.statement, index) : nil
	}

	//------------------------------------------------------------------------------------------------------------------
	public func real(for tableColumn :SQLiteTableColumn) -> Double? {
		// Preflight
		let	name = tableColumn.name
		guard tableColumn.kind.isReal else
			{ fatalError("SQLiteResultsRow column kind mismatch: \"\(name)\" is not the expected type of real") }
		guard let index = self.columnNameMap[tableColumn.name] else
			{ fatalError("SQLiteResultsRow column not found: \"\(name)\"") }

		return (sqlite3_column_type(self.statement, index) != SQLITE_NULL) ?
				sqlite3_column_double(self.statement, index) : nil
	}

	//------------------------------------------------------------------------------------------------------------------
	public func text(for tableColumn :SQLiteTableColumn) -> String? {
		// Preflight
		let	name = tableColumn.name
		guard tableColumn.kind.isText else
			{ fatalError("SQLiteResultsRow column kind mismatch: \"\(name)\" is not the expected type of text") }
		guard let index = self.columnNameMap[tableColumn.name] else
			{ fatalError("SQLiteResultsRow column not found: \"\(name)\"") }

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
		guard tableColumn.kind.isBlob else
			{ fatalError("SQLiteResultsRow column kind mismatch: \"\(name)\" is not the expected type of blob") }
		guard let index = self.columnNameMap[tableColumn.name] else
			{ fatalError("SQLiteResultsRow column not found: \"\(name)\"") }

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
