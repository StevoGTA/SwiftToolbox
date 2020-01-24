//
//  URLComponents+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 12/5/19.
//  Copyright © 2019 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: URLComponents
extension URLComponents {

	// MARK: Properties
	var	queryItemsMap :[String : Any] {
				// Convert queryItems to map
				var	queryItemsMap = [String : Any]()
				self.queryItems?.forEach() {
					// Check for existing value in map
					if let existingValue = queryItemsMap[$0.name] {
						// Additional of this name
						queryItemsMap[$0.name] =
								(existingValue is [String]) ?
										(existingValue as! [String]) + [$0.value!] :
										[(existingValue as! String), $0.value]
					} else {
						// First of this name
						queryItemsMap[$0.name] = $0.value
					}
				}

				return queryItemsMap
			}
}
