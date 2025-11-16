// RQM - Requirements Management in Code
// Copyright (c) 2025
// SPDX-License-Identifier: MIT

use crate::{types::RequirementReference, Error, Requirement, RequirementConfig, Result};
use petgraph::graph::{DiGraph, NodeIndex};

use std::collections::{HashMap, HashSet};

const MAX_TRAVERSAL_DEPTH: usize = 100;

/// A graph representation of requirements with circular reference detection
pub struct RequirementGraph {
    graph: DiGraph<String, ()>,
    summary_to_node: HashMap<String, NodeIndex>,
    requirements: HashMap<String, Requirement>,
}

impl RequirementGraph {
    /// Build a graph from a RequirementConfig
    pub fn from_config(config: &RequirementConfig) -> Result<Self> {
        let mut graph = DiGraph::new();
        let mut summary_to_node = HashMap::new();
        let mut requirements = HashMap::new();

        // First pass: create all nodes
        for req in config.all_requirements() {
            let summary = req.summary.clone();
            let node = graph.add_node(summary.clone());
            summary_to_node.insert(summary.clone(), node);
            requirements.insert(summary, req.clone());
        }

        // Second pass: create edges
        for req in config.all_requirements() {
            let parent_node = summary_to_node[&req.summary];

            for child_ref in &req.requirements {
                match child_ref {
                    RequirementReference::Full(child) => {
                        if let Some(&child_node) = summary_to_node.get(&child.summary) {
                            graph.add_edge(parent_node, child_node, ());
                        }
                    }
                    RequirementReference::Reference(summary) => {
                        if let Some(&child_node) = summary_to_node.get(summary) {
                            graph.add_edge(parent_node, child_node, ());
                        } else {
                            return Err(Error::InvalidReference(format!(
                                "Requirement '{}' references non-existent '{}'",
                                req.summary, summary
                            )));
                        }
                    }
                }
            }
        }

        Ok(Self {
            graph,
            summary_to_node,
            requirements,
        })
    }

    /// Get a requirement by summary
    pub fn get(&self, summary: &str) -> Option<&Requirement> {
        self.requirements.get(summary)
    }

    /// Check if the graph contains cycles
    pub fn has_cycles(&self) -> bool {
        petgraph::algo::is_cyclic_directed(&self.graph)
    }

    /// Find all cycles in the graph
    pub fn find_cycles(&self) -> Vec<Vec<String>> {
        if !self.has_cycles() {
            return vec![];
        }

        let mut cycles = vec![];
        let mut visited = HashSet::new();

        for node in self.graph.node_indices() {
            if !visited.contains(&node) {
                self.find_cycles_from_node(node, &mut visited, &mut vec![], &mut cycles);
            }
        }

        cycles
    }

    fn find_cycles_from_node(
        &self,
        node: NodeIndex,
        visited: &mut HashSet<NodeIndex>,
        path: &mut Vec<NodeIndex>,
        cycles: &mut Vec<Vec<String>>,
    ) {
        if path.contains(&node) {
            // Found a cycle
            let cycle_start = path.iter().position(|&n| n == node).unwrap();
            let cycle: Vec<String> = path[cycle_start..]
                .iter()
                .map(|&n| self.graph[n].clone())
                .collect();
            cycles.push(cycle);
            return;
        }

        if visited.contains(&node) {
            return;
        }

        path.push(node);

        for neighbor in self.graph.neighbors(node) {
            self.find_cycles_from_node(neighbor, visited, path, cycles);
        }

        path.pop();
        visited.insert(node);
    }

    /// Traverse from a requirement with cycle detection
    pub fn traverse<F>(&self, start_summary: &str, mut visit: F) -> Result<()>
    where
        F: FnMut(&Requirement, usize) -> Result<()>,
    {
        let node = self
            .summary_to_node
            .get(start_summary)
            .ok_or_else(|| Error::RequirementNotFound(start_summary.to_string()))?;

        let mut visited = HashSet::new();
        self.traverse_recursive(*node, &mut visited, &mut visit, 0)
    }

    fn traverse_recursive<F>(
        &self,
        node: NodeIndex,
        visited: &mut HashSet<NodeIndex>,
        visit: &mut F,
        depth: usize,
    ) -> Result<()>
    where
        F: FnMut(&Requirement, usize) -> Result<()>,
    {
        if depth > MAX_TRAVERSAL_DEPTH {
            return Err(Error::GraphError(
                "Maximum traversal depth exceeded".to_string(),
            ));
        }

        if visited.contains(&node) {
            // Already visited, skip to prevent infinite loop
            return Ok(());
        }

        visited.insert(node);

        let summary = &self.graph[node];
        if let Some(req) = self.requirements.get(summary) {
            visit(req, depth)?;

            for neighbor in self.graph.neighbors(node) {
                self.traverse_recursive(neighbor, visited, visit, depth + 1)?;
            }
        }

        Ok(())
    }

    /// Get all requirements in topological order (if acyclic)
    pub fn topological_sort(&self) -> Result<Vec<&Requirement>> {
        if self.has_cycles() {
            return Err(Error::CircularReference(
                "Cannot perform topological sort on cyclic graph".to_string(),
            ));
        }

        let sorted = petgraph::algo::toposort(&self.graph, None)
            .map_err(|_| Error::GraphError("Topological sort failed".to_string()))?;

        Ok(sorted
            .iter()
            .filter_map(|&node| {
                let summary = &self.graph[node];
                self.requirements.get(summary)
            })
            .collect())
    }

    /// Get dependencies of a requirement
    pub fn dependencies(&self, summary: &str) -> Result<Vec<&Requirement>> {
        let node = self
            .summary_to_node
            .get(summary)
            .ok_or_else(|| Error::RequirementNotFound(summary.to_string()))?;

        Ok(self
            .graph
            .neighbors(*node)
            .filter_map(|n| {
                let sum = &self.graph[n];
                self.requirements.get(sum)
            })
            .collect())
    }

    /// Get dependents (reverse dependencies) of a requirement
    pub fn dependents(&self, summary: &str) -> Result<Vec<&Requirement>> {
        let node = self
            .summary_to_node
            .get(summary)
            .ok_or_else(|| Error::RequirementNotFound(summary.to_string()))?;

        Ok(self
            .graph
            .node_indices()
            .filter(|&n| self.graph.neighbors(n).any(|neighbor| neighbor == *node))
            .filter_map(|n| {
                let sum = &self.graph[n];
                self.requirements.get(sum)
            })
            .collect())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn create_test_config() -> RequirementConfig {
        let mut req1 = Requirement::new("Requirement 1");
        let mut req2 = Requirement::new("Requirement 2");
        let req3 = Requirement::new("Requirement 3");

        req2.requirements
            .push(RequirementReference::Full(Box::new(req3)));
        req1.requirements
            .push(RequirementReference::Full(Box::new(req2)));

        RequirementConfig {
            version: "1.0".to_string(),
            aliases: vec![],
            requirements: vec![req1],
        }
    }

    #[test]
    fn test_graph_creation() {
        let config = create_test_config();
        let graph = RequirementGraph::from_config(&config).unwrap();

        assert_eq!(graph.requirements.len(), 3);
        assert!(graph.get("Requirement 1").is_some());
    }

    #[test]
    fn test_no_cycles() {
        let config = create_test_config();
        let graph = RequirementGraph::from_config(&config).unwrap();

        assert!(!graph.has_cycles());
    }

    #[test]
    fn test_dependencies() {
        let config = create_test_config();
        let graph = RequirementGraph::from_config(&config).unwrap();

        let deps = graph.dependencies("Requirement 1").unwrap();
        assert_eq!(deps.len(), 1);
        assert_eq!(deps[0].summary, "Requirement 2");
    }

    #[test]
    fn test_traverse() {
        let config = create_test_config();
        let graph = RequirementGraph::from_config(&config).unwrap();

        let mut visited = vec![];
        graph
            .traverse("Requirement 1", |req, _depth| {
                visited.push(req.summary.clone());
                Ok(())
            })
            .unwrap();

        assert_eq!(visited.len(), 3);
        assert!(visited.contains(&"Requirement 1".to_string()));
    }

    #[test]
    fn test_circular_reference() {
        let req1 = Requirement::new("A");
        let req2 = Requirement::new("B");

        let mut req1_with_ref = req1.clone();
        req1_with_ref
            .requirements
            .push(RequirementReference::Reference("B".to_string()));

        let mut req2_with_ref = req2.clone();
        req2_with_ref
            .requirements
            .push(RequirementReference::Reference("A".to_string()));

        let config = RequirementConfig {
            version: "1.0".to_string(),
            aliases: vec![],
            requirements: vec![req1_with_ref, req2_with_ref],
        };

        let graph = RequirementGraph::from_config(&config).unwrap();
        assert!(graph.has_cycles());

        let cycles = graph.find_cycles();
        assert!(!cycles.is_empty());
    }
}
