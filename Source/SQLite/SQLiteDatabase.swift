//
//  SQLiteDatabase.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/16/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

import Foundation
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
public class SQLiteDatabase {

	// MARK: Types
	public	struct Options : OptionSet {

				// MARK: Properties
				static	public	let	walMode = Options(rawValue: 1 << 0)

						public	let	rawValue :Int

				// MARK: Lifecycle methods
				public init(rawValue :Int) { self.rawValue = rawValue }
			}

	// MARK: Enums
	public enum TransactionResult {
		case commit
		case rollback
	}

	// MARK: Properties
	private	let	database :OpaquePointer
	private	let	statementPerformer :SQLiteStatementPerfomer

	// Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func doesExist(at url :URL) -> Bool {
		// Check for known extensions
		return FileManager.default.fileExists(atPath: url.appendingPathExtension("sqlite").path) ||
				FileManager.default.fileExists(atPath: url.appendingPathExtension("sqlite3").path)
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(url :URL, options :Options = [.walMode]) throws {
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
		self.database = database!
		self.statementPerformer = SQLiteStatementPerfomer(database: database!)

		// Check options
		if options.contains(.walMode) {
			// Activate WAL mode
			sqlite3_exec(database, "PRAGMA journal_mode = WAL;", nil, nil, nil);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
		// Cleanup
		sqlite3_close(self.database)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func table(name :String, options :SQLiteTable.Options = [], tableColumns :[SQLiteTableColumn],
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
