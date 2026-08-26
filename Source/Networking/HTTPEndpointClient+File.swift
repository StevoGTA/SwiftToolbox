//
//  HTTPEndpointClient+File.swift
//  Swift Toolbox
//
//  Created by Stevo on 8/26/26.
//  Copyright © 2026 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPEndpointClient File extension
public extension HTTPEndpointClient {

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func queue(_ fileHTTPEndpointRequest :FileHTTPEndpointRequest, identifier :String = "",
			priority :Priority = .normal, progressProc :@escaping FileHTTPEndpointRequest.ProgressProc = { _ in },
			completionProc :@escaping FileHTTPEndpointRequest.CompletionProc) {
		// Setup
		fileHTTPEndpointRequest.progressProc = progressProc
		fileHTTPEndpointRequest.completionProc = completionProc

		// Queue
		queue(fileHTTPEndpointRequest, identifier: identifier, priority: priority)
	}
}
