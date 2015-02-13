//
//  Parser.swift
//  OGDL
//
//  Created by Justin Spahr-Summers on 2015-01-07.
//  Copyright (c) 2015 Carthage. All rights reserved.
//

import Foundation
import Madness

/// Returns a parser which parses one character from the given set.
internal prefix func % (characterSet: NSCharacterSet) -> Parser<String>.Function {
	return { string in
		let scalars = string.unicodeScalars

		if let scalar = first(scalars) {
			if characterSet.longCharacterIsMember(scalar.value) {
				return (String(scalar), String(dropFirst(scalars)))
			}
		}

		return nil
	}
}

/// Removes the characters in the given string from the character set.
internal func - (characterSet: NSCharacterSet, characters: String) -> NSCharacterSet {
	let mutableSet = characterSet.mutableCopy() as NSMutableCharacterSet
	mutableSet.removeCharactersInString(characters)
	return mutableSet
}

/// Removes characters in the latter set from the former.
internal func - (characterSet: NSCharacterSet, subtrahend: NSCharacterSet) -> NSCharacterSet {
	let mutableSet = characterSet.mutableCopy() as NSMutableCharacterSet
	mutableSet.formIntersectionWithCharacterSet(subtrahend.invertedSet)
	return mutableSet
}

/// Optional matching operator.
postfix operator |? {}

/// Matches zero or one occurrence of the given parser.
internal postfix func |? <T>(parser: Parser<T>.Function) -> Parser<T?>.Function {
	return (parser * (0..<2)) --> first
}

private let char_control = NSCharacterSet.controlCharacterSet()
private let char_text = char_control.invertedSet - NSCharacterSet.whitespaceAndNewlineCharacterSet()
private let char_word = char_text - ",()"
private let char_space = NSCharacterSet.whitespaceCharacterSet()
private let char_break = NSCharacterSet.newlineCharacterSet()
private let char_end = char_control - NSCharacterSet.whitespaceAndNewlineCharacterSet()

private let wordStart: Parser<String>.Function = %(char_word - "#'\"")
private let wordChars: Parser<String>.Function = (%(char_word - "'\""))* --> { strings in join("", strings) }
private let word: Parser<String>.Function = wordStart ++ wordChars --> (+)
private let string: Parser<String>.Function = (%char_text | %char_space)+ --> { strings in join("", strings) }
private let br: Parser<()>.Function = ignore(%char_break)
private let comment: Parser<()>.Function = ignore(%"#" ++ string ++ br)
private let quoted: Parser<String>.Function = (ignore(%"'") ++ string ++ ignore(%"'")) | (ignore(%"\"") ++ string ++ ignore(%"\""))
private let requiredSpace: Parser<()>.Function = ignore((comment | %char_space)+)
private let optionalSpace: Parser<()>.Function = ignore((comment | %char_space)*)
private let separator: Parser<()>.Function = ignore(optionalSpace ++ %"," ++ optionalSpace)

private let value: Parser<String>.Function = word | quoted

private func buildHierarchy(values: [String]) -> Node? {
	return values.reverse().reduce(nil) { (child: Node?, value: String) -> Node in
		if let child = child {
			return Node(value: value, children: [ child ])
		} else {
			return Node(value: value, children: [])
		}
	}
}

private let _children: Parser<[Node]>.Function = group | (element --> { elem in [ elem ] })
private let children = { _children($0) }

private let _element: Parser<Node>.Function = value ++ (optionalSpace ++ children)|? --> { value, children in Node(value: value, children: children ?? []) }
private let element = { _element($0) }

private let _siblings: Parser<[Node]>.Function = element ++ (separator ++ element)* --> { head, tail in [ head ] + tail }
private let siblings = { _siblings($0) }

private let _group: Parser<[Node]>.Function = ignore(%"(") ++ optionalSpace ++ siblings ++ optionalSpace ++ ignore(%")")
private let group = { _group($0) }

private let line: Parser<[Node]>.Function = (ignore(comment | br) --> { _ in [] }) | optionalSpace ++ siblings ++ optionalSpace

public let graph: Parser<[Node]>.Function = line+ --> { reduce($0, [], +) }
