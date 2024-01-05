import 'graph.dart';

class UnweightedEdge<TVertex extends Comparable<TVertex>> extends IEdge<TVertex>
    implements Comparable<TVertex>
{
    /// <summary>
    /// Gets or sets the source vertex.
    /// </summary>
    /// <value>The source.</value>
    @override
    TVertex Source;

    /// <summary>
    /// Gets or sets the destination vertex.
    /// </summary>
    /// <value>The destination.</value>
    @override
    TVertex Destination;

    UnweightedEdge(this.Source, this.Destination);

    @override
    int compareTo(TVertex other) 
    {
        var result = Source.compareTo(other);
        if (result != 0)
        {
            return result;
        }

        return Destination.compareTo(other);
    }
}

