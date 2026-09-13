//
//  Data+AniListSearchFixture.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation
import Testing
@testable import TVShowTracker

extension Data {
    static var dandadanAniListSearchResponse: Data {
        Data(#"""
        {
          "data": {
            "Page": {
              "media": [
                {
                  "id": 171018,
                  "title": { "userPreferred": "Dandadan" },
                  "coverImage": {},
                  "format": "TV",
                  "status": "FINISHED",
                  "episodes": 12,
                  "startDate": { "year": 2024, "month": 10, "day": 4 },
                  "relations": {
                    "edges": [{
                      "relationType": "SEQUEL",
                      "node": {
                        "id": 185660,
                        "title": { "userPreferred": "Dandadan 2nd Season" },
                        "coverImage": {},
                        "format": "TV",
                        "status": "FINISHED",
                        "episodes": 12,
                        "startDate": { "year": 2025, "month": 7, "day": 4 }
                      }
                    }]
                  }
                },
                {
                  "id": 185660,
                  "title": { "userPreferred": "Dandadan 2nd Season" },
                  "coverImage": {},
                  "format": "TV",
                  "status": "FINISHED",
                  "episodes": 12,
                  "startDate": { "year": 2025, "month": 7, "day": 4 },
                  "relations": {
                    "edges": [{
                      "relationType": "SEQUEL",
                      "node": {
                        "id": 198966,
                        "title": { "userPreferred": "Dandadan 3rd Season" },
                        "coverImage": {},
                        "format": "TV",
                        "status": "NOT_YET_RELEASED",
                        "episodes": null,
                        "startDate": {}
                      }
                    }]
                  }
                },
                {
                  "id": 198966,
                  "title": { "userPreferred": "Dandadan 3rd Season" },
                  "coverImage": {},
                  "format": "TV",
                  "status": "NOT_YET_RELEASED",
                  "episodes": null,
                  "startDate": {}
                }
              ]
            }
          }
        }
        """#.utf8)
    }
}
