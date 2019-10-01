//
//  UUID+Extensions.swift
//
//  Created by Stevo on 10/18/18.
//  Copyright © 2018 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: UUID extension
extension UUID {

	// MARK: Properties
	public	var	base64EncodedString :String {
						// Convert bytes to data
						let	x = self.uuid
						let	data =
									Data([x.0, x.1, x.2, x.3, x.4, x.5, x.6, x.7, x.8, x.9, x.10, x.11, x.12, x.13,
											x.14, x.15])

						return String(data.base64EncodedString().dropLast(2))
					}
}
