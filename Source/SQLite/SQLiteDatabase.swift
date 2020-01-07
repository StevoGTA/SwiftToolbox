//
//  SQLiteDatabase.swift
//  Swift Toolbox
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
public struct SQLiteDatabase {

	// MARK: Enums
	public enum TransactionResult {
		case commit
		case rollback
	}

	// MARK: Properties
	private	let	statementPerformer :SQLiteStatementPerfomer

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(url :URL) throws {
		// Setup
		let	pathExtension = url.pathExtension
		let	urlUse =
					((pathExtension == "sqlite") || (pathExtension == "sqlite3")) ?
							url : url.appendingPathExtension("sqlite")

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
	public func table(name :String, options :SQLiteTable.Options, tableColumns :[SQLiteTableColumn],
			references :[SQLiteTableColumn.Reference] = []) -> SQLiteTable {
		// Create table
		return SQLiteTable(name: name, options: options, tableColumns: tableColumns, references: references,
				statementPerformer: self.statementPerformer)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func performAsTransaction(_ proc :() -> TransactionResult) {
		// Trigger statement performer to perform as a transaction
		self.statementPerformer.performAsTransaction() {
			// Call proc
			switch proc() {
				case .commit:	return .commit
				case .rollback:	return .rollback
			}
		}
	}
}
