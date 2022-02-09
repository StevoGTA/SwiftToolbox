//
//  JWT.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/8/22.
//  Copyright © 2022 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: JWTError
enum JWTError : Error {
	case decodeError
}

extension JWTError : CustomStringConvertible, LocalizedError {

	// MARK: Properties
	public 	var	description :String { self.localizedDescription }
	public	var	errorDescription :String? {
						switch self {
							case .decodeError:
								return "Decode Error"
						}
					}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - JWT
public struct JWT {

	// MARK: Properties
	public	let	expiration :Date

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(_ string :String) throws {
		// Setup
		let	stringToInfoProc :(_ string :String) throws -> [String : Any] = {
					// Setup
					let	transmogrifiedString =
								$0
										.replacingOccurrences(of: "-", with: "+")
										.replacingOccurrences(of: "_", with: "/")
										.padding(toLength: (($0.count + 3) / 4) * 4, withPad: "=", startingAt: 0)
					guard let data = Data(base64Encoded: transmogrifiedString) else { throw JWTError.decodeError }
					guard let info = try JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else
							{ throw JWTError.decodeError }

					return info
				}

		// Decode
		let	segments = string.components(separatedBy: ".")
		let	segment1Info = try stringToInfoProc(segments[1])
		guard let expiration = Date.withTimeIntervalSince1970(segment1Info["exp"] as? TimeInterval) else
				{ throw JWTError.decodeError }

		// Store
		self.expiration = expiration
	}
}
