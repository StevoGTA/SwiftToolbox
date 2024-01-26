//
//  SQLiteLimit.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/14/22.
//  Copyright © 2022 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: SQLiteLimit
public class SQLiteLimit {

	// MARK: Properties
	let	string :String

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(limit :Int?, offset :Int) {
		// Setup
		self.string = " LIMIT \(limit ?? -1) OFFSET \(offset)"
	}

	//------------------------------------------------------------------------------------------------------------------
	public init(limit :Int?) {
		// Setup
		self.string = " LIMIT \(limit ?? -1)"
	}
}
