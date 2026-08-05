//
//  Logger.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/6/25.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: Logger
public class Logger {

	// MARK: Level
	public enum Level {
		case info
		case warning
		case error
	}

	// MARK: Properties
	public		var	dateFormatter = DateFormatter(dateFormat: "yyyy-MM-dd' 'HH:mm:ss.SSS")

	fileprivate	var	proc :(_ level :Level, _ string :String) -> Void = { _,_ in }

	private		let	level :Level

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	init(level :Level = .warning) {
		// Store
		self.level = level
	}

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func info(_ string :String) {
		// Check level
		if self.level == .info {
			// Log
			self.proc(.info, "\(self.dateFormatter.string(for: Date())!) - \(string)")
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func warning(_ string :String) {
		// Check level
		if (self.level == .info) || (self.level == .warning) {
			// Call proc
			self.proc(.warning, "\(self.dateFormatter.string(for: Date())!) - \(string)")
		}
	}

	//------------------------------------------------------------------------------------------------------------------
	public func error(_ string :String) { self.proc(.error, "\(self.dateFormatter.string(for: Date())!) - \(string)") }
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: ConsoleLogger
public class ConsoleLogger : Logger {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public override init (level :Level = .warning) {
		// Do super
		super.init(level: level)

		// Setup proc
		self.proc = { NSLog($1) }
	}
}

//----------------------------------------------------------------------------------------------------------------------
// MARK: FileLogger
public class FileLogger : Logger {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init (level :Level = .warning, file :File) throws {
		// Setup - .overwrite creates the file, or empties one already there, so every run starts a fresh log
		let	fileWriter = try FileWriter(for: file)

		// Do super
		super.init(level: level)

		/*
			Setup proc - the file stays open for the life of the logger, so each line costs a single write.  Those
				bytes are handed to the OS as they are written, so anything already logged survives a crash of this
				application just as well as it did when the file was opened and closed around every line.
		*/
		let	lock = Lock()
		self.proc = { level, string in
			// One at a time please
			lock.perform() {
				// Catch errors
				do {
					// Add message to file
					try fileWriter.write("\(string)\n")
				} catch {
					// Error
					NSLog("FileLogger encountered error when writing to file - \(error)")
				}
			}
		}
	}
}
