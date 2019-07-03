//
//  SQLiteDatabase.swift
//
//  Created by Stevo on 10/16/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

import SQLite3

//----------------------------------------------------------------------------------------------------------------------
// MARK: SQLiteDatabaseError
public enum SQLiteDatabaseError : Error {
	case failedToOpen
}

extension SQLiteDatabaseError : LocalizedError {
	public	var	errorDescription :String? {
						switch self {
							case .failedToOpen:
								return "SQLiteDatabase failed to open"
						}
					}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - SQLiteDatabase
struct SQLiteDatabase {

	// MARK: Properties
	private	let	statementPerformer :SQLiteStatementPerfomer

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(url :URL) throws {
		// Setup
		let	urlUse = (url.pathExtension == "sqlite") ? url : url.appendingPathExtension("sqlite")

		// Open
		var	database :OpaquePointer? = nil
		if sqlite3_open(urlUse.path, &database) != SQLITE_OK {
			// Failed to open
			throw SQLiteDatabaseError.failedToOpen
		}

		// Setup
		self.statementPerformer = SQLiteStatementPerfomer(database: database!)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func table(name :String, options :SQLiteTable.Options, tableColumns :[SQLiteTableColumn],
			references :[SQLiteTableColumn.Reference] = []) -> SQLiteTable {
		// Create table
		return SQLiteTable(name: name, options: options, tableColumns: tableColumns, references: references,
				statementPerformer: self.statementPerformer)
	}
}
