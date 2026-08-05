//
//  FileWriter.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/3/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: FileWriter
/*
	Writes a file.  Opens on init and closes on deinit, so there is no separate open/close dance, no reopening, and
		no unopened or closed-but-still-around states to reason about.

	The following are independent options - engage only what is needed:
		staged			write to a temp file on the same volume as the destination and move it into place when
							finished, so the destination is never seen partially written
		totalByteCount	the final size of the file, which is what allows knowing when the file is complete
		completionProc	called at most once, when the file is complete and in place
		idleTimeout		if the file is not complete and no write happens for this long, the file is abandoned - any
							temp file is removed and abandonProc is called.  Best paired with a totalByteCount, as
							without one there is no way to tell "done" from "stalled", so a slow producer - or one
							that simply has not called complete() yet - can have its file thrown away

	Call complete() when done, or abandon() to give up - a file with a totalByteCount completes itself.

	Neither proc is called on any particular thread - completionProc arrives on whichever thread finished the file
		and abandonProc can arrive on the idle timer's own queue, so treat both as coming from anywhere.

	Coverage of the file is tracked as written, so writes may arrive out of order and may repeat (a retry of the
		same bytes changes nothing) - the file is complete when every byte from 0 to totalByteCount is covered.

	Positioned writes - write(_:at:) - do not disturb the file offset and are safe to perform concurrently from
		multiple threads.  Sequential writes - write(_:) - advance the file offset and are serialized, so they are
		safe but gain nothing from being spread across threads.

	A write that fails partway leaves bytes on disk that are not accounted for.  A positioned write simply sorts
		itself out when it is retried, but a sequential one does not as the file offset has moved on, so abandon
		rather than carry on writing after one fails.
*/
public final class FileWriter : @unchecked Sendable {

	// MARK: Mode
	public enum Mode {
		case overwrite	// Create, replacing the contents of any existing file
		case append		// Add to the end of the file, creating it if it's not there
		case update		// Open existing (or create), no truncate - for positioned writes
	}

	// MARK: State
	public enum State {
		case writing	// Still accepting writes
		case complete	// Fully written and in place
		case abandoned	// Given up on - a staged file leaves nothing behind, otherwise whatever was written stays
	}

	// MARK: Error
	public struct Error : Swift.Error {

		// MARK: Kind
		public enum Kind {
			case invalidMode
			case couldNotOpen
			case notWriting
			case outOfBounds
			case writeFailed
			case incomplete
			case couldNotMoveIntoPlace
		}

		// MARK: Properties
		public	let	kind :Kind
		public	let	file :File
		public	let	errno :Int32?

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(kind :Kind, file :File, errno :Int32) {
			// Store
			self.kind = kind
			self.file = file
			self.errno = errno
		}

		//--------------------------------------------------------------------------------------------------------------
		init(kind :Kind, file :File) {
			// Store
			self.kind = kind
			self.file = file
			self.errno = nil
		}
	}

	// MARK: Types
	public typealias CompletionProc = @Sendable (_ file :File) -> Void
	public typealias AbandonProc = @Sendable (_ file :File) -> Void

	// MARK: Properties
	public			let	file :File

	public			var	state :State { self.lock.perform({ self.stateInternal }) }
	public			var	writtenByteCount :Int64
							{ self.lock.perform({ self.coverage.reduce(0, { $0 + ($1.upperBound - $1.lowerBound) }) }) }

			private	let	totalByteCount :Int64?
			private	let	stagedFile :File?
			private	let	idleTimeout :TimeInterval?
			private	let	completionProc :CompletionProc?
			private	let	abandonProc :AbandonProc?
			private	let	lock = Lock()

			private	let	fd :Int32
			private	var	nextOffset = Int64(0)
			private	var	coverage = [Range<Int64>]()
			private	var	stateInternal = State.writing
			private	var	idleTimer :DispatchSourceTimer?

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static public func setContents(of file :File, to data :Data, creationDate :Date? = nil,
			modificationDate :Date? = nil, options :Data.WritingOptions = []) throws {
		// Write data
		try data.write(to: file.url, options: options)
		if creationDate != nil {
			// Set
			try file.set(creationDate: creationDate!)
		}
		if modificationDate != nil {
			// Set
			try file.set(modificationDate: modificationDate!)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	static public func setContents(of file :File, to string :String, creationDate :Date? = nil,
			modificationDate :Date? = nil, options :Data.WritingOptions = []) throws {
		// Set content
		try setContents(of: file, to: string.data(using: .utf8)!, creationDate: creationDate,
				modificationDate: modificationDate, options: options)
	}

	//------------------------------------------------------------------------------------------------------------------
	static public func setJSONContents<T>(of file :File, to t :T, creationDate :Date? = nil,
			modificationDate :Date? = nil, options :Data.WritingOptions = []) throws {
		// Set content
		try setContents(of: file, to: try JSONSerialization.data(withJSONObject: t, options: []),
				creationDate: creationDate, modificationDate: modificationDate, options: options)
	}

	//------------------------------------------------------------------------------------------------------------------
	// Write a file within the given proc, which relieves the caller of managing the FileWriter's lifetime - the file is
	//	completed when the proc returns and abandoned if the proc throws.
	static public func write(to file :File, mode :Mode = .overwrite, staged :Bool = false,
			proc :(_ fileWriter :FileWriter) throws -> Void) throws {
		// Setup
		let	fileWriter = try FileWriter(for: file, mode: mode, staged: staged)

		// Call proc
		do {
			// Write
			try proc(fileWriter)
		} catch {
			// Abandon and rethrow
			fileWriter.abandon()

			throw error
		}

		// Complete
		try fileWriter.complete()
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(for file :File, mode :Mode = .overwrite, staged :Bool = false, totalByteCount :Int64? = nil,
			idleTimeout :TimeInterval? = nil, completionProc :CompletionProc? = nil, abandonProc :AbandonProc? = nil)
			throws {
		// Preflight - .append starts partway into an existing file, which neither staging (which starts from
		//	nothing and then replaces the destination) nor coverage (which counts from 0) can make sense of
		guard (mode != .append) || (!staged && (totalByteCount == nil)) else
			{ throw Error(kind: .invalidMode, file: file) }

		// Ensure the destination folder is there - the caller should not have to arrange this, and it must exist before
		//	composing a temp file on its volume
		try FileManager.default.create(file.folder)

		// Setup the file actually being written - a temp file on the destination's volume when staged so that a move
		//	into place is a rename and not a copy
		let	stagedFile = staged ? FileWriter.temporaryFile(for: file) : nil
		let	writeFile = stagedFile ?? file

		// Setup oflag - a staged file is always brand new, so it is always created
		let	oflag :Int32
		switch staged ? Mode.overwrite : mode {
			case .overwrite:	oflag = O_RDWR | O_CREAT | O_TRUNC
			case .append:		oflag = O_RDWR | O_APPEND | O_EXLOCK | O_CREAT
			case .update:		oflag = O_WRONLY | O_CREAT
		}

		// Open
		let	fd = Darwin.open(writeFile.path, oflag, S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH)
		guard fd != -1 else { throw Error(kind: .couldNotOpen, file: file, errno: errno) }

		// Store
		self.file = file
		self.totalByteCount = totalByteCount
		self.stagedFile = stagedFile
		self.idleTimeout = idleTimeout
		self.completionProc = completionProc
		self.abandonProc = abandonProc
		self.fd = fd

		// Start watching for idleness
		if idleTimeout != nil {
			// Setup timer
			let	idleTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.global())
			idleTimer.setEventHandler() { [weak self] in self?.abandon() }
			idleTimer.schedule(deadline: .now() + idleTimeout!, repeating: .never)
			idleTimer.resume()

			self.idleTimer = idleTimer
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
		// Stop watching for idleness
		self.idleTimer?.cancel()

		// Close - the file descriptor is held until now so that a write which is already underway can never land on a
		//	descriptor number that has since been reused for something else entirely
		Darwin.close(self.fd)

		// Check if need to cleanup the staged file
		if (self.stateInternal == .writing), self.stagedFile != nil
			// Cleanup staged file
			{ try? FileManager.default.remove(self.stagedFile!) }
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func write(_ data :Data) throws {
		// Sequential writes advance the file offset, so the write itself must be serialized
		let	isComplete =
					try self.lock.perform() { () -> Bool in
						// Preflight
						guard self.stateInternal == .writing else
							{ throw Error(kind: .notWriting, file: self.file) }
						try checkInBounds(offset: self.nextOffset, count: data.count)
						guard !data.isEmpty else { return false }

						// Write at the current offset
						let	offset = self.nextOffset
						try performWrite(data, at: offset, sequential: true)
						self.nextOffset = offset + Int64(data.count)

						return noteWritten(offset ..< self.nextOffset)
					}

		// Check if complete
		if isComplete {
			// Try to complete
			try complete()
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func write(_ string :String) throws { try write(string.data(using: .utf8)!) }

	//------------------------------------------------------------------------------------------------------------------
	// Write at an explicit offset.  The write does not disturb the file offset, so it does not need to be serialized
	//	with other positioned writes.  Writing directly to the destination requires .update mode - a staged file is
	//	always opened ready for this.  .append mode cannot be used as the OS forces every write to the end of the file
	//	regardless of the offset given.
	public func write(_ data :Data, at offset :Int64) throws {
		// Preflight
		guard self.state == .writing else { throw Error(kind: .notWriting, file: self.file) }
		try checkInBounds(offset: offset, count: data.count)
		guard !data.isEmpty else { return }

		// Write these bytes - positioned writes are atomic at the OS level, so no need to hold the lock
		try performWrite(data, at: offset, sequential: false)

		// Note coverage
		let	isComplete = self.lock.perform({ noteWritten(offset ..< offset + Int64(data.count)) })

		// Check if complete
		if isComplete {
			// Try to complete
			try complete()
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	// Declare the file done - move it into place if staged and call the completionProc.  Happens automatically when a
	//	totalByteCount was given and the file becomes fully written.  Does nothing if already complete, and throws if
	//	the file was abandoned or is not fully written.
	public func complete() throws {
		// Perform under lock
		guard try self.lock.perform({ () -> Bool in
			// Check state
			guard self.stateInternal != .abandoned else { throw Error(kind: .notWriting, file: self.file) }
			guard self.stateInternal == .writing else { return false }
			guard isFullyCovered else { throw Error(kind: .incomplete, file: self.file) }

			// Claim and stop watching for idleness
			self.stateInternal = .complete
			self.idleTimer?.cancel()
			self.idleTimer = nil

			return true
		}) else { return }

		// Catch errors
		do {
			// Make the file exactly the size it was declared to be - writing .update over a larger existing file would
			//	otherwise leave whatever was beyond the end still hanging off it
			if self.totalByteCount != nil {
				// Truncate
				guard Darwin.ftruncate(self.fd, off_t(self.totalByteCount!)) == 0 else
					{ throw Error(kind: .writeFailed, file: self.file, errno: errno) }
			}

			// Move into place if staged - rename replaces the destination in a single step, so the destination is never
			//	momentarily missing
			if self.stagedFile != nil {
				// Move
				guard Darwin.rename(self.stagedFile!.path, self.file.path) == 0 else
					{ throw Error(kind: .couldNotMoveIntoPlace, file: self.file, errno: errno) }
			}
		} catch {
			// Don't leave the temp file lying around, and don't claim to be complete when nothing was published - the
			//	caller hears about it through the error rather than the abandonProc
			if self.stagedFile != nil { try? FileManager.default.remove(self.stagedFile!) }
			self.lock.perform({ self.stateInternal = .abandoned })

			throw error
		}

		// Call completion proc - outside the lock as it is the caller's work and can take as long as it likes
		self.completionProc?(self.file)
	}

	//------------------------------------------------------------------------------------------------------------------
	// Give up on the file and call the abandonProc.  Does nothing if no longer writing.  A staged file leaves nothing
	//	behind; without staging, whatever was already written stays at the destination, which is precisely what staging
	//	is for.
	public func abandon() {
		// Claim under the lock - only one caller ever gets to do this
		guard self.lock.perform({ () -> Bool in
			// Check state
			guard self.stateInternal == .writing else { return false }

			// Claim and stop watching for idleness
			self.stateInternal = .abandoned
			self.idleTimer?.cancel()
			self.idleTimer = nil

			return true
		}) else { return }

		// Remove the temp file so a partially written file is not left lying around
		if self.stagedFile != nil { try? FileManager.default.remove(self.stagedFile!) }

		// Call abandon proc
		self.abandonProc?(self.file)
	}

	// MARK: Private methods
	//------------------------------------------------------------------------------------------------------------------
	// Put the bytes on disk, dealing with the OS taking them a piece at a time.  Lock must be held when sequential.
	private func performWrite(_ data :Data, at offset :Int64, sequential :Bool) throws {
		// Write
		try data.withUnsafeBytes() { (pointer :UnsafeRawBufferPointer) in
			// Setup
			guard var address = pointer.baseAddress else { return }
			var	remaining = pointer.count
			var	offsetUse = offset

			// Write until there is nothing left
			while remaining > 0 {
				// Write what we can
				let	count =
							sequential ?
									Darwin.write(self.fd, address, remaining) :
									Darwin.pwrite(self.fd, address, remaining, off_t(offsetUse))
				guard count > 0 else {
					// Interrupted writes are simply resumed
					if (count == -1) && (errno == EINTR) { continue }

					throw Error(kind: .writeFailed, file: self.file, errno: errno)
				}

				// Advance
				address = address.advanced(by: count)
				remaining -= count
				offsetUse += Int64(count)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	// Note that the given range of the file has been written, keep the idle watch alive, and return whether the file is
	//	now fully written.  Must be called with the lock held.  Counting bytes is not enough - writes can arrive out of
	//	order, so the only way to know the file is whole is to see that the covered ranges join up into one that spans
	//	it.  Completing is left to complete(), which is what makes it happen only once.
	private func noteWritten(_ range :Range<Int64>) -> Bool {
		// Absorb any ranges that overlap or touch this one, leaving the rest alone
		var	lowerBound = range.lowerBound
		var	upperBound = range.upperBound
		var	coverage = [Range<Int64>]()
		self.coverage.forEach() {
			// Check if disjoint
			if ($0.upperBound < lowerBound) || ($0.lowerBound > upperBound) {
				// Untouched
				coverage.append($0)
			} else {
				// Joins with this range
				lowerBound = min(lowerBound, $0.lowerBound)
				upperBound = max(upperBound, $0.upperBound)
			}
		}
		coverage.append(lowerBound ..< upperBound)
		self.coverage = coverage.sorted(by: { $0.lowerBound < $1.lowerBound })

		// Check coverage
		let	isComplete = (self.totalByteCount != nil) && isFullyCovered

		// There is progress, so the file is not idle
		if self.idleTimeout != nil {
			// Check if there is any more to come
			if isComplete {
				// Fully written, so stop watching right now - leaving the countdown armed would let it fire in the
				//	moment between here and complete() and throw away a file that is entirely there
				self.idleTimer?.cancel()
				self.idleTimer = nil
			} else {
				// Restart the idle countdown
				self.idleTimer?.schedule(deadline: .now() + self.idleTimeout!, repeating: .never)
			}
		}

		return isComplete
	}

	//------------------------------------------------------------------------------------------------------------------
	// Check that the given write lands within the file - a declared size is a contract, so going past it is a bug
	private func checkInBounds(offset :Int64, count :Int) throws {
		// Check bounds
		guard (offset >= 0) && ((self.totalByteCount == nil) || ((offset + Int64(count)) <= self.totalByteCount!)) else
			{ throw Error(kind: .outOfBounds, file: self.file) }
	}

	//------------------------------------------------------------------------------------------------------------------
	// Check if every byte of the file has been written.  Must be called with the lock held.  A file with no declared
	//	size is however much has been written, so it is always considered covered.
	private var isFullyCovered :Bool {
		return (self.totalByteCount == nil) ||
				((self.coverage.count == 1) && (self.coverage[0].lowerBound == 0) &&
						(self.coverage[0].upperBound >= self.totalByteCount!))
	}

	//------------------------------------------------------------------------------------------------------------------
	// Compose a temp file alongside the destination, which guarantees it is on the same volume so that moving it into
	//	place is a rename and not a copy, and which needs no temp folder of its own to later clean up. Hidden so it is
	//	not mistaken for real content while it is being written.
	static private func temporaryFile(for file :File) -> File {
		return file.folder.file(withSubPath: ".\(UUID().uuidString).tmp")
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - FileWriter.Error extension
extension FileWriter.Error : CustomStringConvertible, LocalizedError {

	// MARK: Properties
	public 	var	description :String { self.localizedDescription }
	public	var	errorDescription :String? {
						switch self.kind {
							case .invalidMode:
								return ".append cannot be used with staging or a totalByteCount for file \(self.file.path)"
							case .couldNotOpen:
								return "Could not open file \(self.file.path)"
							case .notWriting:
								return "File \(self.file.path) is no longer being written"
							case .outOfBounds:
								return "Write lands outside of file \(self.file.path)"
							case .writeFailed:
								return "Write failed for file \(self.file.path)"
							case .incomplete:
								return "File \(self.file.path) is not fully written"
							case .couldNotMoveIntoPlace:
								return "Could not move file into place \(self.file.path)"
						}
					}
}
