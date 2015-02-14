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
		it("should parse the empty string") {
			expect(parse(graph, "")).to(equal([]))
		}

		it("should parse a line break") {
			expect(parse(graph, "\n")).to(equal([]))
		}

		it("should parse a series of line breaks") {
			expect(parse(graph, "\n\n\n")).to(equal([]))
		}

		it("should parse a single node with descendents") {
			expect(parse(descendents, "foobar")).to(equal(Node(value: "foobar")))
		}

		it("should parse a single node with adjacent") {
			expect(parse(adjacent, "foobar")).to(equal([ Node(value: "foobar") ]))
		}

		it("should parse a single node") {
			let expectedGraph = [ Node(value: "foobar") ]
			let parsedGraph = parse(graph, "foobar")
			expect(parsedGraph).to(equal(expectedGraph))
		}

		it("should parse a single node ending with a newline") {
			let expectedGraph = [ Node(value: "foobar") ]
			let parsedGraph = parse(graph, "foobar\n")
			expect(parsedGraph).to(equal(expectedGraph))
		}

		it("should parse a hierarchy") {
			let expectedGraph = [
				Node(value: "foo", children: [
					Node(value: "bar", children: [
						Node(value: "fuzz", children: [
							Node(value: "buzz")
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
					Node(value: "bar")
				]),

				Node(value: "fuzz", children: [
					Node(value: "buzz")
				])
			]

			let parsedGraph = parse(graph, "foo bar, fuzz buzz")
			expect(parsedGraph).to(equal(expectedGraph))
		}

		it("should parse grouped siblings") {
			let expectedGraph = [
				Node(value: "foo", children: [
					Node(value: "bar"),
					Node(value: "quux"),
				])
			]

			let parsedGraph = parse(graph, "foo (bar, quux)")
			expect(parsedGraph).to(equal(expectedGraph))
		}

		it("should parse grouped siblings with children") {
			let expectedGraph = [
				Node(value: "foo", children: [
					Node(value: "bar.o", children: [ Node(value: "1.2") ]),
					Node(value: "quux.o", children: [ Node(value: "2.1") ]),
				])
			]

			let parsedGraph = parse(graph, "foo ( bar.o 1.2, quux.o 2.1 )")
			expect(parsedGraph).to(equal(expectedGraph))
		}

		it("should parse comments") {
			let parsedGraph = parse(graph, "#foo")
			expect(parsedGraph).to(equal([]))
		}

		it("should parse Example 2") {
			let expectedGraph = [
				Node(value: "libraries", children: [
					Node(value: "foo.so", children: [
						Node(value: "version", children: [
							Node(value: "1.2")
						])
					]),

					Node(value: "bar.so", children: [
						Node(value: "version", children: [
							Node(value: "2.3")
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
