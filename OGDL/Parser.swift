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
