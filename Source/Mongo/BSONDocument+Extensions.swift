//
//  BSONDocument+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/1/24.
//  Copyright © 2024 Stevo Brock. All rights reserved.
//

import SwiftBSON

//----------------------------------------------------------------------------------------------------------------------
// MARK: BSONDocument extension
public extension BSONDocument {

	// MARK: Properties
	var	dictionary :[String : Any] { Dictionary(self.compactMap({ return ($0, $1.value) })) }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(_ keyValuePairs :[String : Any?]) {
		// Init
		self.init()

		// Iterate key/values
		for (key, value) in keyValuePairs {
			// Check value type
			if let bool = value as? Bool {
				// Bool
				self[key] = BSON(bool)
			} else if let bson = value as? BSON {
				// BSON
				self[key] = bson
			} else if let array = value as? [BSON] {
				// [BSON]
				self[key] = BSON(array)
			} else if let bsonDocument = value as? BSONDocument {
				// BSONDocument
				self[key] = BSON(bsonDocument)
			} else if let bsonObjectID = value as? BSONObjectID {
				// BSONObjectID
				self[key] = BSON(bsonObjectID)
			} else if let array = value as? [BSONObjectID] {
				// [BSONObjectID]
				self[key] = BSON(array)
			} else if let double = value as? Double {
				// Double
				self[key] = BSON(double)
			} else if let int = value as? Int {
				// Int
				self[key] = BSON(int)
			} else if let int32 = value as? Int32 {
				// Int32
				self[key] = BSON(int32)
			} else if let int64 = value as? Int64 {
				// Int64
				self[key] = BSON(int64)
			} else if let string = value as? String {
				// String
				self[key] = BSON(string)
			} else if let array = value as? [String] {
				// [String]
				self[key] = BSON(array)
			} else if let array = value as? [[String : Any]] {
				// [[String : Any]]
				self[key] = BSON(array)
			} else if let dict = value as? [String : Any] {
				// [String : Any]
				self[key] = BSON(dict)
			} else if value != nil {
				// ???
				fatalError("Unknown value type for \(value!)")
			}
		}
	}
}
