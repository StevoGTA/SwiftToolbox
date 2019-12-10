//
//  URLComponents+Extensions.swift
//  Media Tools
//
//  Created by Stevo on 12/5/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

//----------------------------------------------------------------------------------------------------------------------
// MARK: URLComponents
extension URLComponents {

	// MARK: Properties
	var	queryItemsMap :[String : String] {
				// Convert queryItems to map
				var	queryItemsMap = [String : String]()
				self.queryItems?.forEach() { queryItemsMap[$0.name] = $0.value }

				return queryItemsMap
			}
}
