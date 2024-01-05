abstract class IEdge<TVertex extends Comparable<TVertex>>
{
    /// <summary>
    /// Gets or sets the source.
    /// </summary>
    /// <value>The source.</value>
    TVertex get Source;
    set Source(TVertex value);

    /// <summary>
    /// Gets or sets the destination.
    /// </summary>
    /// <value>The destination.</value>
    TVertex get Destination;
    set Destination(TVertex value);
}

abstract class IGraph<T extends Comparable<T>>
{
    /// <summary>
    /// Returns true, if graph is directed; false otherwise.
    /// </summary>
    bool get IsDirected;

    /// <summary>
    /// Gets the count of vetices.
    /// </summary>
    int get VerticesCount;

    /// <summary>
    /// Gets the count of edges.
    /// </summary>
    int get EdgesCount;

    /// <summary>
    /// Returns the list of Vertices.
    /// </summary>
    Iterable<T> get Vertices;

    /// <summary>
    /// An enumerable collection of edges.
    /// </summary>
    Iterable<IEdge<T>> get Edges;

    /// <summary>
    /// Get all incoming edges from vertex
    /// </summary>
    Iterable<IEdge<T>> IncomingEdges(T vertex);

    /// <summary>
    /// Get all outgoing edges from vertex
    /// </summary>
    Iterable<IEdge<T>> OutgoingEdges(T vertex);

    /// <summary>
    /// Connects two vertices together.
    /// </summary>
    bool AddEdge(T firstVertex, T secondVertex);

    /// <summary>
    /// Deletes an edge, if exists, between two vertices.
    /// </summary>
    bool RemoveEdge(T firstVertex, T secondVertex);

    /// <summary>
    /// Adds a list of vertices to the graph.
    /// </summary>
    void AddVertices(List<T> collection);

    /// <summary>
    /// Adds a new vertex to graph.
    /// </summary>
    bool AddVertex(T vertex);

    /// <summary>
    /// Removes the specified vertex from graph.
    /// </summary>
    bool RemoveVertex(T vertex);

    /// <summary>
    /// Checks whether two vertices are connected (there is an edge between firstVertex & secondVertex)
    /// </summary>
    bool HasEdge(T firstVertex, T secondVertex);

    /// <summary>
    /// Determines whether this graph has the specified vertex.
    /// </summary>
    bool HasVertex(T vertex);

    /// <summary>
    /// Returns the neighbours doubly-linked list for the specified vertex.
    /// </summary>
    List<T> Neighbours(T vertex);

    /// <summary>
    /// Returns the degree of the specified vertex.
    /// </summary>
    int Degree(T vertex);

    /// <summary>
    /// Returns a human-readable string of the graph.
    /// </summary>
    //String ToReadable();

    /// <summary>
    /// A depth first search traversal of the graph. Prints nodes as they get visited.
    /// It considers the first inserted vertex as the start-vertex for the walk.
    /// </summary>
    Iterable<T> DepthFirstWalk();

    /// <summary>
    /// A depth first search traversal of the graph, starting from a specified vertex. Prints nodes as they get visited.
    /// </summary>
    Iterable<T> DepthFirstWalkFrom(T startingVertex);

    /// <summary>
    /// A breadth first search traversal of the graph. Prints nodes as they get visited.
    /// It considers the first inserted vertex as the start-vertex for the walk.
    /// </summary>
    Iterable<T> BreadthFirstWalk();

    /// <summary>
    /// A breadth first search traversal of the graph, starting from a specified vertex. Prints nodes as they get visited.
    /// </summary>
    Iterable<T> BreadthFirstWalkFrom(T startingVertex);

    /// <summary>
    /// Clear this graph.
    /// </summary>
    void Clear();
}
