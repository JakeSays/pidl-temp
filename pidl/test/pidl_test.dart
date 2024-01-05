import 'dart:ffi';

import 'package:pidl/pidl.dart';
import 'package:test/test.dart';
import 'expression_utils.dart';
import 'test_utils.dart';

void run(String source, Expr expected, Expression Function(CompileResult result) selector)
{
    final diag = Diagnostics();
    final comp = IdlCompiler(
        diagnostics: diag, 
        sourceProvider: SingleSourceProvider(content: source));

    final result = comp.compileFile("main.idl");
    if (result == null)
    {
        diag.displayIssues();
    }

    expect(diag.hasErrors, false);
    expect(result != null, true);
    
    final actual = selector(result!);
    match(actual, expected);
}

ParseIssue syntaxError(String message, [IssueCode? code])
{
    return ParseIssue(code: code ?? IssueCode.syntaxError, severity: IssueSeverity.error, message: message);
}


void main() 
{
    group("failures", ()
    {
        test("interface circular dep", () => compileFail("interface A {} interface B : A {} interface C : A, B, C {}", [syntaxError("Definition C either directly or indirectly depends on itself.", IssueCode.circularDependency)]));
        test("missing {", () => compileFail("enum E a}", [syntaxError("{ expected")]));
    });

    group('expressions', () 
    {
        setUp(() {
        // Additional setup goes here.
        });

        test('add1', () => evaluateExpr(["1 + 2k"], NumberKind.int16, I(2001, Int16(1) + Int16(2000))));
        test('add2', () => evaluateExpr(["(1 + 2k)"], NumberKind.int16, I(2001, P(Int16(1) + Int16(2000)))));
        test('add3', () => evaluateExpr(["(1 + 2k) + 1k"], NumberKind.int16, I(3001, P(Int16(1) + Int16(2000)) + Int16(1000))));
        test('lshift1', () => evaluateExpr(["1 << 10"], NumberKind.int32, I(1 << 10, Int32(1) << Int32(10))));
        test('rshift1', () => evaluateExpr(["4 >> 2"], NumberKind.int32, I(4 >> 2, Int32(4) >> Int32(2))));
        test("mul1", () => evaluateExpr(["10 / 2"], NumberKind.int32, I(5, Int32(10) / Int32(2))));
        test("mul2", () => evaluateExpr(["10 / 2 + 1"], NumberKind.int32, I(6, Int32(10) / Int32(2) + Int32(1))));
        test("pow1", () => evaluateExpr(["10 ^^ 2"], NumberKind.int32, I(100, Int32(10) >>> Int32(2))));
        test("pow2", () => evaluateExpr(["10 ^^ 2 * 2"], NumberKind.int32, I(200, (Int32(10) >>> Int32(2)) * Int32(2))));
        test("pow3", () => evaluateExpr(["100 / 10 ^^ 2 * 2"], NumberKind.int32, I(200, ((Int32(100) / Int32(10)) >>> Int32(2)) * Int32(2))));
        test("and1", () => evaluateExpr(["0xfefefefe & 0x00ff0000"], NumberKind.uint32, I(0x00FE0000, UInt32(0xFEFEFEFE) & UInt32(0x00FF0000))));
        test("and2", () => evaluateExpr(["0xfefefefe & 0x00ff0000 + 1"], NumberKind.uint32, I(0x00FE0001, UInt32(0xFEFEFEFE) & UInt32(0x00FF0000) + UInt32(1))));
        test("and3", () => evaluateExpr(["0xfefefefe & 0x00ff0000 + 1 / 4"], NumberKind.uint32, I(0x00FE0001 ~/ 4, UInt32(0xFEFEFEFE) & UInt32(0x00FF0000) + UInt32(1) / UInt32(4))));
        test("const1", () => evaluateExpr(["10", "c1 + 2"], NumberKind.uint32, I(12, CRef("c1", UInt32(10)) + UInt32(2))));
        test("const2", () => evaluateExpr(["10", "c1 + c1"], NumberKind.uint32, I(20, CRef("c1", UInt32(10)) + CRef("c1", UInt32(10)))));
    });

    group("structs", ()
    {
        test("struct1", () => evaluateStruct("struct s {int8 f;}", struct("s", [field("f", "int8")])));
        test("struct2", () => evaluateStruct("struct s {int8 f = 10;}", struct("s", [field("f", "int8", Int8(10))])));
        test("struct3", () => evaluateStruct("struct s {int8 f = 10 + 2;}", struct("s", [field("f", "int8", I(12, Int8(10) + Int8(2)))])));
        test("struct4", () => evaluateStruct("enum E {a} struct s {E f;}", struct("s", [field("f", "E")]), false));
        test("struct5", () => evaluateStruct("enum E {a} struct s {E f = E.a;}", struct("s", [field("f", "E", I(0, ERef("E.a", 0)))]), false));
        test("struct6", () => evaluateStruct("enum E {a,b} struct s {E f = E.b;}", struct("s", [field("f", "E", I(1, ERef("E.b", 1)))]), false));
        test("struct7", () => evaluateStruct("const int8 C=10; struct s {int8 f = C;}", struct("s", [field("f", "int8", I(10, CRef("C", Int8(10))))]), false));
    });

    group("interfaces", ()
    {
        test("interface1", () => evaluateInterface("interface A {}", interface("A")));
        test("interface2", () => evaluateInterface("interface A {} interface B : A {}", interface("B", null, ["A"])));
        test("interface3", () => evaluateInterface("interface A {} interface B : A {} interface C : A, B {}", interface("C", null, ["A", "B"])));
        test("interface5", () => evaluateInterface("interface A {void m1();}", interface("A", [method("m1", "void")])));
        test("interface6", () => evaluateInterface("interface A {void m1(int8 p1);}", interface("A", [method("m1", "void", [param("p1", "int8")])])));
        test("interface7", () => evaluateInterface("enum E {a} interface A {void m1(int8 p1, E p2);}", interface("A", 
            [method("m1", "void", [param("p1", "int8"), param("p2", "E")])])));
        test("interface8", () => evaluateInterface("enum E {a} interface A {void m1(int8 p1, E p2 = E.a);}", interface("A", 
            [method("m1", "void", [param("p1", "int8"), param("p2", "E", I(0, ERef("E.a", 0)))])])));
        test("interface9", () => evaluateInterface("const int8 C=10; enum E {a} interface A {void m1(int8 p1 = C, E p2 = E.a);}", interface("A", 
            [method("m1", "void", [param("p1", "int8", I(10, CRef("C", Int8(10)))), param("p2", "E", I(0, ERef("E.a", 0)))])])));
    });

    group("enums", ()
    {
        test("enum1",() => evaluateEnum("enum E {a}", mune("E", [rant("a", 0)])));
        test("enum2",() => evaluateEnum("enum E {a = 0b101}", mune("E", [rant("a", 5, Int32(5))])));
        test("enum3",() => evaluateEnum("enum E : uint16 {a = 0b101}", mune("E", [rant("a", 5, UInt16(5))], "uint16")));
        test("enum4",() => evaluateEnum("const int8 C=10; enum E : int8 {a=C}", mune("E", [rant("a", 10, CRef("C", Int8(10)))], "int8")));
        test("enum5",() => evaluateEnum("enum E {a,b=a+5}", mune("E", [rant("a", 0), rant("b", 5, ERef("E.a", 0) + Int32(5))])));
        test("enum6",() => evaluateEnum("enum E {a,b=a+5,c}", mune("E", 
            [
                rant("a", 0), 
                rant("b", 5, ERef("E.a", 0) + Int32(5)),
                rant("c", 6)
            ]
        )));
        test("enum7",() => evaluateEnum("enum E {a,b,c,d}", mune("E", 
            [
                rant("a", 0),
                rant("b", 1),
                rant("c", 2),
                rant("d", 3),
            ]
        )));
        test("enum8",() => evaluateEnum("enum E {a=10,b}", mune("E", [rant("a", 10, Int32(10)), rant("b", 11)]), false));
        test("enum9",() => evaluateEnum("enum E {a=10,b=a*5}", mune("E", [rant("a", 10, Int32(10)), rant("b", 50, ERef("E.a", 10) * Int32(5))]), false));
    });
}
