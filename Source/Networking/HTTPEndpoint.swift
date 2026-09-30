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
public enum HTTPEndpointMethod : Sendable {

	// Values
	case get
	case delete
	case head
	case patch
	case post
	case put
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointStatusError
public struct HTTPEndpointStatusError : CustomStringConvertible, Error, LocalizedError {

	// MARK: CustomStringConvertible implementation
	public 	var	description :String { self.localizedDescription }

	// MARK: LocalizedError implementation
	public	var	errorDescription :String?
					{ (self.info != nil) ? "\(self.status.description) (\(self.info!))" : self.status.description }

	// MARK: Properties
	public	let	status :HTTPEndpointStatus
	public	let	info :String?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(status :HTTPEndpointStatus, info :String? = nil) {
		// Store
		self.status = status
		self.info = info
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - HTTPEndpointStatus
public enum HTTPEndpointStatus : Equatable, Sendable {
	// Values
	case `continue`
	case switchingProtocol
	case processing
	case earlyHints

	case ok
	case created
	case accepted
	case nonAuthoritativeInformation
	case noContent
	case resetContent
	case partialContent
	case multiStatus
	case alreadyReported
	case imUsed

	case multipleChoice
	case movedPermanently
	case found
	case seeOther
	case notModified
	case useProxy
	case unused
	case temporaryRedirect
	case permanentRedirect

	case badRequest
	case unauthorized
	case paymentRequired
	case forbidden
	case notFound
	case methodNotAllowed
	case notAcceptable
	case proxyAuthenticationRequired
	case timeout
	case conflict
	case gone
	case lengthRequired
	case preconditionFailed
	case payloadTooLarge
	case uriTooLong
	case unsupportedMediaType
	case rangeNotSatisfiable
	case expectationFailed
	case imATeapot
	case misdirectedRequest
	case unprocessableEntity
	case locked
	case failedDependency
	case tooEarly
	case upgradeRequired
	case preconditionRequired
	case tooManyRequests
	case requestHeaderFieldsTooLarge
	case unavailableForLegalReasons

	case internalServerError
	case notImplemented
	case badGateway
	case serviceUnavailable
	case gatewayTimeout
	case httpVersionNotSupported
	case variantAlsoNegotiates
	case insufficientStorage
	case loopDetected
	case notExtended
	case networkAuthenticationRequired

	case other(Int)

	// Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(code :Int) {
		// Check code
		switch code {
			case 100:	self = .`continue`
			case 101:	self = .switchingProtocol
			case 102:	self = .processing
			case 103:	self = .earlyHints

			case 200:	self = .ok
			case 201:	self = .created
			case 202:	self = .accepted
			case 203:	self = .nonAuthoritativeInformation
			case 204:	self = .noContent
			case 205:	self = .resetContent
			case 206:	self = .partialContent
			case 207:	self = .multiStatus
			case 208:	self = .alreadyReported
			case 226:	self = .imUsed

			case 300:	self = .multipleChoice
			case 301:	self = .movedPermanently
			case 302:	self = .found
			case 303:	self = .seeOther
			case 304:	self = .notModified
			case 305:	self = .useProxy
			case 306:	self = .unused
			case 307:	self = .temporaryRedirect
			case 308:	self = .permanentRedirect

			case 400:	self = .badRequest
			case 401:	self = .unauthorized
			case 402:	self = .paymentRequired
			case 403:	self = .forbidden
			case 404:	self = .notFound
			case 405:	self = .methodNotAllowed
			case 406:	self = .notAcceptable
			case 407:	self = .proxyAuthenticationRequired
			case 408:	self = .timeout
			case 409:	self = .conflict
			case 410:	self = .gone
			case 411:	self = .lengthRequired
			case 412:	self = .preconditionFailed
			case 413:	self = .payloadTooLarge
			case 414:	self = .uriTooLong
			case 415:	self = .unsupportedMediaType
			case 416:	self = .rangeNotSatisfiable
			case 417:	self = .expectationFailed
			case 418:	self = .imATeapot
			case 421:	self = .misdirectedRequest
			case 422:	self = .unprocessableEntity
			case 423:	self = .locked
			case 424:	self = .failedDependency
			case 425:	self = .tooEarly
			case 426:	self = .upgradeRequired
			case 428:	self = .preconditionRequired
			case 429:	self = .tooManyRequests
			case 431:	self = .requestHeaderFieldsTooLarge
			case 451:	self = .unavailableForLegalReasons

			case 500:	self = .internalServerError
			case 501:	self = .notImplemented
			case 502:	self = .badGateway
			case 503:	self = .serviceUnavailable
			case 504:	self = .gatewayTimeout
			case 505:	self = .httpVersionNotSupported
			case 506:	self = .variantAlsoNegotiates
			case 507:	self = .insufficientStorage
			case 508:	self = .loopDetected
			case 510:	self = .notExtended
			case 511:	self = .networkAuthenticationRequired

			default:	self = .other(code)
		}
	}

	// Properties
	public	var	code :Int {
						// Check value
						switch self {
							case .`continue`:						return 100
							case .switchingProtocol:				return 101
							case .processing:						return 102
							case .earlyHints:						return 103

							case .ok:								return 200
							case .created:							return 201
							case .accepted:							return 202
							case .nonAuthoritativeInformation:		return 203
							case .noContent:						return 204
							case .resetContent:						return 205
							case .partialContent:					return 206
							case .multiStatus:						return 207
							case .alreadyReported:					return 208
							case .imUsed:							return 226

							case .multipleChoice:					return 300
							case .movedPermanently:					return 301
							case .found:							return 302
							case .seeOther:							return 303
							case .notModified:						return 304
							case .useProxy:							return 305
							case .unused:							return 306
							case .temporaryRedirect:				return 307
							case .permanentRedirect:				return 308

							case .badRequest:						return 400
							case .unauthorized:						return 401
							case .paymentRequired:					return 402
							case .forbidden:						return 403
							case .notFound:							return 404
							case .methodNotAllowed:					return 405
							case .notAcceptable:					return 406
							case .proxyAuthenticationRequired:		return 407
							case .timeout:							return 408
							case .conflict:							return 409
							case .gone:								return 410
							case .lengthRequired:					return 411
							case .preconditionFailed:				return 412
							case .payloadTooLarge:					return 413
							case .uriTooLong:						return 414
							case .unsupportedMediaType:				return 415
							case .rangeNotSatisfiable:				return 416
							case .expectationFailed:				return 417
							case .imATeapot:						return 418
							case .misdirectedRequest:				return 421
							case .unprocessableEntity:				return 422
							case .locked:							return 423
							case .failedDependency:					return 424
							case .tooEarly:							return 425
							case .upgradeRequired:					return 426
							case .preconditionRequired:				return 428
							case .tooManyRequests:					return 429
							case .requestHeaderFieldsTooLarge:		return 431
							case .unavailableForLegalReasons:		return 451

							case .internalServerError:				return 500
							case .notImplemented:					return 501
							case .badGateway:						return 502
							case .serviceUnavailable:				return 503
							case .gatewayTimeout:					return 504
							case .httpVersionNotSupported:			return 505
							case .variantAlsoNegotiates:			return 506
							case .insufficientStorage:				return 507
							case .loopDetected:						return 508
							case .notExtended:						return 510
							case .networkAuthenticationRequired:	return 511

							case .other(let code):					return code
						}
					}

	var	isSuccess :Bool { (self.code >= 200) && (self.code < 300) }

	var	description :String {
				// Check value
				switch self {
					case .`continue`:						return "Continue (100)"
					case .switchingProtocol:				return "Switching Protocol (101)"
					case .processing:						return "Processing (102)"
					case .earlyHints:						return "Early Hints (103)"

					case .ok:								return "OK (200)"
					case .created:							return "Created (201)"
					case .accepted:							return "Accepted (202)"
					case .nonAuthoritativeInformation:		return "Non-Authoritative Information (203)"
					case .noContent:						return "No Content (204)"
					case .resetContent:						return "Reset Content (205)"
					case .partialContent:					return "Partial Content (206)"
					case .multiStatus:						return "Multi-Status (WebDAV) (207)"
					case .alreadyReported:					return "Already Reported (WebDAV) (208)"
					case .imUsed:							return "IM Used (HTTP Delta encoding) (226)"

					case .multipleChoice:					return "Multiple Choice (300)"
					case .movedPermanently:					return "Moved Permanently (301)"
					case .found:							return "Found (302)"
					case .seeOther:							return "See Other (303)"
					case .notModified:						return "Not Modified (304)"
					case .useProxy:							return "Use Proxy (305)"
					case .unused:							return "Unused (306)"
					case .temporaryRedirect:				return "Temporary Redirect (307)"
					case .permanentRedirect:				return "Permanent Redirect (308)"

					case .badRequest:						return "Bad Request (400)"
					case .unauthorized:						return "Unauthorized (401)"
					case .paymentRequired:					return "Payment Required (402)"
					case .forbidden:						return "Forbidden (403)"
					case .notFound:							return "Not Found (404)"
					case .methodNotAllowed:					return "Method Not Allowed (405)"
					case .notAcceptable:					return "Not Acceptable (406)"
					case .proxyAuthenticationRequired:		return "Proxy Authentication Required (407)"
					case .timeout:							return "Request Timeout (408)"
					case .conflict:							return "Conflict (409)"
					case .gone:								return "Gone (410)"
					case .lengthRequired:					return "Length Required (411)"
					case .preconditionFailed:				return "Precondition Failed (412)"
					case .payloadTooLarge:					return "Payload Too Large (413)"
					case .uriTooLong:						return "URI Too Long (414)"
					case .unsupportedMediaType:				return "Unsupported Media Type (415)"
					case .rangeNotSatisfiable:				return "Range Not Satisfiable (416)"
					case .expectationFailed:				return "Expectation Failed (417)"
					case .imATeapot:						return "I'm a teapot (418)"
					case .misdirectedRequest:				return "Misdirected Request (421)"
					case .unprocessableEntity:				return "Unprocessable Entity (WebDAV) (422)"
					case .locked:							return "Locked (WebDAV) (423)"
					case .failedDependency:					return "Failed Dependency (WebDAV) (424)"
					case .tooEarly:							return "Too Early (425)"
					case .upgradeRequired:					return "Upgrade Required (426)"
					case .preconditionRequired:				return "Precondition Required (428)"
					case .tooManyRequests:					return "Too Many Requests (429)"
					case .requestHeaderFieldsTooLarge:		return "Request Header Fields Too Large (431)"
					case .unavailableForLegalReasons:		return "Unavailable For Legal Reasons (451)"

					case .internalServerError:				return "Internal Server Error (500)"
					case .notImplemented:					return "Not Implemented (501)"
					case .badGateway:						return "Bad Gateway (502)"
					case .serviceUnavailable:				return "Service Unavailable (503)"
					case .gatewayTimeout:					return "Gateway Timeout (504)"
					case .httpVersionNotSupported:			return "HTTP Version Not Supported (505)"
					case .variantAlsoNegotiates:			return "Variant Also Negotiates (506)"
					case .insufficientStorage:				return "Insufficient Storage (WebDAV) (507)"
					case .loopDetected:						return "Loop Detected (WebDAV) (508)"
					case .notExtended:						return "Not Extended (510)"
					case .networkAuthenticationRequired:	return "Network Authentication Required (511)"

					case .other(let code):					return "Other (\(code))"
				}
			}
}
