//
//  AniListRelationGraph.swift
//  TVShowTracker
//
//  Created by Alan Flament on 11/08/2026.
//

struct AniListRelationGraph {
    let nodes: [Int: AniListAnime]
    let adjacency: [Int: Set<Int>]
    let predecessors: [Int: Set<Int>]
}
