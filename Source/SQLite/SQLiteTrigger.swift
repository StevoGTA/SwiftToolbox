//
//  SQLiteTrigger.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/9/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: SQLiteTrigger
public struct SQLiteTrigger {

	// MARK: Properties
	private	let	updateTableColumn :SQLiteTableColumn
	private	let	comparisonTableColumn :SQLiteTableColumn

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(updateTableColumn :SQLiteTableColumn, comparisonTableColumn :SQLiteTableColumn) {
		// Store
		self.updateTableColumn = updateTableColumn
		self.comparisonTableColumn = comparisonTableColumn
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func string(for tableName :String) -> String {
		// Return string
		return "CREATE TRIGGER \(self.updateTableColumn.name)Trigger" +
				" AFTER UPDATE ON \(tableName)" +
				" FOR EACH ROW" +
				" BEGIN UPDATE \(tableName)" +
				" SET \(self.updateTableColumn.name)=\(self.updateTableColumn.defaultValue!)" +
				" WHERE \(self.comparisonTableColumn.name)=NEW.\(self.comparisonTableColumn.name);" +
				" END"
	}
}
