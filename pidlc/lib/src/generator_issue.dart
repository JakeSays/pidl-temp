import 'package:pidl/pidl.dart';

class GeneratorIssue extends Issue
{
    final Definition? definition;

    @override
    SourceLocation? get location => definition?.location;
    
    GeneratorIssue({
        required super.severity,
        this.definition,
        super.message,
        super.details
    }) : super(code: IssueCode.fail, type: "gen");
}