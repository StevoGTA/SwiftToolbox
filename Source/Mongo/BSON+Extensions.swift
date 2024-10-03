//
//  BSON+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/1/24.
//  Copyright © 2024 Stevo Brock. All rights reserved.
//

import SwiftBSON

//----------------------------------------------------------------------------------------------------------------------
// MARK: BSON extension
public extension BSON {

	// MARK: Properties
	var	value: Any {
				// Check type
				switch self.type {
					case .document:	return self.documentValue!.dictionary
					case .int32:	return self.int32Value!
					case .int64:	return self.int64Value!
					case .array:	return self.arrayValue!.map({ $0.value })
					case .bool:		return self.boolValue!
					case .datetime:	return self.dateValue!
					case .double:	return self.doubleValue!
					case .string:	return self.stringValue!
					default:
						fatalError("Unhandled type: \(self.type)")
				}
			}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(_ value :Bool) { self = .bool(value) }

	//------------------------------------------------------------------------------------------------------------------
	init(_ value :[BSON]) { self = .array(value) }

	//------------------------------------------------------------------------------------------------------------------
	init(_ value :BSONDocument) { self = .document(value) }

	//------------------------------------------------------------------------------------------------------------------
	init(_ value :BSONObjectID) { self = .objectID(value) }

	//------------------------------------------------------------------------------------------------------------------
	init(_ value :[BSONObjectID]) { self = .array(value.map({ BSON($0) })) }

	//------------------------------------------------------------------------------------------------------------------
	init(_ value :Double) { self = .double(value) }

	//------------------------------------------------------------------------------------------------------------------
	init(_ value :Int32) { self = .int32(value) }

	//------------------------------------------------------------------------------------------------------------------
	init(_ value :Int64) { self = .int64(value) }

	//------------------------------------------------------------------------------------------------------------------
	init(_ value :String) { self = .string(value) }

	//------------------------------------------------------------------------------------------------------------------
	init(_ value :[String]) { self = .array(value.map({ BSON($0) })) }

	//------------------------------------------------------------------------------------------------------------------
	init(_ value :[[String : Any]]) { self = .array(value.map({ BSON($0) })) }

	//------------------------------------------------------------------------------------------------------------------
	init(_ value :[String : Any]) { self = .document(BSONDocument(value)) }
}
