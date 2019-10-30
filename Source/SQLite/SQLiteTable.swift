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
	static	private	let	countAllTableColumn = SQLiteTableColumn("COUNT(*)", .integer(size: nil, default: nil), [])

					let	name :String

			private	let	options :Options
			private	let	tableColumns :[SQLiteTableColumn]
			private	let	references :[SQLiteTableColumn.Reference]
			private	let	statementPerformer :SQLiteStatementPerfomer

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
	}

	// MARK: Property methods
	//------------------------------------------------------------------------------------------------------------------
	public subscript(dynamicMember member :String) -> SQLiteTableColumn {
		// Setup
		let	tableColumnName = "\(member)TableColumn"

		// Return table column
		return self.tableColumns.first(where: { $0.name == tableColumnName })!
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
							" (" + String(combining: columnInfos, with: ", ") + ")" +
							(self.options.contains(.withoutRowID) ? " WITHOUT ROWID" : "")

		// Create
		self.statementPerformer.perform(statement: statement)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func count(where sqliteWhere :SQLiteWhere? = nil) -> Int {
		// Compose statement
		let	statement = "SELECT COUNT(*) FROM `\(self.name)`" + ((sqliteWhere != nil) ? sqliteWhere!.string : "")

		// Perform
		var	count = 0
		self.statementPerformer.perform(statement: statement, values: sqliteWhere?.values) {
			// Query count
			$0.next()
			count = $0.integer(for: type(of: self).countAllTableColumn)!
		}

		return count
	}

	//------------------------------------------------------------------------------------------------------------------
	public func select(tableColumns :[SQLiteTableColumn]? = nil,
			innerJoin :(table :SQLiteTable, tableColumn :SQLiteTableColumn)? = nil,
			where sqliteWhere :SQLiteWhere? = nil, resultsProc :@escaping (_ results :SQLiteResults) -> Void) {
		// Compose statement
		let	statement =
					"SELECT " + columnNamesString(for: tableColumns) + " FROM `\(self.name)`" +
							string(for: innerJoin) + ((sqliteWhere != nil) ? sqliteWhere!.string : "")

		// Perform
		self.statementPerformer.perform(statement: statement, values: sqliteWhere?.values, resultsProc: resultsProc)
	}

	//------------------------------------------------------------------------------------------------------------------
	@discardableResult
	public func insert(_ info :[(tableColumn :SQLiteTableColumn, value :Any)]) -> Int64 {
		// Setup
		let	tableColumns = info.map() { $0.tableColumn }
		let	values = info.map() { $0.value }
		let	statement =
					"INSERT INTO `\(self.name)` (" + columnNamesString(for: tableColumns) + ") VALUES (" +
							String(combining: Array(repeating: "?", count: info.count), with: ",") + ")"

		// Perform
		self.statementPerformer.perform(statement: statement, values: values)

		return self.statementPerformer.lastInsertRowID
	}

	//------------------------------------------------------------------------------------------------------------------
	public func insert(_ info :[(tableColumn :SQLiteTableColumn, value :Any)],
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
	public func insertOrReplace(_ info :[(tableColumn :SQLiteTableColumn, value :Any)]) -> Int64 {
		// Setup
		let	tableColumns = info.map() { $0.tableColumn }
		let	values = info.map() { $0.value }
		let	statement =
					"INSERT OR REPLACE INTO `\(self.name)` (" + columnNamesString(for: tableColumns) + ") VALUES (" +
							String(combining: Array(repeating: "?", count: info.count), with: ",") + ")"

		// Perform
		self.statementPerformer.perform(statement: statement, values: values)

		return self.statementPerformer.lastInsertRowID
	}

	//------------------------------------------------------------------------------------------------------------------
	public func insertOrReplace(_ info :[(tableColumn :SQLiteTableColumn, value :Any)],
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
	public func update(_ info :[(tableColumn :SQLiteTableColumn, value :Any)], where sqliteWhere :SQLiteWhere) {
		// Setup
		let	statement =
					"UPDATE `\(self.name)` SET " +
							String(combining: info.map({ "\($0.tableColumn.name) = ?" }), with: ", ") +
							sqliteWhere.string
		let	values = info.map({ $0.value }) + (sqliteWhere.values ?? [])

		// Perform
		self.statementPerformer.perform(statement: statement, values: values)
	}

	//------------------------------------------------------------------------------------------------------------------
	public func delete(where sqliteWhere :SQLiteWhere) {
		// Setup
		let	statement = "DELETE FROM `\(self.name)`" + sqliteWhere.string

		// Perform
		self.statementPerformer.perform(statement: statement, values: sqliteWhere.values)
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func columnNamesString(for tableColumns :[SQLiteTableColumn]?) -> String {
		// Collect column names
		let	columnNames = (tableColumns ?? []).map() { $0.name }

		return !columnNames.isEmpty ? String(combining: columnNames, with: ",") : "*"
	}

	//------------------------------------------------------------------------------------------------------------------
	private func string(for innerJoin :(table :SQLiteTable, tableColumn :SQLiteTableColumn)?) -> String {
		// Return string
		return (innerJoin != nil) ?
				" INNER JOIN `\(innerJoin!.table.name)` ON " +
						"`\(innerJoin!.table.name)`.`\(innerJoin!.tableColumn.name)` = " +
						"`\(self.name)`.`\(innerJoin!.tableColumn.name)`" :
				""
	}
}
