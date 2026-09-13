//
//  AniListSearchMapping.swift
//  TVShowTracker
//
//  Created by Alan Flament on 13/09/2026.
//

import Foundation

enum AniListSearchMapping {
    static func groupedCandidates(from anime: [AniListAnime]) -> [MediaCandidate] {
        let graph = makeRelationGraph(from: anime)
        let nodes = graph.nodes
        let adjacency = graph.adjacency
        let predecessors = graph.predecessors
        var visited = Set<Int>()
        var candidates = [MediaCandidate]()

        for seed in anime where seed.isSeasonInstallment && !visited.contains(seed.id) {
            var pending = [seed.id]
            var component = Set<Int>()

            while let id = pending.popLast() {
                guard component.insert(id).inserted else {
                    continue
                }
                pending.append(contentsOf: adjacency[id, default: []])
            }

            visited.formUnion(component)
            let installments = component.compactMap { nodes[$0] }.sorted(by: isChronologicallyOrdered)
            guard let canonical = installments.first(where: {
                predecessors[$0.id, default: []].isDisjoint(with: component)
            }) ?? installments.first else {
                continue
            }

            candidates.append(MediaCandidate(canonical, installments: installments))
        }

        return candidates
    }

    static func makeRelationGraph(from anime: [AniListAnime]) -> AniListRelationGraph {
        var nodes = [Int: AniListAnime]()
        var adjacency = [Int: Set<Int>]()
        var predecessors = [Int: Set<Int>]()
        var processedRelations = Set<Int>()

        func ingest(_ item: AniListAnime) {
            guard item.isSeasonInstallment else {
                return
            }
            if nodes[item.id]?.relations == nil || item.relations != nil {
                nodes[item.id] = item
            }

            guard let edges = item.relations?.edges,
                  processedRelations.insert(item.id).inserted
            else {
                return
            }

            for edge in edges where edge.connectsSeasons {
                let related = edge.node
                adjacency[item.id, default: []].insert(related.id)
                adjacency[related.id, default: []].insert(item.id)

                if edge.relationType == "PREQUEL" {
                    predecessors[item.id, default: []].insert(related.id)
                } else {
                    predecessors[related.id, default: []].insert(item.id)
                }
                ingest(related)
            }
        }

        for item in anime {
            ingest(item)
        }
        return AniListRelationGraph(
            nodes: nodes,
            adjacency: adjacency,
            predecessors: predecessors
        )
    }

    nonisolated static func isChronologicallyOrdered(_ lhs: AniListAnime, _ rhs: AniListAnime) -> Bool {
        let lhsDate = (lhs.startDate.year ?? .max, lhs.startDate.month ?? .max, lhs.startDate.day ?? .max)
        let rhsDate = (rhs.startDate.year ?? .max, rhs.startDate.month ?? .max, rhs.startDate.day ?? .max)

        if lhsDate.0 != rhsDate.0 {
            return lhsDate.0 < rhsDate.0
        }
        if lhsDate.1 != rhsDate.1 {
            return lhsDate.1 < rhsDate.1
        }
        if lhsDate.2 != rhsDate.2 {
            return lhsDate.2 < rhsDate.2
        }
        return lhs.id < rhs.id
    }
}
