//
//  SerialQueue.swift
//  Swift Toolbox
//
//  Created by Stevo on 3/8/22.
//  Copyright © 2022 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: SerialQueue
public class SerialQueue<T> : ProcConcurrentQueue<T> {

	// MARK: Lifecycle methods
	//------------------------------------------------------------------------------------------------------------------
	public init(procDispatchQueue :DispatchQueue = .global(), proc :@escaping Proc) {
		// Do super
		super.init(maxConcurrentItems: .specified(1), procDispatchQueue: procDispatchQueue, proc: proc)
	}
}
