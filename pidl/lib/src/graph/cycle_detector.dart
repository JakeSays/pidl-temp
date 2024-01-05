import 'dart:collection';

import 'graph.dart';

/// <summary>
/// Returns true if Graph has cycle.
/// </summary>
bool IsCyclic<T extends Comparable<T>>(IGraph<T> Graph, List<T> cycle)
{
    var visited = HashSet<T>();
    var recursionStack = HashSet<T>();

    if (Graph.IsDirected)
    {
        for (var vertex in Graph.Vertices)
        {
            final result = _isDirectedCyclic<T>(Graph, vertex, visited, recursionStack);
            if (result != null)
            {
                cycle.add(vertex);
                cycle.add(result);
                return true;
            }
        }
    }
    else
    {
        for (var vertex in Graph.Vertices)
        {
            final result = _isUndirectedCyclic<T>(Graph, vertex, null, visited);
            if (result != null)
            {
                cycle.add(vertex);
                cycle.add(result);
                return true;
            }
        }
    }

    return false;
}

T? _isUndirectedCyclic<T extends Comparable<T>>(IGraph<T> graph, T source, Object? parent, HashSet<T> visited)
{
    if (!visited.contains(source))
    {
        // Mark the current node as visited
        visited.add(source);

        // Recur for all the vertices adjacent to this vertex
        for (var adjacent in graph.Neighbours(source))
        {
            // If an adjacent node was not visited, then check the DFS forest of the adjacent for UNdirected cycles.
            if (!visited.contains(adjacent))
            {
                final result = _isUndirectedCyclic<T>(graph, adjacent, source, visited);
                if (result != null)
                {
                    return result;
                }
            }

            // If an adjacent is visited and NOT parent of current vertex, then there is a cycle.
            if (parent != null && adjacent.compareTo(parent as T) != 0)
            {
                return adjacent;
            }
        }
    }

    return null;
}

T? _isDirectedCyclic<T extends Comparable<T>>(IGraph<T> graph, T source, HashSet<T> visited, HashSet<T> recursionStack)
{
    if (!visited.contains(source))
    {
        // Mark the current node as visited and add it to the recursion stack
        visited.add(source);
        recursionStack.add(source);

        // Recur for all the vertices adjacent to this vertex
        for (var adjacent in graph.Neighbours(source))
        {
            // If an adjacent node was not visited, then check the DFS forest of the adjacent for directed cycles.
            if (!visited.contains(adjacent))
            {
                final result = _isDirectedCyclic<T>(graph, adjacent, visited, recursionStack);
                if (result != null)
                {
                    return result;
                }
            }

            // If an adjacent is visited and is on the recursion stack then there is a cycle.
            if (recursionStack.contains(adjacent))
            {
                return adjacent;
            }
        }
    }

    // Remove the source vertex from the recursion stack
    recursionStack.remove(source);
    return null;
}
