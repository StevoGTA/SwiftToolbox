//
//  AnimationTimer.swift
//  Crowd Noise
//
//  Created by Stevo on 11/5/20.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: AnimationTimer
class AnimationTimer : ObservableObject {

	// MARK: Properties
	@Published
			var	frameIndex = 0

	private	var	timer :Timer!

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(framerate :Double) {
		// Setup
		self.timer =
				Timer.scheduledTimer(withTimeInterval: 1.0 / framerate, repeats: true) { [unowned self] _ in
					// Update value
					self.frameIndex += 1
				}
	}

	//------------------------------------------------------------------------------------------------------------------
	init(framerate :Double, completionFrameIndex :Int, completionProc :@escaping () -> Void) {
		// Setup
		self.timer =
				Timer.scheduledTimer(withTimeInterval: 1.0 / framerate, repeats: true) { [unowned self] in
					// Update value
					self.frameIndex += 1

					// Check value
					if self.frameIndex == completionFrameIndex {
						// Done
						$0.invalidate()

						// Call proc
						completionProc()
					}
				}
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
		self.timer.invalidate()
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func invalidate() { self.timer.invalidate() }
}
