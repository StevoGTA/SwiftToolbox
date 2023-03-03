//
//  FileWriter.swift
//  Swift Toolbox
//
//  Created by Stevo on 11/3/20.
//  Copyright © 2020 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: FileWriterError
struct FileWriterError : Error {

	// Error Type
	enum ErrorType {
		case couldNotOpen
		case notOpen
		case writeFailed
	}

	// Properties
	let type: ErrorType
	let	file :File
	let	errno :Int32?
}

extension FileWriterError : CustomStringConvertible, LocalizedError {

	// MARK: Properties
	public 	var	description :String { self.localizedDescription }
	public	var	errorDescription :String? {
						switch self.type {
							case .couldNotOpen: return "Could not open file \(self.file.path)"
							case .notOpen: return "File \(self.file.path) is not open"
							case .writeFailed: return "Write failed for file \(self.file.path)"
						}
					}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: - FileWriter
public class FileWriter {

	// MARK: Properties
	private	let	file :File

	private	var	fd :Int32 = -1

	// Class methods
	//------------------------------------------------------------------------------------------------------------------
	static public func setContents(of file :File, to data :Data, creationDate :Date? = nil,
			modificationDate :Date? = nil) throws {
		// Write data
		try data.write(to: file.url)
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
	static public func setContents(of file :File, to string :String) throws {
		// Set content
		try setContents(of: file, to: string.data(using: .utf8)!)
	}

	//------------------------------------------------------------------------------------------------------------------
	static public func setJSONContents<T>(of file :File, to t :T) throws {
		// Set content
		try setContents(of: file, to: try JSONSerialization.data(withJSONObject: t, options: []))
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
	public func open() throws {
		// Preflight
		guard self.fd == -1 else { return }

		// Open
		self.fd = Darwin.open(self.file.path, O_WRONLY | O_CREAT, S_IRUSR + S_IRGRP + S_IROTH)
		guard self.fd != -1 else { throw FileWriterError(type: .couldNotOpen, file: self.file, errno: errno) }
	}

	//------------------------------------------------------------------------------------------------------------------
	public func write(_ data :Data) throws {
		// Preflight
		guard self.fd != -1 else { throw FileWriterError(type: .notOpen, file: self.file, errno: nil) }

		// Write
		try data.withUnsafeBytes() {
			// Write
			if Darwin.write(self.fd, $0.baseAddress, $0.count) != $0.count {
				// Error
				throw FileWriterError(type: .writeFailed, file: self.file, errno: errno)
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
