import 'package:meta/meta.dart';

import '../../context/context.dart';
import '../../context/result.dart';
import '../../core/parser.dart';
import '../../parser/utils/resolvable.dart';
import 'makename.stub.dart'
    if (dart.library.mirrors) 'makname.mirrors.dart';

/// Internal implementation of a reference parser.
@immutable
class ReferenceParser<R> extends Parser<R> implements ResolvableParser<R> {
  ReferenceParser(this.function, this.arguments, [super.name]);

  final Function function;
  final List arguments;
  Parser<R>? resolved;

  @override
  Parser<R> resolve() 
  {    
    var p = Function.apply(function, arguments) as Parser<R>;
    resolved = p;
    
    p.name = name ?? makename(p, function);

    return p;
  }

  @override
  Result<R> parseOn(Context context) =>
      throw UnsupportedError('References cannot be parsed.');

  @override
  ReferenceParser<R> copy() =>
      throw UnsupportedError('References cannot be copied.');

  @override
  bool operator ==(Object other) {
    if (other is ReferenceParser) {
      if (function != other.function ||
          arguments.length != other.arguments.length) {
        return false;
      }
      for (var i = 0; i < arguments.length; i++) {
        final a = arguments[i], b = other.arguments[i];
        if (a is Parser &&
            a is! ReferenceParser &&
            b is Parser &&
            b is! ReferenceParser) {
          // for parsers do a deep equality check
          if (!a.isEqualTo(b)) {
            return false;
          }
        } else {
          // for everything else just do standard equality
          if (a != b) {
            return false;
          }
        }
      }
      return true;
    }
    return false;
  }

  @override
  int get hashCode => function.hashCode;
}
