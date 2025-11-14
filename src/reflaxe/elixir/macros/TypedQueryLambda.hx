package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
using haxe.macro.Tools;
#end

class TypedQueryLambda {
#if macro
    public static function buildWhereExpr(ethis: Expr, predicate: Expr): Expr {
        // Extract function arg name and body (eg. "u -> ..." → argName = "u")
        var argName = (function() return switch (predicate.expr) {
            case EFunction(_, f) if (f.args != null && f.args.length > 0): f.args[0].name;
            default: "t";
        })();
        var body = extractLambdaBody(predicate);

        // Determine schema type from TypedQuery<T>
        var classType = getQueryType(ethis);

        // Build Elixir condition template + pinned value args
        #if debug_elixir_where
        var printer = new haxe.macro.Printer();
        Context.warning('TypedQuery.where predicate: ' + printer.printExpr(body), body.pos);
        #end
        // Compose injection directly for simple binary comparisons
        return switch (body.expr) {
            case EBinop(op, left, right) if (isComparison(op)):
                var fieldSnake = toField(left, argName, classType.name, body.pos);
                var opStr = opToString(op);
                var code = '(require Ecto.Query; Ecto.Query.where({0}, [t], ' + fieldSnake + ' ' + opStr + ' ^({1})))';
                // Return a pure expression (no TBlock/TVar), to avoid broken assignments in generated code
                macro new ecto.TypedQuery.TypedQuery(untyped __elixir__($v{code}, $ethis, $right));
            case _:
                Context.error('Unsupported where() condition. Supported: ==, !=, <, <=, >, >=, &&, ||, !', body.pos);
                macro $ethis;
        }
    }
    public static macro function where<T>(ethis: ExprOf<ecto.TypedQuery<T>>, predicate: ExprOf<T -> Bool>): Expr {
        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        #end
        var __expr = buildWhereExpr(ethis, predicate);
        #if hxx_instrument_sys
        var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
        haxe.macro.Context.warning(
            '[MacroTiming] name=TypedQueryLambda.where elapsed_ms=' + Std.int(__elapsed),
            predicate.pos
        );
        #end
        return __expr;
    }

    // Represents a condition template and the pinned value expressions it references
    private static inline function makeCond(template:String, values:Array<Expr>):{template:String, values:Array<Expr>} {
        return { template: template, values: values };
    }

    // Recursively build condition string and collect pinned values
    private static function buildCondition(e: Expr, param: String, schemaName: String): {template:String, values:Array<Expr>} {
        #if debug_elixir_where
        switch (e.expr) {
            case EBinop(op, _, _):
                Context.warning('operator detected: ' + Std.string(op), e.pos);
            case _:
                Context.warning('expr tag: ' + Std.string(e.expr), e.pos);
        }
        #end
        return switch (e.expr) {
            // Binary comparisons
            case EBinop(op, left, right) if (isComparison(op)):
                var fieldStr = toField(left, param, schemaName, e.pos);
                var opStr = opToString(op);
                // Right-hand side is passed as an expression and pinned with ^{index}
                var idx = 1; // will be adjusted by caller based on concatenation order
                var tpl = fieldStr + ' ' + opStr + ' ^{' + idx + '}';
                makeCond(tpl, [right]);

            // Boolean AND / OR
            case EBinop(OpBoolAnd, l, r):
                combineBool('and', buildCondition(l, param, schemaName), buildCondition(r, param, schemaName));
            case EBinop(OpBoolOr, l, r):
                combineBool('or', buildCondition(l, param, schemaName), buildCondition(r, param, schemaName));

            // NOT
            case EUnop(OpNot, true, inner):
                var c = buildCondition(inner, param, schemaName);
                makeCond('(not (' + c.template + '))', c.values);

            // Parenthesized expressions (keep grouping)
            case EParenthesis(inner):
                var c = buildCondition(inner, param, schemaName);
                makeCond('(' + c.template + ')', c.values);

            default:
                haxe.macro.Context.error('Unsupported where() condition. Supported: ==, !=, <, <=, >, >=, &&, ||, !', e.pos);
                makeCond('', []);
        }
    }

    private static function isComparison(op:haxe.macro.Binop):Bool {
        return switch (op) {
            case OpEq | OpNotEq | OpLt | OpLte | OpGt | OpGte: true;
            default: false;
        }
    }

    private static function opToString(op:haxe.macro.Binop):String {
        return switch (op) {
            case OpEq: '==';
            case OpNotEq: '!=';
            case OpLt: '<';
            case OpLte: '<=';
            case OpGt: '>';
            case OpGte: '>=';
            default: Context.error('Unsupported operator', Context.currentPos()); '';
        }
    }

    // Validate left-hand side is the lambda param field, return snake-cased Elixir access like "t.user_id"
    private static function toField(e: Expr, param: String, schemaName: String, pos:haxe.macro.Position): String {
        return switch (e.expr) {
            case EField(obj, field):
                // Validate field exists on schema
                if (!reflaxe.elixir.schema.SchemaIntrospection.hasField(schemaName, field)) {
                    Context.error('Field "' + field + '" does not exist in ' + schemaName, pos);
                }
                't.' + toSnakeCase(field);
            default:
                Context.error('Left side must be a field access (e.g., ' + param + '.field)', pos);
                '';
        }
    }

    // Combine two boolean conditions and reindex pinned placeholders
    private static function combineBool(op:String, left:{template:String, values:Array<Expr>}, right:{template:String, values:Array<Expr>}):{template:String, values:Array<Expr>} {
        // Reindex right side placeholders to start after left's count
        var leftCount = left.values.length;
        var reindexedRightTemplate = reindexPlaceholders(right.template, leftCount);
        var tpl = '(' + left.template + ') ' + op + ' (' + reindexedRightTemplate + ')';
        return makeCond(tpl, left.values.concat(right.values));
    }

    // Shift placeholder indices in a template by offset (^{1} → ^{1+offset})
    private static function reindexPlaceholders(template:String, offset:Int):String {
        if (offset == 0) return template;
        // Replace ^{n} with ^{n+offset}; keep it simple with a small parser
        var buf = new StringBuf();
        var i = 0;
        while (i < template.length) {
            var ch = template.charAt(i);
            if (ch == '^' && i + 2 < template.length && template.charAt(i+1) == '{') {
                // read number
                var j = i + 2; var num = "";
                while (j < template.length && template.charAt(j) >= '0' && template.charAt(j) <= '9') { num += template.charAt(j); j++; }
                if (j < template.length && template.charAt(j) == '}') {
                    var n = Std.parseInt(num);
                    if (n != null) {
                        buf.add('^{'); buf.add(Std.string(n + offset)); buf.add('}');
                        i = j + 1; continue;
                    }
                }
            }
            buf.add(ch); i++;
        }
        return buf.toString();
    }

    // Local helpers (avoid depending on EctoQueryMacros private members)
    private static function extractLambdaBody(expr: Expr): Expr {
        var body:Expr = switch (expr.expr) {
            case EFunction(_, f) if (f != null): f.expr;
            case EParenthesis(inner): extractLambdaBody(inner);
            case EMeta(_, inner): extractLambdaBody(inner);
            default: Context.error('Expected lambda function for where()', expr.pos); expr;
        };
        return unwrapImplicitReturn(body);
    }

    private static function unwrapImplicitReturn(e:Expr):Expr {
        return switch (e.expr) {
            case EReturn(inner) if (inner != null): unwrapImplicitReturn(inner);
            case EMeta(meta, inner) if (meta != null && meta.name == ":implicitReturn"): unwrapImplicitReturn(inner);
            default: e;
        }
    }

    private static function unwrapToExpr(expr:Expr):Expr {
        return switch (expr.expr) {
            case EParenthesis(inner): unwrapToExpr(inner);
            case EMeta(_, inner): unwrapToExpr(inner);
            default: expr;
        }
    }

    private static function getQueryType(expr: Expr): ClassType {
        var t = Context.typeof(expr);
        return switch (t) {
            case TAbstract(_, params) if (params != null && params.length > 0):
                switch (params[0]) {
                    case TInst(clsRef, _): clsRef.get();
                    default: Context.error('Unable to infer schema type parameter for TypedQuery<T>', expr.pos); null;
                }
            default:
                Context.error('Expected TypedQuery<T> expression', expr.pos);
                null;
        }
    }

    private static function toSnakeCase(str:String):String {
        var out = new StringBuf();
        for (i in 0...str.length) {
            var c = str.charAt(i);
            if (c == c.toUpperCase() && i > 0) {
                out.add("_"); out.add(c.toLowerCase());
            } else {
                out.add(c.toLowerCase());
            }
        }
        return out.toString();
    }
#end
}
