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
	var	dictionary :[String : Any] {
				// Return as dictionary
				Dictionary(
					self.compactMap({
						// Check value type
						switch $1 {
							case .document(let document):	return ($0, document.dictionary)
							case .int32(let int32):			return ($0, int32)
							case .int64(let int64):			return ($0, int64)
							case .bool(let bool):			return ($0, bool)
							case .double(let double):		return ($0, double)
							case .string(let string):		return ($0, string)

							case .array(let array):
								// Array
								if array is [String] {
									// [String]
									return ($0, array.map({ $0.stringValue! }))
								} else if array is [BSONDocument] {
									// [BSONDocument]
									return ($0, array.map({ $0.documentValue!.dictionary }))
								} else {
									// ???
									fatalError("Unknown value type for \($1)")
								}

							default:
								fatalError("Unknown value type for \($1)")
						}
					}))
			}

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
