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

private let char_control = NSCharacterSet(range: NSRange(location: 0, length: 32))
private let char_text = char_control.invertedSet
private let char_word = char_text - ",()"
private let char_space = NSCharacterSet.whitespaceCharacterSet()
private let char_break = NSCharacterSet.newlineCharacterSet()
private let char_end = char_control - NSCharacterSet.whitespaceAndNewlineCharacterSet()

private let wordStart = %(char_word - "#'\"")
private let wordChar = %(char_word - "'\"")
private let word = wordStart+ ++ wordChar*
private let string = (%char_text | %char_space)+
private let br = %char_break
private let comment = %"#" ++ ignore(string) ++ br
private let quoted = (%"'" ++ string ++ %"'") | (%"\"" ++ string ++ %"\"")
private let space = (%char_space)+
