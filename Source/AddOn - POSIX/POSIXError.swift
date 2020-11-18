//
//  POSIXError.swift
//  Swift Toolbox
//
//  Created by Stevo on 4/20/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: POSIXError
enum POSIXError : Error {
	case general(_ errno :Int32)
}

extension POSIXError : LocalizedError {

	// MARK: Properties
	public	var	errorDescription :String?
					{ switch self { case .general(let errno):	return String(validatingUTF8: strerror(errno))! } }
}
