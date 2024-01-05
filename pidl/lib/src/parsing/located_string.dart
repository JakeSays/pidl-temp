import '../source.dart';

class LocatedString implements LocationProvider
{
    final String string;
    
    @override
    SourceLocation? location;

    LocatedString({required this.string, required this.location});

    @override
    String toString() 
    {
        return "$string : $location";
    }
}
