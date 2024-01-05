import 'issues.dart';
import 'console.dart';

export 'issues.dart';
export 'issue_code.dart';

class Diagnostics
{
    final List<Issue> issues = [];

    final bool detailed;
    Diagnostics({this.detailed = false});

    int errorCount = 0;
    int warningCount = 0;

    void addIssue(Issue issue) 
    {
        issues.add(issue);

        if (issue.severity == IssueSeverity.error)
        {
            errorCount += 1;
        }
        else if (issue.severity == IssueSeverity.warning)
        {
            warningCount += 1;
        }
    }

    bool get hasIssues => issues.isNotEmpty;
    bool get hasErrors => errorCount > 0;

    void displayIssues()
    {
        for (final issue in issues)
        {
            displayIssue(issue);
        }
    }

    void displayIssue(Issue issue)
    {
        Function writer = write;
        String prefix = "INFO: (${issue.type}) ";

        if (issue.severity == IssueSeverity.error)
        {
            writer = red;
            prefix = "ERROR: (${issue.type}) ";
        }
        else if (issue.severity == IssueSeverity.warning)
        {
            writer = yellow;
            prefix = "WARNING: (${issue.type}) ";
        }

        final loc = issue.location;

        if (loc != null)
        {
            writer("${loc.description}: ");
        }
        writer("$prefix${issue.message}");
        writeln();

        final displayDetails = detailed && issue.details != null;

        if (loc != null)
        {
            blueln(loc.startLine);
            blueln("${" " * (loc.start.column - 1)}^");
        }

        if (issue is ParseIssue && issue.lastSuccessfulNode != null)
        {
            yellowln("Closest to:");
            blueln(issue.lastSuccessfulNode!.location!.startLine);
            blueln("${" " * (issue.lastSuccessfulNode!.location!.start.column - 1)}^");
        }

        if (displayDetails)
        {
            writeln(issue.details);
        }
    }
}