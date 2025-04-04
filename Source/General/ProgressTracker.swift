//
//  ProgressTracker.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/19/24.
//  Copyright © 2024 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: SizeProgressTracker
public class SizeProgressTracker {

	// MARK: SizeProgressInfo
	private class SizeProgressInfo {

		// MARK: TimeDeltaInfo
		struct TimeDeltaInfo {

			// MARK: Properties
			let	deltaSize :Int64
			let	deltaTimeInterval :TimeInterval
		}

		// MARK: Properties
		let	sizeProgress :SizeProgress

		var	lastCurrentSize :Int64
		var	lastDate :Date

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(_ sizeProgress :SizeProgress) {
			// Store
			self.sizeProgress = sizeProgress

			// Setup
			self.lastCurrentSize = self.sizeProgress.currentSize
			self.lastDate = Date()
		}

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		func composeTimeDeltaInfo(for date :Date) -> TimeDeltaInfo {
			// Setup
			let	currentSize = self.sizeProgress.currentSize

			// Compose TimeDeltaInfo
			let	timeDeltaInfo =
						TimeDeltaInfo(deltaSize: currentSize - self.lastCurrentSize,
								deltaTimeInterval: date.timeIntervalSince(self.lastDate))

			// Update
			self.lastCurrentSize = currentSize
			self.lastDate = date

			return timeDeltaInfo
		}
	}

	// MARK: TimeSliceInfo
	private class TimeSliceInfo {

		// MARK: Properties
		private(set)	var	transferRate = 0.0
		private(set)	var	count = 0
						var	transferRatePerItem :Double { (count > 0) ? transferRate / Double(count) : 0.0 }

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		func add(_ timeDeltaInfo :SizeProgressInfo.TimeDeltaInfo) {
			// Update
			self.transferRate += Double(timeDeltaInfo.deltaSize) / timeDeltaInfo.deltaTimeInterval
			self.count += 1
		}
	}

	// MARK: Properties
	private	var	sizeProgressInfos = LockingArray<SizeProgressInfo>()
	private	var	timeSliceInfos = [TimeSliceInfo]()
	private	var	timer :Timer!

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(with interval :TimeInterval = 1.0) {
		// Setup timer
		self.timer =
				Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [unowned self] _ in self.update() }
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
		// Cleanup
		self.timer.invalidate()
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func add(_ sizeProgress :SizeProgress) { self.sizeProgressInfos.append(SizeProgressInfo(sizeProgress)) }

	//------------------------------------------------------------------------------------------------------------------
	public func remove(_ sizeProgress :SizeProgress) {
		// Remove
		self.sizeProgressInfos.removeAll(where: {$0.sizeProgress === sizeProgress} )
	}

	//------------------------------------------------------------------------------------------------------------------
	public func info(for remainingSize :Int64, remainingItems :Int, parallelItems :Int) ->
			(averageTransferRate :Double, estimatedTimeIntervalRemaining :TimeInterval?) {
		// Compose info
		let	count = Double(self.timeSliceInfos.count)
		guard count > 0.0 else { return (0.0, nil) }

		let	averageTransferRate = self.timeSliceInfos.reduce(0.0, { $0 + $1.transferRate }) / count

		let	averageTransferRatePerItem = self.timeSliceInfos.reduce(0.0, { $0 + $1.transferRatePerItem }) / count
		let	estimatedTimeIntervalRemaining :TimeInterval?
		if (remainingSize > 0) && (averageTransferRatePerItem > 0.0) && (parallelItems > 0) {
			// Have info to calculate
			estimatedTimeIntervalRemaining =
					Double(remainingSize) / averageTransferRatePerItem / Double(min(remainingItems, parallelItems))
		} else {
			// Nothing to do or no way to do it
			estimatedTimeIntervalRemaining = nil
		}

		return (averageTransferRate, estimatedTimeIntervalRemaining)
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func update() {
		// Setup
		let	date = Date()

		// Compose new time slice info
		let	timeSliceInfo = TimeSliceInfo()
		self.sizeProgressInfos.values.forEach() { timeSliceInfo.add($0.composeTimeDeltaInfo(for: date)) }

		// Update storage
		self.timeSliceInfos.append(timeSliceInfo)
		if self.timeSliceInfos.count > 10 {
			// Drop oldest one
			self.timeSliceInfos = Array(self.timeSliceInfos.dropFirst())
		}
	}
}
