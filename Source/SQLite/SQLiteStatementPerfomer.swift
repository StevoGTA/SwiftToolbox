//
//  SQLiteStatementPerfomer.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/23/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Foundation
import SQLite3

//----------------------------------------------------------------------------------------------------------------------
// MARK: LastInsertRowID
enum LastInsertRowID {}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - SQLiteStatement
fileprivate struct SQLiteStatement {

	// MARK: Enums
	private	static	let	SQLITE_STATIC = unsafeBitCast(0, to: sqlite3_destructor_type.self)
	private	static	let	SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

	// MARK: Properties
	private	let	string :String
	private	let	values :[Any]?

	private	let	lastInsertRowIDProc :((_ lastInsertRowID :Int64) -> Void)?

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func perform(statement string :String, values :[Any]? = nil, with database :OpaquePointer,
			processValuesProc :SQLiteResultsRow.ProcessValuesProc) throws {
		// Setup
		var	statement :OpaquePointer? = nil
		defer { sqlite3_finalize(statement) }

		// Prepare
		guard sqlite3_prepare_v2(database, string, -1, &statement, nil) == SQLITE_OK else {
			// Error
			let	errorMessage = String(cString: sqlite3_errmsg(database))
			fatalError("SQLiteStatementPerfomer could not prepare query with \"\(string)\", with error \"\(errorMessage)\"")
		}

		// Check for values
		if values != nil {
			// Bind values
			self.bind(values: values!, to: statement!, with: database)
		}

		// Iterate results
		let	resultsRow = SQLiteResultsRow(statement: statement!)
		while sqlite3_step(statement) == SQLITE_ROW { try processValuesProc(resultsRow) }
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(statement :String, values :[Any]? = nil, lastInsertRowIDProc :((_ lastInsertRowID :Int64) -> Void)? = nil) {
		// Store
		self.string = statement
		self.values = values
		self.lastInsertRowIDProc = lastInsertRowIDProc
	}

	// MARK: Instance Methods
	//------------------------------------------------------------------------------------------------------------------
	func perform(with database :OpaquePointer) throws {
		// Setup
		var	statement :OpaquePointer? = nil
		defer { sqlite3_finalize(statement) }

		// Prepare
		guard sqlite3_prepare_v2(database, self.string, -1, &statement, nil) == SQLITE_OK else {
			// Error
			let	errorMessage = String(cString: sqlite3_errmsg(database))
			fatalError("SQLiteStatementPerfomer could not prepare query with \"\(self.string)\", with error \"\(errorMessage)\"")
		}

		// Check for values
		if self.values != nil {
			// Bind values
			type(of: self).bind(values: self.values!, to: statement!, with: database)
		}

		// Perform
		guard sqlite3_step(statement) == SQLITE_DONE else {
			// Error
			let	errorMessage = String(cString: sqlite3_errmsg(database))
			fatalError("SQLiteStatementPerfomer could not perform query with \"\(self.string)\", with error \"\(errorMessage)\"")
		}

		// Check for last insert row ID proc
		if self.lastInsertRowIDProc != nil {
			// Call proc
			self.lastInsertRowIDProc!(sqlite3_last_insert_rowid(database))
		}
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	static private func bind(values :[Any], to statement :OpaquePointer, with database :OpaquePointer) {
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
			} else if let uint = $0.element as? UInt {
				// Unsigned integer
				sqlite3_bind_int64(statement, Int32($0.offset + 1), Int64(uint))
			} else if let double = $0.element as? Double {
				// Real
				sqlite3_bind_double(statement, Int32($0.offset + 1), double)
			} else if let text = $0.element as? String {
				// Text
				sqlite3_bind_text(statement, Int32($0.offset + 1), text, -1, self.SQLITE_TRANSIENT)
			} else if let data = $0.element as? Data {
				// Blob
				sqlite3_bind_blob(statement, Int32($0.offset + 1), (data as NSData).bytes, Int32(data.count),
						self.SQLITE_STATIC)
			} else if $0.element is LastInsertRowID {
				// Last insert row ID
				sqlite3_bind_int64(statement, Int32($0.offset + 1), sqlite3_last_insert_rowid(database))
			} else {
				// null
				sqlite3_bind_null(statement, Int32($0.offset + 1))
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - SQLiteStatementPerfomer
class SQLiteStatementPerfomer {

	// MARK: Enums
	enum TransactionResult {
		case commit
		case rollback
	}

	// MARK: Properties
			var	variableNumberLimit :Int { Int(sqlite3_limit(self.database, SQLITE_LIMIT_VARIABLE_NUMBER, -1)) }

	private	let	database :OpaquePointer
	private	let	lock = Lock()

	private	var	transactionsMap = [Thread : [SQLiteStatement]]()
	private	var	transactionsMapLock = ReadPreferringReadWriteLock()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(database :OpaquePointer) {
		// Store
		self.database = database
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func addToTransactionOrPerform(statement string :String, values :[Any]? = nil,
			lastInsertRowIDProc :((_ lastInsertRowID :Int64) -> Void)? = nil) {
		// Setup
		let	sqliteStatement =
					SQLiteStatement(statement: string, values: values, lastInsertRowIDProc: lastInsertRowIDProc)

		// Check for transaction
		if var sqliteStatements = self.transactionsMapLock.read({ self.transactionsMap[Thread.current] }) {
			// In transaction
			self.transactionsMapLock.write() {
				// Add sqlite statement
				self.transactionsMap[Thread.current] = nil
				sqliteStatements.append(sqliteStatement)
				self.transactionsMap[Thread.current] = sqliteStatements
			}
		} else {
			// Perform
			self.lock.perform() { try! sqliteStatement.perform(with: self.database) }
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func perform(statement string :String, values :[Any]? = nil,
			processValuesProc :SQLiteResultsRow.ProcessValuesProc) rethrows {
		// Setup
		try self.lock.perform() {
			// Perform
			try SQLiteStatement.perform(statement: string, values: values, with: self.database,
					processValuesProc: processValuesProc)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func performAsTransaction(_ proc :() -> TransactionResult) {
		// Internals check
		guard self.transactionsMapLock.read({ self.transactionsMap[Thread.current] }) == nil else {
			// Error
			fatalError("SQLiteStatementPerfomer performAsTransaction() called while already in transaction")
		}

		// Start transaction
		self.transactionsMapLock.write()
				{ self.transactionsMap[Thread.current] = [SQLiteStatement(statement: "BEGIN TRANSACTION")] }

		// Call proc and check result
		if proc() == .commit {
			// End transaction
			var	sqliteStatements = [SQLiteStatement]()
			self.transactionsMapLock.write() {
				// Retrieve sqlite statements
				sqliteStatements = self.transactionsMap[Thread.current]!
				self.transactionsMap[Thread.current] = nil
			}

			// Check for empty transaction
			guard sqliteStatements.count > 1 else { return }

			// Add COMMIT
			sqliteStatements.append(SQLiteStatement(statement: "COMMIT"))

			// Perform
			self.lock.perform() { sqliteStatements.forEach() { _ = try! $0.perform(with: self.database) } }
		} else {
			// No longer in transaction
			self.transactionsMapLock.write() { self.transactionsMap[Thread.current] = nil }
		}
	}
}
