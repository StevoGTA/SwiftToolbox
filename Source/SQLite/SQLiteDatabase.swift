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

extension SQLiteDatabaseError : CustomStringConvertible, LocalizedError {

	// MARK: Properties
	public 	var	description :String { self.localizedDescription }
	public	var	errorDescription :String? {
						switch self {
							case .failedToOpen:	return "SQLiteDatabase failed to open"
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
			var	tables :[SQLiteTable] { SQLiteTable.all(self.statementPerformer) }

	private	let	database :OpaquePointer
	private	let	statementPerformer :SQLiteStatementPerformer

	// Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func doesExist(in folder :Folder, with name :String = "database") -> Bool {
		// Check for known extensions
		return FileManager.default.exists(folder.file(withSubPath: name.appending(pathExtension: "sqlite"))) ||
				FileManager.default.exists(folder.file(withSubPath: name.appending(pathExtension: "sqlite3")))
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init (with file :File, options :Options = [.walMode]) throws {
		// Open
		var	database :OpaquePointer? = nil
		let	result = sqlite3_open(file.path, &database)
		if result != SQLITE_OK {
			// Failed to open
			NSLog("SQLiteDatabase failed to open with \(result) (\"\(String(cString: sqlite3_errstr(result)))\")")
			throw SQLiteDatabaseError.failedToOpen
		}

		// Setup
		self.database = database!
		self.statementPerformer = SQLiteStatementPerformer(database: database!)

		// Check options
		if options.contains(.walMode) {
			// Activate WAL mode
			sqlite3_exec(database, "PRAGMA journal_mode = WAL;", nil, nil, nil);
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public convenience init(in folder :Folder, with name :String = "database", options :Options = [.walMode]) throws {
		// Setup
		let	urlBase = folder.url.appendingPathComponent(name)
		let	file =
					FileManager.default.exists(File(urlBase.appendingPathExtension("sqlite3"))) ?
							File(urlBase.appendingPathExtension("sqlite3")) :
							File(urlBase.appendingPathExtension("sqlite"))

		try self.init(with: file, options: options)
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
