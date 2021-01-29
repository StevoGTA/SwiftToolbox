//
//  HTTPURLResponse+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/25/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPURLResponse extension
extension HTTPURLResponse {

	// MARK: Properties
	var	contentRange :(units :String?, start :Int64?, length :Int64?, size :Int64?)? {
				// Specification:
				//	Content-Range: <unit> <range-start>-<range-end>/<size>
				//	Content-Range: <unit> <range-start>-<range-end>/*
				//	Content-Range: <unit> */<size>
				// Examples:
				//	Content-Range: bytes 200-1000/67589
				guard let string = self.value(forHeaderField: "Content-Range") else { return nil }

				let	components = string.components(separatedBy: " ")
				guard components.count == 2 else { return nil }

				let	units = components[0]

				let	parts = components[1].components(separatedBy: "/")
				guard parts.count == 2 else { return nil }
				let	size = Int64(parts[1])

				let	rangeComponents = parts[0].components(separatedBy: "-")
				if rangeComponents.count == 2 {
					// Start and end
					guard let start = Int64(rangeComponents[0]) else { return nil }
					guard let end = Int64(rangeComponents[1]) else { return nil }

					return (units, start, end - start + 1, size)
				} else {
					// Probably just size
					return (units, nil, nil, size)
				}
			}
	var	contentType :String? { self.allHeaderFields["Content-Type"] as? String }

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func contentRangeHeader(for units :String, size :Int64) -> (String, String) {
		// Return info
		return ("Content-Range", "\(units) */\(size)")
	}

	//------------------------------------------------------------------------------------------------------------------
	static func contentRangeHeader(for units :String, start :Int64, length :Int64) -> (String, String) {
		// Return info
		return ("Content-Range", "\(units) \(start)-\(start + length - 1)/*")
	}

	//------------------------------------------------------------------------------------------------------------------
	static func contentRangeHeader(for units :String, start :Int64, length :Int64, size :Int64) -> (String, String) {
		// Return info
		return (size > 0) ?
				("Content-Range", "\(units) \(start)-\(start + length - 1)/\(size)") :
				("Content-Range", "\(units) */0")
	}

	//------------------------------------------------------------------------------------------------------------------
	static func contentTypeHeader(for contentType :String) -> (String, String) { ("Content-Type", contentType) }

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func value(forHeaderField field :String) -> String? {
		// Setup
		let	fieldUse = field.lowercased()

		return self.allHeaderFields.first(where: { ($0.key as! String).lowercased() == fieldUse })?.value as? String
	}
}
