//
//  UndoManager.swift
//  Virtual Sheet Music
//
//  Created by Stevo on 6/26/20.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: UndoManager
class UndoManager<T> {

	// MARK: Types
	private struct State<T> {

		// MARK: Properties
		let	t :T
		let	name :String?
	}

	// MARK: Properties
			var	undoInfo :(canUndo :Bool, firstUndoName :String?) {
						// Try to retrieve last item
						if let state = self.undoItems.last {
							// Have info
							return (true, state.name)
						} else {
							// Don't have info
							return (false, nil)
						}
					}
			var	redoInfo :(canRedo :Bool, firstRedoName :String?) {
						// Try to retrieve last item
						if let state = self.redoItems.last {
							// Have info
							return (true, state.name)
						} else {
							// Don't have info
							return (false, nil)
						}
					}

	private	var	undoItems = [State<T>]()
	private	var	redoItems = [State<T>]()

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	func pushState(_ t :T, name :String? = nil) {
		// Add to undo items
		self.undoItems.append(State(t: t, name: name))

		// Clear redo items
		self.redoItems.removeAll()
	}

	//------------------------------------------------------------------------------------------------------------------
	func performUndo(currentState t :T) -> T {
		// Ensure we have an undo item
		guard !self.undoItems.isEmpty else { fatalError("UndoManager cannot perform Undo") }

		// Perform undo
		let	state = self.undoItems.removeLast()
		self.redoItems.append(State(t: t, name: state.name))

		return state.t
	}

	//------------------------------------------------------------------------------------------------------------------
	func performRedo(currentState t :T) -> T {
		// Ensure we have a redo item
		guard !self.redoItems.isEmpty else { fatalError("UndoManager cannot perform Redo") }

		// Perform redo
		let	state = self.redoItems.removeLast()
		self.undoItems.append(State(t: t, name: state.name))

		return state.t
	}
}
