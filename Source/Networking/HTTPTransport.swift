//
//  HTTPTransport.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/30/26.
//  Copyright © 2026 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: HTTPTransportTask
@objc public protocol HTTPTransportTask {

	// MARK: Methods
	//------------------------------------------------------------------------------------------------------------------
	func cancel()
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPTransport
public protocol HTTPTransport : AnyObject {

	// MARK: Types
	typealias DataCompletionProc = (_ response :HTTPURLResponse?, _ data :Data?, _ error :Error?) -> Void
	typealias StreamDataProc = (_ data :Data) -> Void
	typealias StreamCompletionProc = (_ response :HTTPURLResponse?, _ error :Error?) -> Void
	typealias FileProgressProc = (_ progress :Double) -> Void
	typealias FileCompletionProc = (_ response :HTTPURLResponse?, _ url :URL?, _ error :Error?) -> Void

	// MARK: Properties
	var	maximumConcurrentRequests :Int { get }

	// MARK: Methods
	//------------------------------------------------------------------------------------------------------------------
	func perform(_ urlRequest :URLRequest, redirectBody :Data?, completionProc :@escaping DataCompletionProc) ->
			HTTPTransportTask

	//------------------------------------------------------------------------------------------------------------------
	func perform(_ urlRequest :URLRequest, dataProc :@escaping StreamDataProc,
			completionProc :@escaping StreamCompletionProc) -> HTTPTransportTask

	//------------------------------------------------------------------------------------------------------------------
	func perform(_ urlRequest :URLRequest, progressProc :@escaping FileProgressProc,
			completionProc :@escaping FileCompletionProc) -> HTTPTransportTask
}
