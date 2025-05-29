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
public class FileWriter {

	// MARK: Mode
	public enum Mode {
		case overwrite
		case append
	}

	// MARK: Error
	struct Error : Swift.Error {

		// MARK: Kind
		enum Kind {
			case couldNotOpen
			case alreadyOpen
			case notOpen
			case writeFailed
		}

		// MARK: Properties
		let kind: Kind
		let	file :File
		let	errno :Int32?

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

	// MARK: Properties
	private	let	file :File

	private	var	fd :Int32 = -1

	// Class methods
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

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(for file :File) {
		// Store
		self.file = file
	}

	//------------------------------------------------------------------------------------------------------------------
	deinit { close() }

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func open(mode :Mode = .overwrite) throws {
		// Preflight
		guard self.fd == -1 else { throw Error(kind: .alreadyOpen, file: self.file) }

		// Setup
		let	oflag :Int32
		switch mode {
			case .overwrite:	oflag = O_RDWR | O_CREAT | O_EXCL
			case .append:		oflag = O_RDWR | O_APPEND | O_EXLOCK
		}

		// Open
		self.fd = Darwin.open(self.file.path, oflag, S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH)
		guard self.fd != -1 else { throw Error(kind: .couldNotOpen, file: self.file, errno: errno) }
	}

	//------------------------------------------------------------------------------------------------------------------
	public func write(_ data :Data) throws {
		// Preflight
		guard self.fd != -1 else { throw Error(kind: .notOpen, file: self.file) }

		// Write
		try data.withUnsafeBytes() {
			// Write
			if Darwin.write(self.fd, $0.baseAddress, $0.count) != $0.count {
				// Error
				throw Error(kind: .writeFailed, file: self.file, errno: errno)
			}
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func write(_ string : String) throws { try write(string.data(using: .utf8)!) }

	//------------------------------------------------------------------------------------------------------------------
	public func close() {
		// Preflight
		guard self.fd != -1 else { return }

		// Close
		Darwin.close(self.fd)
	}
}

//----------------------------------------------------------------------------------------------------------------------
//MARK: - FileWriter.Error extension
extension FileWriter.Error : CustomStringConvertible, LocalizedError {

	// MARK: Properties
	public 	var	description :String { self.localizedDescription }
	public	var	errorDescription :String? {
						switch self.kind {
							case .couldNotOpen:	return "Could not open file \(self.file.path)"
							case .alreadyOpen:	return "File \(self.file.path) is already open"
							case .notOpen:		return "File \(self.file.path) is not open"
							case .writeFailed:	return "Write failed for file \(self.file.path)"
						}
					}
}
