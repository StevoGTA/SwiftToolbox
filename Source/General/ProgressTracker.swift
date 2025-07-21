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
		func composeTimeDeltaInfo(for date :Date) -> TimeDeltaInfo? {
			// Check if should report info.  We only report info if progress is tracked and has changed
			if (self.sizeProgress.currentSize > self.lastCurrentSize) || (self.sizeProgress.currentSize > 0) {
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
			} else {
				// Either progress is not being tracked, or hasn't changed in this cycle
				return nil
			}
		}
	}

	// MARK: TimeSliceInfo
	private class TimeSliceInfo {

		// MARK: Properties
		private(set)	var	rate = 0.0
		private(set)	var	count = 0
						var	ratePerItem :Double { (count > 0) ? rate / Double(count) : 0.0 }

		// MARK: Instance methods
		//--------------------------------------------------------------------------------------------------------------
		func add(_ timeDeltaInfo :SizeProgressInfo.TimeDeltaInfo) {
			// Update
			self.rate += Double(timeDeltaInfo.deltaSize) / timeDeltaInfo.deltaTimeInterval
			self.count += 1
		}
	}

	// MARK: Properties
	private	let	arraysLock = Lock()
	private	var	sizeProgressInfos = [SizeProgressInfo]()
	private	var	recentlyCompletedSizeProgressInfos = [SizeProgressInfo]()

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
	public func add(_ sizeProgress :SizeProgress) {
		// Add
		self.arraysLock.perform({ self.sizeProgressInfos.append(SizeProgressInfo(sizeProgress)) })
	}

	//------------------------------------------------------------------------------------------------------------------
	public func remove(_ sizeProgress :SizeProgress) {
		// Move to recently completed
		self.arraysLock.perform() {
			// Try to find
			if let index = self.sizeProgressInfos.firstIndex(where: { $0.sizeProgress === sizeProgress }) {
				// Move
				self.recentlyCompletedSizeProgressInfos.append(self.sizeProgressInfos.remove(at: index))
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func info(for remainingSize :Int64, remainingItems :Int, parallelItems :Int) ->
			(averageRate :Double, estimatedTimeIntervalRemaining :TimeInterval?) {
		// Compose info
		let	count = Double(self.timeSliceInfos.count)
		guard count > 0.0 else { return (0.0, nil) }

		let	averageRate = self.timeSliceInfos.reduce(0.0, { $0 + $1.rate }) / count

		let	averageRatePerItem = self.timeSliceInfos.reduce(0.0, { $0 + $1.ratePerItem }) / count
		let	estimatedTimeIntervalRemaining :TimeInterval?
		if (remainingSize > 0) && (averageRatePerItem > 0.0) && (parallelItems > 0) {
			// Have info to calculate
			estimatedTimeIntervalRemaining =
					Double(remainingSize) / averageRatePerItem / Double(min(remainingItems, parallelItems))
		} else {
			// Nothing to do or no way to do it
			estimatedTimeIntervalRemaining = nil
		}

		return (averageRate, estimatedTimeIntervalRemaining)
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	private func update() {
		// Setup
		let	date = Date()

		// Compose new time slice info
		let	timeSliceInfo = TimeSliceInfo()
		self.arraysLock.perform() {
			// Process current SizeProgressInfos
			self.sizeProgressInfos
					.compactMap({ $0.composeTimeDeltaInfo(for: date) })
					.forEach({ timeSliceInfo.add($0) })

			// Process recently completed SizeProgressInfos
			self.recentlyCompletedSizeProgressInfos
					.compactMap({ sizeProgressInfo -> SizeProgressInfo.TimeDeltaInfo? in
						//
						guard sizeProgressInfo.lastCurrentSize < sizeProgressInfo.sizeProgress.totalSize else {
							// Nothing to report
							return nil
						}

						return SizeProgressInfo.TimeDeltaInfo(
								deltaSize: sizeProgressInfo.sizeProgress.totalSize - sizeProgressInfo.lastCurrentSize,
								deltaTimeInterval: date.timeIntervalSince(sizeProgressInfo.lastDate))
					})
					.forEach({ timeSliceInfo.add($0) })
			self.recentlyCompletedSizeProgressInfos.removeAll()
		}

		// Update storage
		self.timeSliceInfos.append(timeSliceInfo)
		if self.timeSliceInfos.count > 10 {
			// Drop oldest one
			self.timeSliceInfos = Array(self.timeSliceInfos.dropFirst())
		}
	}
}
