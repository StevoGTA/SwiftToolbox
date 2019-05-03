//
//  SQLiteTable.swift
//
//  Created by Stevo on 10/15/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: SQLiteTable
struct SQLiteTable {

	// MARK: Options
	struct Options : OptionSet {

		static	let	withoutRowID = Options(rawValue: 1 << 0)

				let	rawValue :Int

		// MARK: Lifecycle methods
		init(rawValue :Int) { self.rawValue = rawValue }
	}

	// MARK: Properties
	private	let	name :String
	private	let	options :Options
	private	let	tableColumnInfos :[SQLiteTableColumnInfo]
	private	let	referenceInfos :[SQLiteTableColumnReferencesInfo]
	private	let	statementPerformer :SQLiteStatementPerfomer

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(name :String, options :Options, tableColumnInfos :[SQLiteTableColumnInfo],
			referenceInfos :[SQLiteTableColumnReferencesInfo] = [], statementPerformer :SQLiteStatementPerfomer) {
		// Store
		self.name = name
		self.options = options
		self.tableColumnInfos = tableColumnInfos
		self.referenceInfos = referenceInfos
		self.statementPerformer = statementPerformer
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func create(ifNotExists :Bool = true) {
		// Setup
		var	tableColumnReferenceInfoMap = [/* column name */ String : SQLiteTableColumnReferencesInfo]()
		self.referenceInfos.forEach() { tableColumnReferenceInfoMap[$0.tableColumnInfo.name] = $0 }

		let	columnInfos :[String] =
					self.tableColumnInfos.map() {
						// Compose column string
						var	columnInfo = "\($0.name) "

						switch $0.type {
							case .integer(let size, let `default`):
								// Integer
								columnInfo += "INTEGER"
								if size != nil { columnInfo += "(\(size!))" }
								if `default` != nil { columnInfo += " DEFAULT \(`default`!)" }

							case .real(let `default`):
								// Real
								columnInfo += "REAL"
								if `default` != nil { columnInfo += " DEFAULT \(`default`!)" }

							case .text(let size, let `default`):
								// Text
								columnInfo += "TEXT"
								if size != nil { columnInfo += "(\(size!))" }
								if `default` != nil { columnInfo += " DEFAULT \(`default`!)" }

							case .blob:
								// Blob
								columnInfo += "BLOB"
						}

						$0.options.forEach() {
							// What is option
							switch $0 {
								case .primaryKey:		columnInfo += " PRIMARY KEY"
								case .autoincrement:	columnInfo += " AUTOINCREMENT"
								case .notNull:			columnInfo += " NOT NULL"
								case .unique:			columnInfo += " UNIQUE"
								case .check:			columnInfo += " CHECK"
							}
						}

						if let tableColumnReferenceInfo = tableColumnReferenceInfoMap[$0.name] {
							// Add reference
							columnInfo +=
									" REFERENCES \(tableColumnReferenceInfo.referencedTable.name)(\(tableColumnReferenceInfo.referencedTableColumnInfo.name)) ON UPDATE CASCADE"
						}

						return columnInfo
					}

		// Compose create statement
		let	statement =
					"CREATE TABLE" + (ifNotExists ? " IF NOT EXISTS" : "") + " \(self.name)" +
							" (" + String(combining: columnInfos, with: ", ") + ")" +
							(self.options.contains(.withoutRowID) ? " WITHOUT ROWID" : "")

		// Create
		self.statementPerformer.perform(statement: statement)
	}

	//------------------------------------------------------------------------------------------------------------------
	func select(tableColumnInfos :[SQLiteTableColumnInfo]? = nil,
			innerJoin :(table :SQLiteTable, tableColumnInfo :SQLiteTableColumnInfo)? = nil,
			where whereInfo :(tableColumnInfo :SQLiteTableColumnInfo, columnValue :Any)? = nil,
			resultsProc :(_ results :SQLiteResults) -> Void) {
		// Compose statement
		let	statement =
					"SELECT " + columnNamesString(for: tableColumnInfos) + " FROM \(self.name)" +
							string(for: innerJoin) + string(for: whereInfo)

		// Perform
		self.statementPerformer.perform(statement: statement, resultsProc: resultsProc)
	}

	//------------------------------------------------------------------------------------------------------------------
	func select(tableColumnInfos :[SQLiteTableColumnInfo]? = nil,
			innerJoin :(table :SQLiteTable, tableColumnInfo :SQLiteTableColumnInfo)? = nil,
			where whereInfo :(tableColumnInfo :SQLiteTableColumnInfo, columnValues :[Any]),
			resultsProc :(_ results :SQLiteResults) -> Void) {
		// Compose statement
		let	statement =
					"SELECT " + columnNamesString(for: tableColumnInfos) + " FROM \(self.name)" +
							string(for: innerJoin) + string(for: whereInfo)

		// Perform
		self.statementPerformer.perform(statement: statement, values: whereInfo.columnValues, resultsProc: resultsProc)
	}

	//------------------------------------------------------------------------------------------------------------------
	func insert(_ info :[(tableColumnInfo :SQLiteTableColumnInfo, value :Any)]) -> Int64 {
		// Setup
		let	tableColumnInfos = info.map() { $0.tableColumnInfo }
		let	values = info.map() { $0.value }
		let	statement =
					"INSERT INTO \(self.name) (" + columnNamesString(for: tableColumnInfos) + ") VALUES (" +
							String(combining: Array(repeating: "?", count: info.count), with: ",") + ")"

		// Perform
		return self.statementPerformer.perform(statement: statement, values: values)
	}

	//------------------------------------------------------------------------------------------------------------------
	func insertOrReplace(_ info :[(tableColumnInfo :SQLiteTableColumnInfo, value :Any)]) -> Int64 {
		// Setup
		let	tableColumnInfos = info.map() { $0.tableColumnInfo }
		let	values = info.map() { $0.value }
		let	statement =
					"INSERT OR REPLACE INTO \(self.name) (" + columnNamesString(for: tableColumnInfos) + ") VALUES (" +
							String(combining: Array(repeating: "?", count: info.count), with: ",") + ")"

		// Perform
		return self.statementPerformer.perform(statement: statement, values: values)
	}

	//------------------------------------------------------------------------------------------------------------------
	func update(_ info :[(tableColumnInfo :SQLiteTableColumnInfo, value :Any)],
			where whereInfo :(tableColumnInfo :SQLiteTableColumnInfo, columnValue :Any)) {
		// Setup
		let	statement =
					"UPDATE \(self.name) SET " +
							String(combining: info.map({ "\($0.tableColumnInfo.name) = ?" }), with: ", ") +
							" WHERE \(whereInfo.tableColumnInfo.name) = \"\(whereInfo.columnValue)\""

		// Perform
		_ = self.statementPerformer.perform(statement: statement, values: info.map({ $0.value }))
	}

	//------------------------------------------------------------------------------------------------------------------
	func delete<T>(where whereInfo :(tableColumnInfo :SQLiteTableColumnInfo, columnValue :T)) {
		// Setup
		let	statement =
					"DELETE FROM \(self.name) WHERE \(whereInfo.tableColumnInfo.name) = \"\(whereInfo.columnValue)\""

		// Perform
		self.statementPerformer.perform(statement: statement)
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func columnNamesString(for tableColumnInfos :[SQLiteTableColumnInfo]?) -> String {
		// Collect column names
		let	columnNames = (tableColumnInfos ?? []).map() { $0.name }

		return !columnNames.isEmpty ? String(combining: columnNames, with: ",") : "*"
	}

	//------------------------------------------------------------------------------------------------------------------
	private func string(for innerJoin :(table :SQLiteTable, tableColumnInfo :SQLiteTableColumnInfo)?) -> String {
		// Return string
		return (innerJoin != nil) ?
				" INNER JOIN \(innerJoin!.table.name) ON " +
						"\(innerJoin!.table.name).\(innerJoin!.tableColumnInfo.name) = " +
						"\(self.name).\(innerJoin!.tableColumnInfo.name)" :
				""
	}

	//------------------------------------------------------------------------------------------------------------------
	private func string(for whereInfo :(tableColumnInfo :SQLiteTableColumnInfo, columnValue :Any)?) -> String {
		// Return string
		return (whereInfo != nil) ?
				" WHERE \(self.name).\(whereInfo!.tableColumnInfo.name) = \"\(whereInfo!.columnValue)\"" : ""
	}

	//------------------------------------------------------------------------------------------------------------------
	private func string(for whereInfo :(tableColumnInfo :SQLiteTableColumnInfo, columnValues :[Any])) -> String {
		// Return string
		return " WHERE \(self.name).\(whereInfo.tableColumnInfo.name) IN (" +
				String(combining: Array(repeating: "?", count: whereInfo.columnValues.count), with: ",") + ")"
	}
}
