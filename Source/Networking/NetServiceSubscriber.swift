//
//  NetServiceSubscriber.swift
//  Swift Toolbox
//
//  Created by Stevo on 10/6/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

#if os(iOS) || os(tvOS)
	import UIKit
#endif

//----------------------------------------------------------------------------------------------------------------------
// MARK: NetServiceSubscriber
class NetServiceSubscriber : NSObject, NetServiceBrowserDelegate, NetServiceDelegate {

	// MARK: Properties
	static			let	domainDefault = "local."
	static			let	domainAll = ""

	static			let	typeHTTPTCP = "_http._tcp."
	static			let	typeAll = "_services._dns-sd._udp."

	static			let	nameAll = "*"

					var	isSearching = false
					var	logActions = false

					var	serviceAvailableProc
								:(_ domain :String, _ type :String, _ name :String, _ hostName :String?, _ port :Int) ->
										Void = { _,_,_,_,_ in }
					var	serviceResignedProc :(_ domain :String, _ type :String, _ name :String) -> Void = { _,_,_ in }
					var	allServicesResignedProc :() -> Void = {}

			private	let	domain :String
			private	let	type :String
			private	let	name :String

			private	let	netServiceBrowser = NetServiceBrowser()

			private	var	servicesBeingResolved = Set<NetService>()

#if os(iOS) || os(watchOS) || os(tvOS)
			private	var	applicationDidEnterBackgroundNotificationObserver :Any!
			private	var	applicationWillEnterForegroundNotificationObserver :Any!
#endif

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(domain :String = NetServiceSubscriber.domainDefault, type :String = NetServiceSubscriber.typeHTTPTCP,
			name :String) {
		// Store
		self.domain = domain
		self.type = type
		self.name = name

		// Do super
		super.init()

		// Register notifications
#if os(iOS) || os(watchOS) || os(tvOS)
		self.applicationDidEnterBackgroundNotificationObserver =
				NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification)
						{ [unowned self] _ in
							// Check if searching
							if self.isSearching {
								// Check logging
								if self.logActions {
									// Log
									NSLog("NetServiceSubscriber: stopping service search for \(self.domain)/\(self.type)/\(self.name)")
								}

								// Stop search
								self.netServiceBrowser.stop()
							}

							// Call proc
							self.allServicesResignedProc()
						}
		self.applicationWillEnterForegroundNotificationObserver =
				NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification)
						{ [unowned self] _ in
							// Check if was searching
							if self.isSearching {
								// Check logging
								if self.logActions {
									// Log
									NSLog("NetServiceSubscriber resuming service search for \(self.domain)/\(self.type)/\(self.name)")
								}

								// Start
								self.netServiceBrowser.searchForServices(ofType: self.type, inDomain: self.domain)
							}
						}
#endif

		// Finish setup
		self.netServiceBrowser.delegate = self
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
#if os(iOS) || os(watchOS) || os(tvOS)
		NotificationCenter.default.removeObserver(self.applicationDidEnterBackgroundNotificationObserver)
		NotificationCenter.default.removeObserver(self.applicationWillEnterForegroundNotificationObserver)
#endif

		// Stop
		stopSearch()
	}

	// MARK: NSNetServiceBrowserDelegate methods
	//------------------------------------------------------------------------------------------------------------------
    func netServiceBrowser(_ browser :NetServiceBrowser, didNotSearch errorDict :[String : NSNumber]) {
    	// Check for logging
    	if self.logActions {
    		// Log
    		NSLog("NetServiceSubscriber: did not search with error info: \(errorDict)")
    	}
	}

	//------------------------------------------------------------------------------------------------------------------
    func netServiceBrowser(_ browser :NetServiceBrowser, didFindDomain domainString :String, moreComing :Bool) {
    	// Check for logging
    	if self.logActions {
    		// Log
    		NSLog("NetServiceSubscriber: did find domain \"\(domainString)\"\(moreComing ? ", with more coming..." : "")")
    	}
	}

	//------------------------------------------------------------------------------------------------------------------
    func netServiceBrowser(_ browser :NetServiceBrowser, didFind service :NetService, moreComing :Bool) {
    	// Check for logging
    	if self.logActions {
    		// Log
    		NSLog("NetServiceSubscriber: service \(service.domain)/\(service.type)/\(service.name) now available")
    	}

    	// Check if interested
    	if (self.name == NetServiceSubscriber.nameAll) || (service.name == self.name) {
    		// Yes, let's resolve
    		self.servicesBeingResolved.insert(service)
    		service.delegate = self
    		service.resolve(withTimeout: 10.0)
    	}
	}

	//------------------------------------------------------------------------------------------------------------------
    func netServiceBrowser(_ browser :NetServiceBrowser, didRemove service :NetService, moreComing :Bool) {
    	// Check for logging
    	if self.logActions {
    		// Log
    		NSLog("NetServiceSubscriber: service \(service.domain)/\(service.type)/\(service.name) gone away")
    	}

    	// Call proc
    	self.serviceResignedProc(service.domain, service.type, service.name)
    }

	// MARK: NetServiceDelegate methods
	//------------------------------------------------------------------------------------------------------------------
    func netServiceDidResolveAddress(_ service :NetService) {
    	// Check for logging
    	if self.logActions {
    		// Log
			NSLog("NetServiceSubscriber: service \(service.domain)/\(service.type)/\(service.name) resolved to \(service.hostName ?? "<UNKNOWN>"):\(service.port)")
    	}

    	// Update
    	self.servicesBeingResolved.remove(service)

    	// Call proc
    	self.serviceAvailableProc(service.domain, service.type, service.name, service.hostName, service.port)
    }

	//------------------------------------------------------------------------------------------------------------------
    func netService(_ service :NetService, didNotResolve errorDict :[String : NSNumber]) {
    	// Check for logging
    	if self.logActions {
    		// Log
    		NSLog("NetServiceSubscriber: service \(service.domain)/\(service.type)/\(service.name) could not be resolved")
    	}

    	// Update
    	self.servicesBeingResolved.remove(service)
    }

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func startSearch() {
		// Check if searching
		if self.isSearching {
			// Stop
			self.netServiceBrowser.stop()
		}

		// Log
		if self.logActions {
			// Log
			NSLog("NetServiceSubscriber starting service search for \(self.domain)/\(self.type)/\(self.name)")
		}

		// Start search
		self.netServiceBrowser.searchForServices(ofType: self.type, inDomain: self.domain)
		self.isSearching = true
	}

	//------------------------------------------------------------------------------------------------------------------
	func stopSearch() {
		// Check if searching
		guard self.isSearching else { return }

		// Check logging
		if self.logActions {
			// Log
			NSLog("NetServiceSubscriber: stopping service search for \(self.domain)/\(self.type)/\(self.name)")
		}

		// Stop search
		self.netServiceBrowser.stop()
		self.isSearching = false

		// Cleanup
		self.servicesBeingResolved.removeAll()
	}
}
