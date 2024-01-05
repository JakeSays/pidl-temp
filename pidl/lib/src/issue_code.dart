
enum IssueCode implements Comparable<IssueCode>
{
    none(code: 0, message: "No Issue"),

    //library consumer generic issues
    fail(code: 42, message: "Unknown error"),
    exception(code: 911, message: "Exception"),
    note(code: 411, message: ""),

    //parse related issues
    somethingBadHappened(code: 1000, message: "Parse failed for some reason"),
    importNotFound(code: 1001, message: "Import file not found"),
    fileNotFound(code: 1002, message: "Source file not found"),
    syntaxError(code: 1003, message: "Syntax error"),

    //semantic related issues
    invalidType(code: 2000, message: "Invalid type"),
    invalidValue(code: 2001, message: "Invalid value"),
    outOfBounds(code: 2002, message: "Out of bounds"),
    duplicateName(code: 2003, message: "Duplicate name"),
    duplicateValue(code: 2004, message: "Duplicate value"),
    unknownEnumerant(code: 2005, message: "Unknown enumerant"),
    unknownAttribute(code: 2006, message: "Unknown attribute"),
    ambiguousTypes(code: 2006, message: "Ambiguous types"),
    invalidName(code: 2007, message: "Invalid name"),
    invalidValueType(code: 2008, message: "Invalid value type"),
    outOfRange(code: 2009, message: "Value is out of range for numeric type"),
    circularDependency(code: 2010, message: "Circular dependency detected"),
    unknownType(code: 2010, message: "Unknown type"),
    typeExpected(code: 2011, message: "Type expected"),
    nullValueNotAllowed(code: 2012, message: "Null value not allowed"),
    duplicateParameters(code: 2013, message: "Parameter names must be unique"),
    duplicateMethods(code: 2014, message: "Method names must be unique"),
    invalidParameterType(code: 2015, message: "Invalid type for parameter"),
    invalidReturnType(code: 2016, message: "Invalid return type"),
    invalidBaseType(code: 2017, message: "Invalid base type"),
    duplicateFields(code: 2018, message: "Field names must be unique"),
    invalidFieldType(code: 2019, message: "Invalid field type"),
    illFormedLiteral(code: 2020, message: "Improperly formed literal"),
    invalidAttributeArgValue(code: 2021, message: "Invalid attribute argument value"),
    incompleteDefinition(code: 2022, message: "Incomplete definition"),
    duplicateBaseTypes(code: 2023, message: "Duplicate base types"),
    invalidFileAttribute(code: 2024, message: "file: attributes are only valid at the file level"),
    invalidInitializer(code: 2025, message: "Invalid initializer expression"),

    //expression evaluation issues
    invalidLiteralValue(code: 3000, message: "Invalid literal value"),
    invalidExpressionType(code: 3001, message: "Invalid expression type")
    ;

    final int code;
    final String message;

    const IssueCode({
        required this.code,
        required this.message
    });

    @override
    int compareTo(IssueCode other)
    {
        if (code < other.code)
        {
            return -1;
        }

        if (code > other.code)
        {
            return 1;
        }

        return message.compareTo(other.message);
    }
}