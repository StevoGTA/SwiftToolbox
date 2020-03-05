//
//  SQLiteTable.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/15/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: SQLiteTable
@dynamicMemberLookup
public struct SQLiteTable {

	// MARK: Options
	public	struct Options : OptionSet {

				static	public	let	withoutRowID = Options(rawValue: 1 << 0)

						public	let	rawValue :Int

				// MARK: Lifecycle methods
				public init(rawValue :Int) { self.rawValue = rawValue }
			}

	// MARK: Properties
	static	private	let	countAllTableColumn = SQLiteTableColumn("COUNT(*)", .integer, [])

					let	name :String

			private	let	options :Options
			private	let	tableColumns :[SQLiteTableColumn]
			private	let	references :[SQLiteTableColumn.Reference]
			private	let	statementPerformer :SQLiteStatementPerfomer

			private	var	tableColumnsMap = [/* property name */ String : SQLiteTableColumn]()

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(name :String, options :Options, tableColumns :[SQLiteTableColumn],
			references :[SQLiteTableColumn.Reference] = [], statementPerformer :SQLiteStatementPerfomer) {
		// Store
		self.name = name
		self.options = options
		self.tableColumns = tableColumns
		self.references = references
		self.statementPerformer = statementPerformer

		// Setup
		tableColumns.forEach() { self.tableColumnsMap["\($0.name)TableColumn"] = $0 }
	}

	// MARK: Property methods
	//------------------------------------------------------------------------------------------------------------------
	public subscript(dynamicMember member :String) -> SQLiteTableColumn {
		// Return table column
		return self.tableColumnsMap[member]!
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func create(ifNotExists :Bool = true) {
		// Setup
		var	tableColumnReferenceMap = [/* column name */ String : SQLiteTableColumn.Reference]()
		self.references.forEach() { tableColumnReferenceMap[$0.tableColumn.name] = $0 }

		let	columnInfos :[String] =
					self.tableColumns.map() {
						// Compose column string
						var	columnInfo = "\($0.name) "

						switch $0.kind {
							case .integer:
								// Integer
								columnInfo += "INTEGER"

							case .integer1:
								// Integer 1
								columnInfo += "INTEGER"
								columnInfo += "(1)"

							case .integer2:
								// Integer 2
								columnInfo += "INTEGER"
								columnInfo += "(2)"

							case .integer3:
								// Integer 3
								columnInfo += "INTEGER"
								columnInfo += "(3)"

							case .integer4:
								// Integer 4
								columnInfo += "INTEGER"
								columnInfo += "(4)"

							case .integer8:
								// Integer 8
								columnInfo += "INTEGER"
								columnInfo += "(8)"

							case .real:
								// Real
								columnInfo += "REAL"

							case .text:
								// Text
								columnInfo += "TEXT"

							case .textWith(let size):
								// Text
								columnInfo += "TEXT"
								columnInfo += "(\(size))"

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

						if let tableColumnReferenceInfo = tableColumnReferenceMap[$0.name] {
							// Add reference
							columnInfo +=
									" REFERENCES \(tableColumnReferenceInfo.referencedTable.name)(\(tableColumnReferenceInfo.referencedTableColumn.name)) ON UPDATE CASCADE"
						}

						return columnInfo
					}

		// Compose create statement
		let	statement =
					"CREATE TABLE" + (ifNotExists ? " IF NOT EXISTS" : "") + " `\(self.name)`" +
							" (" + String(combining: columnInfos) + ")" +
							(self.options.contains(.withoutRowID) ? " WITHOUT ROWID" : "")

		// Create
		self.statementPerformer.perform(statement: statement)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func drop() {
		// Perform
		self.statementPerformer.perform(statement: "DROP TABLE `\(self.name)`")
	}

	//------------------------------------------------------------------------------------------------------------------
	public func hasRow(where sqliteWhere :SQLiteWhere) -> Bool { return count(where: sqliteWhere) > 0 }

	//------------------------------------------------------------------------------------------------------------------
	public func count(where sqliteWhere :SQLiteWhere? = nil) -> UInt {
		// Compose statement
		let	statement = "SELECT COUNT(*) FROM `\(self.name)`" + (sqliteWhere?.string ?? "")

		// Perform
		var	count :UInt = 0
		self.statementPerformer.perform(statement: statement, values: sqliteWhere?.values) {
			// Query count
			count = $0.integer(for: type(of: self).countAllTableColumn)!
		}

		return count
	}

	//------------------------------------------------------------------------------------------------------------------
	public func select(tableColumns :[SQLiteTableColumn]? = nil, innerJoin :SQLiteInnerJoin? = nil,
			where sqliteWhere :SQLiteWhere? = nil, processValuesProc :@escaping SQLiteResultsRow.ProcessValuesProc)
			throws {
		// Check if we have SQLiteWhere
		if sqliteWhere != nil {
			// Iterate all groups in SQLiteWhere
			let	variableNumberLimit = self.statementPerformer.variableNumberLimit
			try sqliteWhere!.forEachValueGroup(chunkSize: variableNumberLimit) { string, values in
				// Compose statement
				let	statement =
							"SELECT " + columnNamesString(for: tableColumns) + " FROM `\(self.name)`" +
									(innerJoin?.string ?? "") + string

				// Run lean
				try autoreleasepool() {
					// Perform
					try self.statementPerformer.perform(statement: statement, values: values,
							processValuesProc: processValuesProc)
				}
			}
		} else {
			// No SQLiteWhere
			let	statement =
						"SELECT " + columnNamesString(for: tableColumns) + " FROM `\(self.name)`" +
								(innerJoin?.string ?? "")

			// Run lean
			try autoreleasepool() {
				// Perform
				// Perform
				try self.statementPerformer.perform(statement: statement, values: nil,
						processValuesProc: processValuesProc)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func insertRow(_ info :[(tableColumn :SQLiteTableColumn, value :Any)]) -> Int64 {
		// Setup
		let	tableColumns = info.map() { $0.tableColumn }
		let	values = info.map() { $0.value }
		let	statement =
					"INSERT INTO `\(self.name)` (" + columnNamesString(for: tableColumns) + ") VALUES (" +
							String(combining: Array(repeating: "?", count: info.count), with: ",") + ")"

		// Perform
		var	lastInsertRowID :Int64 = 0
		self.statementPerformer.perform(statement: statement, values: values) { lastInsertRowID = $0 }

		return lastInsertRowID
	}

	//------------------------------------------------------------------------------------------------------------------
	public func insertRow(_ info :[(tableColumn :SQLiteTableColumn, value :Any)],
			lastInsertRowIDProc :@escaping (_ lastInsertRowID :Int64) -> Void) {
		// Setup
		let	tableColumns = info.map() { $0.tableColumn }
		let	values = info.map() { $0.value }
		let	statement =
					"INSERT INTO `\(self.name)` (" + columnNamesString(for: tableColumns) + ") VALUES (" +
							String(combining: Array(repeating: "?", count: info.count), with: ",") + ")"

		// Perform
		self.statementPerformer.perform(statement: statement, values: values, lastInsertRowIDProc: lastInsertRowIDProc)
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func insertOrReplaceRow(_ info :[(tableColumn :SQLiteTableColumn, value :Any)]) -> Int64 {
		// Setup
		let	tableColumns = info.map() { $0.tableColumn }
		let	values = info.map() { $0.value }
		let	statement =
					"INSERT OR REPLACE INTO `\(self.name)` (" + columnNamesString(for: tableColumns) + ") VALUES (" +
							String(combining: Array(repeating: "?", count: info.count), with: ",") + ")"

		// Perform
		var	lastInsertRowID :Int64 = 0
		self.statementPerformer.perform(statement: statement, values: values) { lastInsertRowID = $0 }

		return lastInsertRowID
	}

	//------------------------------------------------------------------------------------------------------------------
	public func insertOrReplaceRow(_ info :[(tableColumn :SQLiteTableColumn, value :Any)],
			lastInsertRowIDProc :@escaping (_ lastInsertRowID :Int64) -> Void) {
		// Setup
		let	tableColumns = info.map() { $0.tableColumn }
		let	values = info.map() { $0.value }
		let	statement =
					"INSERT OR REPLACE INTO `\(self.name)` (" + columnNamesString(for: tableColumns) + ") VALUES (" +
							String(combining: Array(repeating: "?", count: info.count), with: ",") + ")"

		// Perform
		self.statementPerformer.perform(statement: statement, values: values, lastInsertRowIDProc: lastInsertRowIDProc)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func insertOrReplaceRows(_ tableColumn :SQLiteTableColumn, values :[Any]) {
		// Perform in chunks of SQLITE_LIMIT_VARIABLE_NUMBER
		values.forEachChunk(chunkSize: self.statementPerformer.variableNumberLimit) {
			// Setup
			let	statement =
						"INSERT OR REPLACE INTO `\(self.name)` (" + columnNamesString(for: [tableColumn]) + ") VALUES "
								+ String(combining: Array(repeating: "(?)", count: $0.count), with: ",")

			// Perform
			self.statementPerformer.perform(statement: statement, values: $0)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func update(_ info :[(tableColumn :SQLiteTableColumn, value :Any)], where sqliteWhere :SQLiteWhere) {
		// Setup
		let	statement =
					"UPDATE `\(self.name)` SET " + String(combining: info.map({ "\($0.tableColumn.name) = ?" })) +
							sqliteWhere.string
		let	values = info.map({ $0.value }) + (sqliteWhere.values ?? [])

		// Perform
		self.statementPerformer.perform(statement: statement, values: values)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func deleteRows(_ tableColumn :SQLiteTableColumn, values :[Any]) {
		// Perform in chunks of SQLITE_LIMIT_VARIABLE_NUMBER
		values.forEachChunk(chunkSize: self.statementPerformer.variableNumberLimit) {
			// Setup
			let	statement =
						"DELETE FROM `\(self.name)` WHERE `\(tableColumn.name)` IN (" +
								String(combining: Array(repeating: "?", count: $0.count), with: ",") + ")"

			// Perform
			self.statementPerformer.perform(statement: statement, values: $0)
		}
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func columnNamesString(for tableColumns :[SQLiteTableColumn]?) -> String {
		// Collect column names
		let	columnNames = (tableColumns ?? []).map() { $0.name }

		return !columnNames.isEmpty ? String(combining: columnNames, with: ",") : "*"
	}
}
