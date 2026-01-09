//
//  Timer+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 1/24/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Timer Extension
public extension Timer {

	// MARK: Types
	typealias Proc = @Sendable (_ timer :Timer) -> Void

	// MARK: AutoInvalidating
	class AutoInvalidating {

		// MARK: Properties
		private	var	timer :Timer

		// MARK: Class methods
		//--------------------------------------------------------------------------------------------------------------
		static func scheduled(withTimeInterval timeInterval :TimeInterval, repeats :Bool = false,
				runLoop :RunLoop = .current, proc :@escaping Proc) -> AutoInvalidating {
			// Setup
			return AutoInvalidating(timeInterval: timeInterval, repeats: repeats, runLoop: runLoop, proc: proc)
		}

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		private init(timeInterval :TimeInterval, repeats :Bool, runLoop :RunLoop, proc :@escaping Proc) {
			// Setup
			self.timer = Timer.scheduled(withTimeInterval: timeInterval, repeats: repeats, runLoop: runLoop, proc: proc)
		}

		//--------------------------------------------------------------------------------------------------------------
		deinit {
			// Cleanup
			self.timer.invalidate()
		}
	}

	// MARK: ProcCaller
	private class ProcCaller {

		// MARK: Properties
		let	fireProc :(_ timer :Timer) -> Void

		// MARK: Lifecycle methods
		//------------------------------------------------------------------------------------------------------------------
		init(fireProc :@escaping (_ timer :Timer) -> Void) {
			// Store
			self.fireProc = fireProc
		}

		// MARK: Instance methods
		//------------------------------------------------------------------------------------------------------------------
		@objc func timerFireMethod(timer :Timer) {
			// Call proc
			self.fireProc(timer)
		}
	}

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static func scheduled(withTimeInterval timeInterval :TimeInterval, repeats :Bool = false,
			runLoop :RunLoop = .current, proc :@escaping Proc) -> Timer {
		// Setup
		let	timer :Timer
		if #available(OSX 10.12, *) {
			// Use framework version
			timer = Timer(timeInterval: timeInterval, repeats: repeats, block: proc)
		} else {
			// Setup
			let	procCaller = ProcCaller(fireProc: proc)

			// Init
			timer =
					Timer(timeInterval: timeInterval, target: procCaller, selector: #selector(timerFireMethod(timer:)),
							userInfo: nil, repeats: false)
		}

		// Schedule
		runLoop.add(timer, forMode: .common)

		return timer
	}

	//------------------------------------------------------------------------------------------------------------------
	static func scheduled(firingAt date :Date, runLoop :RunLoop = .current, proc :@escaping Proc) -> Timer {
		// Setup
		let	timer = Timer(fireAt: date, proc: proc)

		// Schedule
		runLoop.add(timer, forMode: .common)

		return timer
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	convenience init(timeInterval :TimeInterval, proc :@escaping Proc) {
		// Check availability
		if #available(OSX 10.12, *) {
			// Use framework version
			self.init(timeInterval: timeInterval, repeats: false, block: proc)
		} else {
			// Setup
			let	procCaller = ProcCaller(fireProc: proc)

			// Init
			self.init(timeInterval: timeInterval, target: procCaller, selector: #selector(timerFireMethod(timer:)),
					userInfo: nil, repeats: false)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	convenience init(fireAt date :Date, proc :@escaping Proc) {
		// Check availability
		if #available(OSX 10.12, *) {
			// Use framework version
			self.init(fire: date, interval: 0.0, repeats: false, block: proc)
		} else {
			// Setup
			let	procCaller = ProcCaller(fireProc: proc)

			// Init
			self.init(fireAt: date, interval: 0.0, target: procCaller, selector: #selector(timerFireMethod(timer:)),
					userInfo: nil, repeats: false)
		}
	}

	// MARK: Dummy methods
	//------------------------------------------------------------------------------------------------------------------
	// We want to reference this method on the TimerProcCaller class, but can't seem to get the Swift compiler to do
	//	that
	@objc private func timerFireMethod(timer :Timer) {}
}
