//
//  TVTimeCSVDocument.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

import Foundation

struct TVTimeCSVDocument {
    let rows: [[String: String]]

    init(contentsOf url: URL) throws {
        let contents = try String(contentsOf: url, encoding: .utf8)
        let records = Self.records(from: contents)
        guard let header = records.first else {
            rows = []
            return
        }

        let headers = header.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        rows = records.dropFirst().compactMap { record in
            guard record.contains(where: { !$0.isEmpty }) else {
                return nil
            }

            return Dictionary(uniqueKeysWithValues: zip(headers, record))
        }
    }

    private static func records(from contents: String) -> [[String]] {
        var records = [[String]]()
        var record = [String]()
        var field = ""
        var isInsideQuotes = false
        let characters = Array(contents)
        var index = 0

        while index < characters.count {
            let character = characters[index]

            if character == "\"" {
                let nextIndex = index + 1
                if isInsideQuotes, nextIndex < characters.count, characters[nextIndex] == "\"" {
                    field.append(character)
                    index = nextIndex
                } else {
                    isInsideQuotes.toggle()
                }
            } else if character == ",", !isInsideQuotes {
                record.append(field)
                field = ""
            } else if character == "\n", !isInsideQuotes {
                record.append(field.trimmingCharacters(in: .newlines))
                records.append(record)
                record = []
                field = ""
            } else if character != "\r" {
                field.append(character)
            }

            index += 1
        }

        guard !record.isEmpty || !field.isEmpty else {
            return records
        }

        record.append(field)
        records.append(record)
        return records
    }
}
