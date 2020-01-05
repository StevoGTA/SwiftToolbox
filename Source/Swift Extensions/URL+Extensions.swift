//
//  URL+Extensions.swift
//  Media Tools
//
//  Created by Stevo on 1/4/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: URLError
public enum URLError : Error {
	case isNotChildOf(rootURL :URL, invalidURL :URL)
}

extension URLError : LocalizedError {
	public	var	errorDescription :String? {
						switch self {
							case .isNotChildOf(let rootURL, let invalidURL):
								return "URL \(invalidURL.path) is not a child of \(rootURL.path)"
						}
					}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: URL
extension URL {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func subPath(relativeTo url :URL) throws -> String {
		// Setup
		let	fullPath = self.path
		let	rootPath = url.path

		// Validate
		guard fullPath.hasPrefix(rootPath) else { throw URLError.isNotChildOf(rootURL: self, invalidURL: url) }

		return fullPath.substring(fromCharacterIndex: rootPath.count)
	}
}
