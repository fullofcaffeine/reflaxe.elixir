package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.schema.SchemaIntrospection;
using haxe.macro.Tools;
using StringTools;
#end

class EctoQueryMacros {
#if macro

    public static macro function from<T>(schemaClass: ExprOf<Class<T>>): ExprOf<ecto.TypedQuery.TypedQuery<T>> { 
        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        #end
        try {
            var classType = getClassType(schemaClass);
            var __result:ExprOf<ecto.TypedQuery.TypedQuery<T>> = macro {
                var query = untyped __elixir__('(require Ecto.Query; Ecto.Query.from(t in {0}, []))', $v{classType.name});
                new ecto.TypedQuery.TypedQuery(query);
            };
            #if hxx_instrument_sys
            var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
            Context.warning(
                '[MacroTiming] name=EctoQueryMacros.from elapsed_ms=' + Std.int(__elapsed),
                schemaClass.pos
            );
            #end
            return __result;
        } catch (e: haxe.Exception) {
            // Macro boundary: macro execution can fail for many reasons (invalid AST shapes, schema
            // introspection mismatch, etc.). Convert to a deterministic Context.error with position.
            Context.error('Failed to process from() macro: ' + Std.string(e), Context.currentPos());
            return macro null;
        }
    }

    public static macro function where<T>(query: ExprOf<ecto.TypedQuery.TypedQuery<T>>, condition: ExprOf<T -> Bool>): ExprOf<ecto.TypedQuery.TypedQuery<T>> {
        #if hxx_instrument_sys
        var __t0 = haxe.Timer.stamp();
        #end
        var conditionExpr = extractLambdaBody(condition);
        var fieldAccesses = extractFieldAccesses(conditionExpr);
        var classType = getQueryType(query);
        for (field in fieldAccesses) {
            if (!SchemaIntrospection.hasField(classType.name, field)) {
                Context.error('Field "' + field + '" does not exist in ' + classType.name, Context.currentPos());
            }
        }
        var elixirCondition = convertToElixirCondition(conditionExpr);
        var __macroResult:ExprOf<ecto.TypedQuery.TypedQuery<T>> = macro {
            var newQuery = untyped __elixir__('(require Ecto.Query; Ecto.Query.where({0}, [t], {1}))', $query.query, $v{elixirCondition});
            new ecto.TypedQuery.TypedQuery(newQuery);
        };
        #if hxx_instrument_sys
        var __elapsed = (haxe.Timer.stamp() - __t0) * 1000.0;
        Context.warning(
            '[MacroTiming] name=EctoQueryMacros.where elapsed_ms=' + Std.int(__elapsed),
            condition.pos
        );
        #end
        return __macroResult;
    }

    static function getClassType(expr: Expr): ClassType {
        switch(expr.expr) {
            case EConst(CIdent(name)):
                var type = Context.getType(name);
                switch(type) {
                    case TInst(classRef, _): return classRef.get();
                    default: Context.error('Expected class type', expr.pos);
                }
            default: Context.error('Expected class identifier', expr.pos);
        }
        return null;
    }

    static function getQueryType(expr: Expr): ClassType {
        var type = Context.typeof(expr);
        switch(type) {
            case TAbstract(_, [TInst(classRef, _)]): return classRef.get();
            default: Context.error('Could not determine query type', expr.pos);
        }
        return null;
    }

    static function extractLambdaBody(expr: Expr): Expr {
        return switch(expr.expr) {
            case EFunction(_, f): f.expr;
            default: Context.error('Expected lambda function', expr.pos); null;
        }
    }

    static function extractFieldAccesses(expr: Expr): Array<String> {
        var fields = [];
        function traverse(e: Expr) {
            switch(e.expr) {
                case EField(obj, field):
                    switch(obj.expr) { case EConst(CIdent(_)): fields.push(field); default: }
                default:
            }
            e.iter(traverse);
        }
        traverse(expr);
        return fields;
    }

    public static function toSnakeCase(str: String): String {
        var result = ""; for (i in 0...str.length) { var c = str.charAt(i); if (c == c.toUpperCase() && i > 0) result += "_" + c.toLowerCase() else result += c.toLowerCase(); } return result;
    }

    static function convertToElixirCondition(expr: Expr): String {
        return switch(expr.expr) {
            case EBinop(OpEq, left, right):
                var leftStr = exprToElixir(left);
                var rightStr = exprToElixir(right);
                leftStr + " == ^(" + rightStr + ")";
            default:
                Context.error('Unsupported query condition', expr.pos);
                "";
        }
    }

    static function exprToElixir(expr: Expr): String {
        return switch(expr.expr) {
            case EField(obj, field):
                switch(obj.expr) {
                    case EConst(CIdent(name)) if (name == "t"): 't.' + toSnakeCase(field);
                    default: exprToElixir(obj) + '.' + toSnakeCase(field);
                }
            case EConst(CIdent(name)): name;
            case EConst(CInt(v)): v;
            case EConst(CString(s, _)): '"' + s + '"';
            case EBinop(OpAdd, l, r): exprToElixir(l) + ' <> ' + exprToElixir(r);
            default:
                Context.error('Unsupported expression in query', expr.pos);
                "";
        }
    }
#end
}
