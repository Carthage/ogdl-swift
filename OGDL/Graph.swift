//
//  Graph.swift
//  OGDL
//
//  Created by Justin Spahr-Summers on 2015-01-07.
//  Copyright (c) 2015 Carthage. All rights reserved.
//

import Foundation

public class Node {
	public let value: String
	public let children: [Node]

	public init(value: String, children: [Node]) {
		self.value = value
		self.children = children
	}
}
