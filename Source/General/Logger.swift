//
//  Logger.swift
//  Swift Toolbox
//
//  Created by Stevo on 2/6/25.
//

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

	// MARK: Properties
	private	let	fileWriter :FileWriter

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init (level :Level = .warning, file :File) {
		// Setup
		self.fileWriter = FileWriter(for: file)

		// Do super
		super.init(level: level)

		// Setup proc
		let	lock = Lock()
		self.proc = { level, string in
			// One at a time please
			lock.perform() {
				// Catch errors
				do {
					// Add message to file
					try self.fileWriter.open(mode: FileManager.default.exists(file) ? .append : .overwrite)
					try self.fileWriter.write("\(string)\n")
					self.fileWriter.close()
				} catch {
					// Error
					NSLog("FileLogger encountered error when writing to file - \(error)")
				}
			}
		}

		// Remove any existing file
		try? FileManager.default.remove(file)
	}
}
