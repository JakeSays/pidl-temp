class ParserConfiguration
{
    final SyntaxConfiguration syntax;
    bool enableTracingParser = false;

    ParserConfiguration({
        SyntaxConfiguration? syntax
    }) : syntax = syntax ?? SyntaxConfiguration();
}

class SyntaxConfiguration
{
    String namespaceKeyword = "namespace";
    String importKeyword = "import";
    String structKeyword = "struct";
    String interfaceKeyword = "interface";
    String constantKeyword = "const";
    String aliasKeyword = "alias";
    String asKeyword = "as";
    String baseSeparatorKeyword = ":";
    String trueKeyword = "true";
    String falseKeyword = "false";
    String booleanKeyword = "boolean";
    String stringKeyword = "string";
    String float32Keyword = "float32";
    String float64Keyword = "float64";
    String int8Keyword = "int8";
    String uint8Keyword = "uint8";
    String int16Keyword = "int16";
    String uint16Keyword = "uint16";
    String int32Keyword = "int32";
    String uint32Keyword = "uint32";
    String int64Keyword = "int64";
    String uint64Keyword = "uint64";
    String listKeyword = "list";
    String mapKeyword = "map";
    String enumKeyword = "enum";
    String voidKeyword = "void";
    String negativeOperatorKeyword = "-";
    String subtractOperatorKeyword = "-";
    String addOperatorKeyword = "+";
    String multiplyOperatorKeyword = "*";
    String divideOperatorKeyword = "/";
    String moduloOperatorKeyword = "%";
    String orOperatorKeyword = "|";
    String xorOperatorKeyword = "^";
    String andOperatorKeyword = "&";
    String leftShiftOperatorKeyword = "<<";
    String rightShiftOperatorKeyword = ">>";
    String negateOperatorKeyword = "~";
    String powerOperatorKeyword = "^^";
    String nullKeyword = "null";

    String assignmentToken = "=";
    String digitSeparatorToken = "'";
    String decimalSeparatorToken = ".";
    String identSeparatorToken = ".";
    String stringDelimiterToken = '"';
    String parenOpenToken = "(";
    String parenCloseToken = ")";
    String docCommentToken = "///";
    String singleLineCommentToken = "//";
    String multiLineCommentOpenToken = "/*";
    String multiLineCommentCloseToken = "*/";
    String attributeOpenToken = "[";
    String attributeCloseToken = "]";
    String scopeOpenToken = "{";
    String scopeCloseToken = "}";
}
