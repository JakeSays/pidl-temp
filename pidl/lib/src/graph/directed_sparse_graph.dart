/// *
/// The Directed Sparse Graph Data Structure.
/// 
/// Definition:
/// A sparse graph is a graph G = (V, E) in which |E| = O(|V|).
/// A directed graph is a graph where each edge follow one direction only between any two vertices.
/// 
/// An adjacency-list digraph (directed-graph) representation. 
/// Implements the IGraph<T> interface.

import "graph.dart";
import 'unweighted_edge.dart';
import 'dart:collection';
import 'cycle_detector.dart';

class CycleException<T> implements Exception 
{
    List<Object> cycle;
    
    CycleException(this.cycle);

    @override
    String toString() => 'A cycle was detected in a graph that must be acyclic';
}

class DirectedSparseGraph<T extends Comparable<T>> extends IGraph<T>
{
    int _edgesCount;
    T? _firstInsertedNode;
    final Map<T, LinkedList<_AdjEntry<T>>> _adjacencyList = {};

    DirectedSparseGraph()
        : _edgesCount = 0;

    /// <summary>
    /// Helper function. Checks if edge exist in graph.
    /// </summary>
    bool _doesEdgeExist(T vertex1, T vertex2)
    {
        final contains = _adjacencyList[vertex1]!.Contains(vertex2);
        return contains;
    }

    /// <summary>
    /// Returns true, if graph is directed; false otherwise.
    /// </summary>
    @override
    bool get IsDirected => true;

    /// <summary>
    /// Gets the count of vetices.
    /// </summary>
    @override
    int get VerticesCount => _adjacencyList.length;

    /// <summary>
    /// Gets the count of edges.
    /// </summary>
    @override
    int get EdgesCount => _edgesCount;

    /// <summary>
    /// Returns the list of Vertices.
    /// </summary>
    @override
    Iterable<T> get Vertices => _adjacencyList.keys;

    @override
    Iterable<IEdge<T>> get Edges => _edges();

    @override
    Iterable<IEdge<T>> IncomingEdges(T vertex) => _incomingEdges(vertex);

    @override
    Iterable<IEdge<T>> OutgoingEdges(T vertex) => _outgoingEdges(vertex);

    Iterable<UnweightedEdge<T>> _edges() sync*
    {
        for (final vertex in _adjacencyList.entries)
        {
            for (final adjacent in vertex.value)
            {
                yield UnweightedEdge(vertex.key, adjacent.entry!);
            }
        }
    }

    Iterable<UnweightedEdge<T>> _incomingEdges(T vertex) sync*
    {
        if (!HasVertex(vertex))
        {
            return;            
        }
        
        for(var adjacent in _adjacencyList.keys)
        {
            if (_adjacencyList[adjacent]!.Contains(vertex))
            {
                yield UnweightedEdge(adjacent, vertex);
            }
        }
    }

    Iterable<UnweightedEdge<T>> _outgoingEdges(T vertex) sync*
    {
        if (!HasVertex(vertex))
        {
            return;
        }

        for(var adjacent in _adjacencyList[vertex]!)
        {   
            yield UnweightedEdge(vertex, adjacent.entry!);
        }
    }


    /// <summary>
    /// Connects two vertices together in the direction: first->second.
    /// </summary>
    @override
    bool AddEdge(T source, T destination)
    {
        if (!HasVertex(source) || !HasVertex(destination))
        {
            return false;
        }
        if (_doesEdgeExist(source, destination))
        {
            return false;
        }

        // Add edge from source to destination
        _adjacencyList[source]!.add(_AdjEntry(destination));

        _edgesCount += 1;

        return true;
    }

    /// <summary>
    /// Removes edge, if exists, from source to destination.
    /// </summary>
    @override
    bool RemoveEdge(T source, T destination)
    {
        // Check existence of nodes and non-existence of edge
        if (!HasVertex(source) || !HasVertex(destination))
        {
            return false;
        }
        if (!_doesEdgeExist(source, destination))
        {
            return false;
        }

        // Remove edge from source to destination
        final list = _adjacencyList[source]!;
        list.Remove(destination);

        // Decrement the edges count
        _edgesCount -= 1;

        return true;
    }

    /// <summary>
    /// Add a collection of vertices to the graph.
    /// </summary>
    @override
    void AddVertices(List<T> collection)
    {
        for (final entry in collection)
        {
            AddVertex(entry);
        }
    }

    /// <summary>
    /// Add vertex to the graph
    /// </summary>
    @override
    bool AddVertex(T vertex)
    {
        if (HasVertex(vertex))
        {
            return false;
        }

        if (_adjacencyList.isEmpty)
        {
            _firstInsertedNode = vertex;
        }

        _adjacencyList[vertex] = LinkedList<_AdjEntry<T>>();

        return true;
    }

    /// <summary>
    /// Removes the specified vertex from graph.
    /// </summary>
    @override
    bool RemoveVertex(T vertex)
    {
        // Check existence of vertex
        if (!HasVertex(vertex))
        {
            return false;
        }

        // Subtract the number of edges for this vertex from the total edges count
        _edgesCount = _edgesCount - _adjacencyList[vertex]!.length;

        // Remove vertex from graph
        _adjacencyList.remove(vertex);

        // Remove destination edges to this vertex
        for (var adjacent in _adjacencyList.entries)
        {
            if (adjacent.value.Contains(vertex))
            {
                adjacent.value.Remove(vertex);

                // Decrement the edges count.
                _edgesCount -= 1;
            }
        }

        return true;
    }

    /// <summary>
    /// Checks whether there is an edge from source to destination.
    /// </summary>
    @override
    bool HasEdge(T source, T destination)
    {
        return _adjacencyList[source] != null && 
            _adjacencyList[destination] != null && 
            _doesEdgeExist(source, destination);
    }

    /// <summary>
    /// Checks whether a vertex exists in the graph
    /// </summary>
    @override
    bool HasVertex(T vertex)
    {
        return _adjacencyList[vertex] != null;
    }

    /// <summary>
    /// Returns the neighbours doubly-linked list for the specified vertex.
    /// </summary>
    List<T> Neighbours(T vertex)
    {
        if (!HasVertex(vertex))
        {
            return [];
        }

        final adj = _adjacencyList[vertex];
        if (adj == null)
        {
            return [];
        }
        final result = adj.map((e) => e.entry!).toList();
        return result;
    }

    /// <summary>
    /// Returns the degree of the specified vertex.
    /// </summary>
    @override
    int Degree(T vertex)
    {
        return _adjacencyList[vertex]?.length ?? -1;
    }

    /// <summary>
    /// Returns a human-readable string of the graph.
    /// </summary>
    // String ToReadable()
    // {
    //     String output = "";

    //     for (var node in _adjacencyList.entries)
    //     {
    //         var adjacents = "";

    //         output = "$output\n${node.key}: [";

    //         for (var adjacentNode in node.value)
    //         {
    //             adjacents = "$adjacents$adjacentNode";
    //         }

    //         if (adjacents.isNotEmpty)
    //         {
    //             adjacents = adjacents.trimRight()
    //             .TrimEnd(new char[] { ',', ' ' });
    //         }

    //         output = String.Format("{0}{1}]", output, adjacents);
    //     }

    //     return output;
    // }

    /// <summary>
    /// A depth first search traversal of the graph starting from the first inserted node.
    /// Returns the visited vertices of the graph.
    /// </summary>
    @override
    Iterable<T> DepthFirstWalk()
    {
        if (_firstInsertedNode == null)
        {
            return [];
        }
        return DepthFirstWalkFrom(_firstInsertedNode!);
    }

    /// <summary>
    /// A depth first search traversal of the graph, starting from a specified vertex.
    /// Returns the visited vertices of the graph.
    /// </summary>
    @override
    Iterable<T> DepthFirstWalkFrom(T source)
    {
        // Check for existence of source
        if (VerticesCount == 0)
        {
            return [];
        }
        if (!HasVertex(source))
        {
            return [];
        }

        var visited = HashSet<T>();
        var stack = <T>[];
        var listOfNodes = <T>[];

        stack.add(source);

        while (stack.isNotEmpty)
        {
            var current = stack.removeLast();

            if (!visited.contains(current))
            {
                listOfNodes.add(current);
                visited.add(current);

                for (var adjacent in Neighbours(current))
                {
                    if (!visited.contains(adjacent))
                    {
                        stack.add(adjacent);
                    }
                }
            }
        }

        return listOfNodes;
    }

    /// <summary>
    /// A breadth first search traversal of the graphstarting from the first inserted node.
    /// Returns the visited vertices of the graph.
    /// </summary>
    @override
    Iterable<T> BreadthFirstWalk()
    {
        if (_firstInsertedNode == null)
        {
            return [];
        }
        return BreadthFirstWalkFrom(_firstInsertedNode!);
    }

    /// <summary>
    /// A breadth first search traversal of the graph, starting from a specified vertex.
    /// Returns the visited vertices of the graph.
    /// </summary>
    @override
    Iterable<T> BreadthFirstWalkFrom(T source)
    {
        // Check for existence of source
        if (VerticesCount == 0)
        {
            return [];
        }

        if (!HasVertex(source))
        {
            return [];
        }

        var visited = HashSet<T>();
        var queue = Queue<T>();
        var listOfNodes = <T>[];

        listOfNodes.add(source);
        visited.add(source);

        queue.add(source);

        while (queue.isNotEmpty)
        {
            var current = queue.removeLast();
            var neighbors = Neighbours(current);

            for (var adjacent in neighbors)
            {
                if (!visited.contains(adjacent))
                {
                    listOfNodes.add(adjacent);
                    visited.add(adjacent);
                    queue.add(adjacent);
                }
            }
        }

        return listOfNodes;
    }

    /// <summary>
    /// Clear this graph.
    /// </summary>
    @override
    void Clear()
    {
        _edgesCount = 0;
        _adjacencyList.clear();
    }

    List<T> TopologicalSort()
    {
        List<T> cycle = [];
        if (IsCyclic<T>(this, cycle))
        {
            throw CycleException(cycle);
        }

        var visited = HashSet<T>();
        var topoSortStack = <T>[];

        for (var vertex in Vertices)
        {
            if (!visited.contains(vertex))
            {
                _topoSortHelper(vertex, topoSortStack, visited);
            }
        }

        return topoSortStack;        
    }

    void _topoSortHelper(T source, List<T> topoSortStack, HashSet<T> visited)
    {
        visited.add(source);

        for (var adjacent in Neighbours(source))
        {
            if (!visited.contains(adjacent))
            {
                _topoSortHelper(adjacent, topoSortStack, visited);
            }
        }

        topoSortStack.add(source);
    }
}

final class _AdjEntry<T> extends LinkedListEntry<_AdjEntry<T>>
{
    T? entry;

    _AdjEntry(this.entry);
}

extension _LinkedListExtension<T> on LinkedList<_AdjEntry<T>>
{
    bool Contains(T value)
    {
        return any((element) => element.entry == value);
    }

    _AdjEntry<T>? find(T entry)
    {
        for (final el in this)
        {
            if (el.entry == entry)
            {
                return el;
            }
        }

        return null;
    }

    void Remove(T value)
    {
        final entry = find(value);
        if (entry == null)
        {
            return;
        }

        remove(entry);
    }
}
