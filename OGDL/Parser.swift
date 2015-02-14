//
//  Parser.swift
//  OGDL
//
//  Created by Justin Spahr-Summers on 2015-01-07.
//  Copyright (c) 2015 Carthage. All rights reserved.
//

import Foundation
import Madness
import Prelude

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

/// A function taking an Int and returning a parser which parses at least that many
/// indentation characters.
func indentation(n: Int) -> Parser<Int>.Function {
	return (%char_space * (n..<Int.max)) --> { $0.count }
}

private func buildHierarchy(values: [String]) -> Node? {
	return values.reverse().reduce(nil) { (child: Node?, value: String) -> Node in
		if let child = child {
			return Node(value: value, children: [ child ])
		} else {
			return Node(value: value, children: [])
		}
	}
}


// MARK: Generic combinators

// fixme: move these into Madness.

/// Delays the evaluation of a parser so that it can be used in a recursive grammar without deadlocking Swift at runtime.
private func lazy<T>(parser: () -> Parser<T>.Function) -> Parser<T>.Function {
	return { parser()($0) }
}

/// Returns a parser which produces an array of parse trees produced by `parser` interleaved with ignored parses of `separator`.
///
/// This is convenient for e.g. comma-separated lists.
private func interleave<T, U>(separator: Parser<U>.Function, parser: Parser<T>.Function) -> Parser<[T]>.Function {
	return (parser ++ (ignore(separator) ++ parser)*) --> { [$0] + $1 }
}


// MARK: OGDL

private let children: Parser<[Node]>.Function = lazy { group | (element --> { elem in [ elem ] }) }

private let element = lazy { value ++ (optionalSpace ++ children)|? --> { value, children in Node(value: value, children: children ?? []) } }

// stubbed
private let block: Int -> Parser<()>.Function = { n in const(nil) }

/// Parses a single descendent element.
///
/// This is an element which may be an in-line descendent, and which may further have in-line descendents of its own.
private let descendent = (word | quoted) --> { Node(value: $0, children: []) }

/// Parses a sequence of hierarchically descending elements, e.g.:
///
///		x y z # => Node(x, [Node(y, Node(z))])
private let descendents: Parser<Node>.Function = fix { descendents in descendent >>- { node in
	(optionalSpace ++ descendents) --> { node.byAppendingChildren([ $1 ]) }
}}

/// Parses a sequence of adjacent sibling elements, e.g.:
///
///		x, y z, w (u, v) # => [ Node(x), Node(y, Node(z)), Node(w, [ Node(u), Node(v) ]) ]
private let adjacent: Parser<[Node]>.Function = lazy { interleave(separator, descendents >>- { node in (optionalSpace ++ group) --> { node.byAppendingChildren($1) } }) }

/// Parses a parenthesized sequence of sibling elements, e.g.:
/// 
///		(x, y z, w) # => [ Node(x), Node(y, Node(z)), Node(w) ]
private let group = lazy { ignore(%"(") ++ optionalSpace ++ adjacent ++ optionalSpace ++ ignore(%")") }

private let line: Int -> Parser<[Node]>.Function = { n in
	// fixme: block parsing: ignore(%char_space+ ++ block(n))|?) ++
	ignore(indentation(n)) ++ adjacent ++ (comment | br)
}

public let graph: Parser<[Node]>.Function = (comment | br)* ++ line(0)* --> { reduce($0, [], +) }

