//
//  Graph.swift
//  OGDL
//
//  Created by Justin Spahr-Summers on 2015-01-07.
//  Copyright (c) 2015 Carthage. All rights reserved.
//

import Foundation

/// Represents a node in an OGDL graph. Nodes are not required to be unique.
public class Node: Equatable {
	/// The value given for this node.
	public let value: String

	/// Any children of this node.
	public let children: [Node]

	public init(value: String, children: [Node] = []) {
		self.value = value
		self.children = children
	}

	/// Creates a new node by appending the given children to that of the receiver.
	public func nodeByAppendingChildren(children: [Node]) -> Node {
		return Node(value: value, children: self.children + children)
	}
}

public func == (lhs: Node, rhs: Node) -> Bool {
	return lhs.value == rhs.value && lhs.children == rhs.children
}

extension Node: Hashable {
	public var hashValue: Int {
		return value.hashValue ^ children.count.hashValue
	}
}

extension Node: Printable {
	public var description: String {
		var string = ""
		if value.rangeOfCharacterFromSet(NSCharacterSet.alphanumericCharacterSet().invertedSet) == nil {
			string = value
		} else {
			string = "\"\(value)\""
		}

		if !children.isEmpty {
			let childDescriptions = map(children) { $0.description }
			string += " (" + join(", ", childDescriptions) + ")"
		}

		return string
	}
}
