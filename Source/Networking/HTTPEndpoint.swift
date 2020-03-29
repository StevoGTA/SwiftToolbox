//
//  HTTPEndpoint.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/23/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPEndpointMethod
enum HTTPEndpointMethod {
	case get
	case head
	case patch
	case post
	case put
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointStatus
enum HTTPEndpointStatus : UInt {
	case ok = 200

	case badRequest = 400
	case unauthorized = 401
	case forbidden = 403
	case notFound = 404
	case conflict = 409

	case internalServerError = 500
}
