//
//  FileReader.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/3/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Local procs
#if os(macOS)
	fileprivate func _open(_ path :UnsafePointer<CChar>, _ oflag :Int32) -> Int32 { Darwin.open(path, oflag) }
	fileprivate	func _read(_ fd: Int32, _ buf :UnsafeMutableRawPointer!, _ count :Int) -> Int { Darwin.read(fd, buf, count) }
	fileprivate func _close(_ fd :Int32) -> Int32 { Darwin.close(fd) }
#elseif os(Linux)
	fileprivate func _open(_ path :UnsafePointer<CChar>, _ oflag :Int32) -> Int32 { Glibc.open(path, oflag) }
	fileprivate	func _read(_ fd: Int32, _ buf :UnsafeMutableRawPointer!, _ count :Int) -> Int { Glibc.read(fd, buf, count) }
	fileprivate func _close(_ fd :Int32) -> Int32 { Glibc.close(fd) }
#endif

//----------------------------------------------------------------------------------------------------------------------
// MARK: - FileReader
public class FileReader {

	// MARK: Mode
	public enum Mode {
		case readOnlyCached
		case readOnlyNotCached
	}

	// MARK: Error
	struct Error : Swift.Error {

		// MARK: Kind
		enum Kind {
			case couldNotOpen
			case alreadyOpen
			case notOpen
			case endOfFile
			case readFailed
			case seekFailed
		}

		// MARK: Properties
		let kind: Kind
		let	file :File
		let	errno :Int32?
		let	bytesRead :Int64?

		// MARK: Lifecycle methods
		//--------------------------------------------------------------------------------------------------------------
		init(kind :Kind, file :File, errno :Int32) {
			// Store
			self.kind = kind
			self.file = file
			self.errno = errno
			self.bytesRead = nil
		}

		//--------------------------------------------------------------------------------------------------------------
		init(kind :Kind, file :File) {
			// Store
			self.kind = kind
			self.file = file
			self.errno = nil
			self.bytesRead = nil
		}
	}

	// MARK: Properties
	private	let	file :File

	private	var	fd :Int32 = -1

	// MARK: Class methods
	//------------------------------------------------------------------------------------------------------------------
	static public func contentsAsData(of file :File) throws -> Data {
		// Read as data
		try Data(contentsOf: file.url, options: [.mappedIfSafe])
	}

	//------------------------------------------------------------------------------------------------------------------
	static public func contentsAsString(of file :File, encoding :String.Encoding = .utf8) throws -> String? {
		// Read as string
		return String(data: try Data(contentsOf: file.url, options: [.mappedIfSafe]), encoding: encoding)
	}

	//------------------------------------------------------------------------------------------------------------------
	static public func contentsAsJSON<T>(of file :File) throws -> T? {
		// Return contents
		return try JSONSerialization.jsonObject(with: try Data(contentsOf: file.url), options: []) as? T
	}

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(_ file :File) {
		// Store
		self.file = file
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit {
		// Make sure we are closed
		close()
	}
	
	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func open(mode :Mode = .readOnlyNotCached) throws {
		// Preflight
		guard self.fd == -1 else { throw Error(kind: .alreadyOpen, file: self.file) }

		// Setup
		let	oflag :Int32
		switch mode {
			case .readOnlyCached:		oflag = O_RDONLY
			case .readOnlyNotCached:	oflag = O_RDONLY
		}

		// Open
		self.fd = _open(self.file.path, oflag)
		if self.fd == -1 {
			// Under some circumstances, the first open may fail while a second will succeed
			self.fd = _open(self.file.path, oflag)
		}
		guard self.fd != -1 else { throw Error(kind: .couldNotOpen, file: self.file, errno: errno) }

		// Check caching
		if mode == .readOnlyNotCached {
			// Turn off caching
#if os(macOS)
			_ = fcntl(self.fd, F_NOCACHE, 1)
#endif
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func read(byteCount :Int) throws -> Data {
		// Preflight
		guard self.fd != -1 else { throw Error(kind: .notOpen, file: self.file) }

		// Read
		let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: byteCount)
		defer { ptr.deallocate() }
		switch _read(self.fd, ptr, byteCount) {
			case byteCount:	return Data(bytes: ptr, count: byteCount)
			case -1:		throw Error(kind: .readFailed, file: self.file, errno: errno)
			default:		throw Error(kind: .endOfFile, file: self.file)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func read<T>(_: T.Type) throws -> T {
		// Preflight
		guard self.fd != -1 else { throw Error(kind: .notOpen, file: self.file) }

		// Read
		let	byteCount = MemoryLayout<T>.size
		let ptr = UnsafeMutablePointer<T>.allocate(capacity: 1)
		defer { ptr.deallocate() }
		switch _read(self.fd, ptr, byteCount) {
			case byteCount:	return ptr.pointee
			case -1:		throw Error(kind: .readFailed, file: self.file, errno: errno)
			default:		throw Error(kind: .endOfFile, file: self.file)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func seek(byteCount :off_t, whence :Int32 = SEEK_CUR) throws {
		// Preflight
		guard self.fd != -1 else { throw Error(kind: .notOpen, file: self.file) }

		// Seek
		guard lseek(self.fd, byteCount, whence) != -1 else {
			throw Error(kind: .seekFailed, file: self.file, errno: errno)
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	func tell() throws -> Int64 {
		// Preflight
		guard self.fd != -1 else { throw Error(kind: .notOpen, file: self.file) }

		return Int64(lseek(self.fd, 0, SEEK_CUR))
	}

	//------------------------------------------------------------------------------------------------------------------
	public func close() {
		// Preflight
		guard self.fd != -1 else { return }

		// Close
		_ = _close(self.fd)
	}
}

//----------------------------------------------------------------------------------------------------------------------
//MARK: - FileReader.Error extension
extension FileReader.Error : CustomStringConvertible, LocalizedError {

	// MARK: Properties
	public 	var	description :String { self.localizedDescription }
	public	var	errorDescription :String? {
						switch self.kind {
							case .couldNotOpen:	return "Could not open file \(self.file.path)"
							case .alreadyOpen:	return "File \(self.file.path) is already open"
							case .notOpen:		return "File \(self.file.path) is not open"
							case .endOfFile:	return "Found unexpected EOF for file \(self.file.path)"
							case .readFailed:
									return "Read failed for file \(self.file.path) with errno \(self.errno!)"
							case .seekFailed:
									return "Seek failed for file \(self.file.path) with errno \(self.errno!)"
						}
					}
}
