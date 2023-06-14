//
//  XMLNode+Extensions.swift
//  Swift Toolbox
//
//  Created by Stevo on 6/6/23.
//  Copyright © 2023 Stevo Brock. All rights reserved.
//

import Foundation

//----------------------------------------------------------------------------------------------------------------------
// MARK: XMLNode extension
extension XMLNode {

	// MARK: Properties
	public	var	int64Value :Int64? { Int64(self.stringValue) }

	// MARK: Instance methods
	//------------------------------------------------------------------------------------------------------------------
	public func firstChildElement(named name :String) -> XMLElement? {
		// Return first child with matching name
		return self.children?.first(where: { $0.name == name }) as? XMLElement
	}

	//------------------------------------------------------------------------------------------------------------------
	public func children(named name :String) -> [XMLNode] { self.children?.filter({ $0.name == name }) ?? [] }
}
