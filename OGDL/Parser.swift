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
