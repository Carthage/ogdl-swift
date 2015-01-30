//
//  ParserSpec.swift
//  OGDL
//
//  Created by Justin Spahr-Summers on 2015-01-07.
//  Copyright (c) 2015 Carthage. All rights reserved.
//

import Foundation
import Madness
import Nimble
import OGDL
import Quick

class ParserSpec: QuickSpec {
	override func spec() {
		it("should parse a single node") {
			let expectedGraph = [ Node(value: "foobar", children: []) ]
			let parsedGraph = parse(graph, "foobar")
			expect(parsedGraph).to(equal(expectedGraph))
		}

		it("should parse a hierarchy") {
			let expectedGraph = [
				Node(value: "foo", children: [
					Node(value: "bar", children: [
						Node(value: "fuzz", children: [
							Node(value: "buzz", children: [])
						])
					])
				])
			]

			let parsedGraph = parse(graph, "foo bar fuzz buzz")
			expect(parsedGraph).to(equal(expectedGraph))
		}

		it("should parse siblings") {
			let expectedGraph = [
				Node(value: "foo", children: [
					Node(value: "bar", children: [])
				]),

				Node(value: "fuzz", children: [
					Node(value: "buzz", children: [])
				])
			]

			let parsedGraph = parse(graph, "foo bar, fuzz buzz")
			expect(parsedGraph).to(equal(expectedGraph))
		}

		it("should parse grouped siblings") {
			let expectedGraph = [
				Node(value: "foo", children: [
					Node(value: "bar", children: []),
					Node(value: "quux", children: []),
				])
			]

			let parsedGraph = parse(graph, "foo (bar, quux)")
			expect(parsedGraph).to(equal(expectedGraph))
		}

		it("should parse Example 2") {
			let expectedGraph = [
				Node(value: "libraries", children: [
					Node(value: "foo.so", children: [
						Node(value: "version", children: [
							Node(value: "1.2", children: [])
						])
					]),

					Node(value: "bar.so", children: [
						Node(value: "version", children: [
							Node(value: "2.3", children: [])
						])
					]),
				])
			]

			for i in 1...5 {
				let URL = NSBundle(forClass: self.dynamicType).URLForResource("Example2-\(i)", withExtension: "ogdl", subdirectory: "Samples")!

				let sample = NSString(contentsOfURL: URL, encoding: NSUTF8StringEncoding, error: nil)
				expect(sample).notTo(beNil())

				let parsedGraph = parse(graph, sample ?? "")
				if let parsedGraph = parsedGraph {
					println("graph \(i):\n\(parsedGraph)\n")
				}

				expect(parsedGraph).to(equal(expectedGraph))
			}
		}
	}
}
