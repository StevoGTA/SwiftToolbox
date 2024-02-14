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
open class Progress {

	// MARK: Properties
	public	var	message :String {
						get { self.messageInternal.value }
						set {
							// Store
							self.messageInternal.set(newValue)

							// Call updated proc
							callUpdatedProc()
						}
					}
	public	var	value :Double? = nil {
						didSet {
							// Setup
							let	value = self.value

							// Call updated proc
							callUpdatedProc()
						}
					}
	public	var	elapsedTimeInterval :TimeInterval?
					{ (self.startedDate != nil) ? Date().timeIntervalSince(self.startedDate!) : nil }

	public	var	updatedProc :(_ progress :Progress) -> Void = { _ in }

	private	let	messageInternal = LockingValue<String>("")
	private	let	minimumUpdateTimeInterval :TimeInterval

	private	var	startedDate :Date?
	private	var	lastUpdatedDate :Date?

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(minimumUpdateTimeInterval :TimeInterval = 1.0 / 60.0) {
		// Store
		self.minimumUpdateTimeInterval = minimumUpdateTimeInterval
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func start() { self.startedDate = Date() }

	//------------------------------------------------------------------------------------------------------------------
	public func update(to current :Int, of total :Int) { self.value = Double(current) / Double(total) }

	//------------------------------------------------------------------------------------------------------------------
	public func update(to current :UInt, of total :UInt) { self.value = Double(current) / Double(total) }

	//------------------------------------------------------------------------------------------------------------------
	public func complete() { self.value = 1.0 }

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func callUpdatedProc(force :Bool = false) {
		// Check if need to call updatedProc
		let	date = Date()
		if force || (self.lastUpdatedDate == nil) ||
				(date.timeIntervalSince(self.lastUpdatedDate!) >= self.minimumUpdateTimeInterval) {
			// Update
			self.lastUpdatedDate = date

			// Check thread
			if Thread.current == Thread.main {
				// On main thread
				self.updatedProc(self)
			} else {
				// Queue on main thread
				DispatchQueue.main.async() { [weak self] in if let self { self.updatedProc(self) } }
			}
		}
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: SizeProgress
public class SizeProgress : Progress {

	// MARK: Properties
	public	var	totalSize :Int64 { didSet { updateValue() } }
	public	var	currentSize :Int64 = 0 { didSet { updateValue() } }

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(totalSize :Int64 = 0, minimumUpdateTimeInterval :TimeInterval = 1.0 / 60.0) {
		// Store
		self.totalSize = totalSize

		// Do super
		super.init(minimumUpdateTimeInterval: minimumUpdateTimeInterval)
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func add(size :Int64) { self.currentSize += size }

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func updateValue() {
		// Update value
		self.value = (self.totalSize > 0) ? (Double(self.currentSize) / Double(self.totalSize)) : 0.0
	}
}
