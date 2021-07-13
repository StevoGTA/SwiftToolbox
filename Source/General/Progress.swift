//
//  Progress.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/26/21.
//  Copyright © 2021 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Progress
public class Progress {

	// MARK: Properties
	public	var	message :String = "" {
						didSet {
							// Setup
							let	message = self.message

							// Check thread
							if Thread.current == Thread.main {
								// On main thread
								self.messageUpdatedProc(message)
							} else {
								// Queue on main thread
								DispatchQueue.main.async() { [weak self] in self?.messageUpdatedProc(message) }
							}
						}
					}
	public	var	value :Float? = nil {
						didSet {
							// Setup
							let	value = self.value

							// Check thread
							if Thread.current == Thread.main {
								// On main thread
								self.valueUpdatedProc(value)
							} else {
								// Queue on main thread
								DispatchQueue.main.async() { [weak self] in self?.valueUpdatedProc(value) }
							}
						}
					}

			var	messageUpdatedProc :(_ message :String) -> Void = { _ in }
			var	valueUpdatedProc :(_ value :Float?) -> Void = { _ in }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init() {}
}
