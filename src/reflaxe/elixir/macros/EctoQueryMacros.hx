package reflaxe.elixir.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.schema.SchemaIntrospection;

using haxe.macro.Tools;
using StringTools;

/**
 * Macro-based type-safe query builder for Ecto
 * 
 * Provides compile-time validation and idiomatic Elixir query generation
 * following standard Phoenix/Ecto patterns exactly.
 * 
 * Design Philosophy:
 * - Looks exactly like Ecto.Query in Phoenix apps
 * - Type safety without changing runtime patterns
 * - Compile-time field validation
 * - Automatic camelCase to snake_case conversion
 */
class EctoQueryMacros {
    /**
     * Create a type-safe query from a schema class
     * Generates: from(t in Todo, ...)
     */
    public static macro function from<T>(schemaClass: ExprOf<Class<T>>): ExprOf<ecto.TypedQuery.TypedQuery<T>> {
        try {
            var classType = getClassType(schemaClass);
            var schemaInfo = SchemaIntrospection.getSchemaInfo(classType.name);
            var tableName = schemaInfo != null ? schemaInfo.tableName : classType.name;
            
            // Generate the Ecto.Query.from expression
            // Return a TypedQuery instance directly
            return macro {
                var query = untyped __elixir__(
                    '(require Ecto.Query; Ecto.Query.from(t in {0}, []))',
                    $v{classType.name}
                );
                new ecto.TypedQuery.TypedQuery(query);
            };
        } catch (e: Dynamic) {
            Context.error('Failed to process from() macro: ' + Std.string(e), Context.currentPos());
            return macro null;
        }
    }
    
    /**
     * Add a where clause with lambda field extraction
     * Validates fields at compile time
     */
    public static macro function where<T>(query: ExprOf<ecto.TypedQuery.TypedQuery<T>>, 
                                          condition: ExprOf<T -> Bool>): ExprOf<ecto.TypedQuery.TypedQuery<T>> {
        // Extract the lambda expression
        var conditionExpr = extractLambdaBody(condition);
        var fieldAccesses = extractFieldAccesses(conditionExpr);
        
        // Validate fields exist in schema
        var classType = getQueryType(query);
        for (field in fieldAccesses) {
            if (!SchemaIntrospection.hasField(classType.name, field)) {
                Context.error('Field "$field" does not exist in ${classType.name}', Context.currentPos());
            }
        }
        
        // Convert to Elixir query syntax
        var elixirCondition = convertToElixirCondition(conditionExpr);
        
        return macro {
            var newQuery = untyped __elixir__(
                '(require Ecto.Query; Ecto.Query.where({0}, [t], {1}))',
                $query.query,
                $v{elixirCondition}
            );
            new ecto.TypedQuery.TypedQuery(newQuery);
        };
    }
    
    /**
     * Add order_by clause with compile-time validation
     * Supports: orderBy(t -> [asc: t.name, desc: t.createdAt])
     */
    public static macro function orderBy<T>(query: ExprOf<ecto.TypedQuery.TypedQuery<T>>,
                                            ordering: ExprOf<T -> Dynamic>): ExprOf<ecto.TypedQuery.TypedQuery<T>> {
        var orderExpr = extractLambdaBody(ordering);
        var orderClauses = parseOrderClauses(orderExpr);
        
        // Validate fields
        var classType = getQueryType(query);
        for (clause in orderClauses) {
            if (!SchemaIntrospection.hasField(classType.name, clause.field)) {
                Context.error('Field "${clause.field}" does not exist in ${classType.name}', Context.currentPos());
            }
        }
        
        // Generate Elixir order_by
        var elixirOrder = orderClauses.map(c -> '${c.direction}: t.${toSnakeCase(c.field)}').join(", ");
        
        return macro {
            var newQuery = untyped __elixir__(
                '(require Ecto.Query; Ecto.Query.order_by({0}, [t], [{1}]))',
                $query.query,
                $v{elixirOrder}
            );
            new ecto.TypedQuery.TypedQuery(newQuery);
        };
    }
    
    /**
     * Select specific fields with type safety
     * Supports: select(t -> {id: t.id, title: t.title})
     */
    public static macro function select<T, R>(query: ExprOf<ecto.TypedQuery.TypedQuery<T>>,
                                              projection: ExprOf<T -> R>): ExprOf<ecto.TypedQuery.TypedQuery<R>> {
        var selectExpr = extractLambdaBody(projection);
        var fields = extractSelectFields(selectExpr);
        
        // Validate fields exist
        var classType = getQueryType(query);
        for (field in fields) {
            if (!SchemaIntrospection.hasField(classType.name, field.source)) {
                Context.error('Field "${field.source}" does not exist in ${classType.name}', Context.currentPos());
            }
        }
        
        // Generate Elixir select map
        var elixirSelect = fields.map(f -> '${f.alias}: t.${toSnakeCase(f.source)}').join(", ");
        
        return macro {
            var newQuery = untyped __elixir__(
                '(require Ecto.Query; Ecto.Query.select({0}, [t], %{{1}}))',
                $query.query,
                $v{elixirSelect}
            );
            new ecto.TypedQuery.TypedQuery(newQuery);
        };
    }
    
    /**
     * Add join clause with association validation
     * Supports: join(t -> t.posts, :left, as: :posts)
     */
    public static macro function join<T>(query: ExprOf<ecto.TypedQuery.TypedQuery<T>>,
                                         association: ExprOf<T -> Dynamic>,
                                         type: ExprOf<ecto.TypedQuery.JoinType>,
                                         ?alias: ExprOf<String>): ExprOf<ecto.TypedQuery.TypedQuery<T>> {
        var assocExpr = extractLambdaBody(association);
        var assocName = extractAssociationName(assocExpr);
        
        // Validate association exists
        var classType = getQueryType(query);
        if (!SchemaIntrospection.hasAssociation(classType.name, assocName)) {
            Context.error('Association "$assocName" does not exist in ${classType.name}', Context.currentPos());
        }
        
        var joinType = getJoinTypeString(type);
        var asClause = alias != null ? macro $alias : macro null;
        
        return macro {
            var newQuery = if ($asClause != null) {
                untyped __elixir__(
                    '(require Ecto.Query; Ecto.Query.join({0}, {1}, [t], assoc in assoc(t, {2}), as: {3}))',
                    $query.query,
                    $v{joinType},
                    $v{toSnakeCase(assocName)},
                    $asClause
                );
            } else {
                untyped __elixir__(
                    '(require Ecto.Query; Ecto.Query.join({0}, {1}, [t], assoc in assoc(t, {2})))',
                    $query.query,
                    $v{joinType},
                    $v{toSnakeCase(assocName)}
                );
            };
            new ecto.TypedQuery.TypedQuery(newQuery);
        };
    }
    
    /**
     * Preload associations with compile-time validation
     */
    public static macro function preload<T>(query: ExprOf<ecto.TypedQuery.TypedQuery<T>>,
                                            associations: ExprOf<Array<String>>): ExprOf<ecto.TypedQuery.TypedQuery<T>> {
        // Extract association names from array
        var assocNames = extractArrayLiterals(associations);
        
        // Validate all associations exist
        var classType = getQueryType(query);
        for (assoc in assocNames) {
            if (!SchemaIntrospection.hasAssociation(classType.name, assoc)) {
                Context.error('Association "$assoc" does not exist in ${classType.name}', Context.currentPos());
            }
        }
        
        // Convert to Elixir atoms
        var elixirAssocs = '[' + assocNames.map(a -> ':${toSnakeCase(a)}').join(", ") + ']';
        
        return macro {
            var newQuery = untyped __elixir__(
                '(require Ecto.Query; Ecto.Query.preload({0}, {1}))',
                $query.query,
                $v{elixirAssocs}
            );
            new ecto.TypedQuery.TypedQuery(newQuery);
        };
    }
    
    // Helper functions
    
    static function getClassType(expr: Expr): ClassType {
        switch(expr.expr) {
            case EConst(CIdent(name)):
                var type = Context.getType(name);
                switch(type) {
                    case TInst(classRef, _):
                        return classRef.get();
                    default:
                        Context.error('Expected class type', expr.pos);
                }
            default:
                Context.error('Expected class identifier', expr.pos);
        }
        return null;
    }
    
    static function getQueryType(expr: Expr): ClassType {
        var type = Context.typeof(expr);
        switch(type) {
            case TAbstract(_, [TInst(classRef, _)]):
                return classRef.get();
            default:
                Context.error('Could not determine query type', expr.pos);
        }
        return null;
    }
    
    static function extractLambdaBody(expr: Expr): Expr {
        switch(expr.expr) {
            case EFunction(_, f):
                return f.expr;
            default:
                Context.error('Expected lambda function', expr.pos);
        }
        return null;
    }
    
    static function extractFieldAccesses(expr: Expr): Array<String> {
        var fields = [];
        
        function traverse(e: Expr) {
            switch(e.expr) {
                case EField(obj, field):
                    // Check if it's accessing the lambda parameter
                    switch(obj.expr) {
                        case EConst(CIdent(_)):
                            fields.push(field);
                        default:
                    }
                default:
            }
            e.iter(traverse);
        }
        
        traverse(expr);
        return fields;
    }
    
    static function toSnakeCase(str: String): String {
        // Convert camelCase to snake_case
        var result = "";
        for (i in 0...str.length) {
            var char = str.charAt(i);
            if (char == char.toUpperCase() && i > 0) {
                result += "_" + char.toLowerCase();
            } else {
                result += char.toLowerCase();
            }
        }
        return result;
    }
    
    static function convertToElixirCondition(expr: Expr): String {
        // Convert Haxe expression to Elixir query condition
        // This is a simplified version - would need expansion for all operators
        switch(expr.expr) {
            case EBinop(OpEq, left, right):
                var leftStr = exprToElixir(left);
                var rightStr = exprToElixir(right);
                return leftStr + " == " + rightStr;
            case EBinop(OpGt, left, right):
                var leftStr = exprToElixir(left);
                var rightStr = exprToElixir(right);
                return leftStr + " > " + rightStr;
            case EBinop(OpLt, left, right):
                var leftStr = exprToElixir(left);
                var rightStr = exprToElixir(right);
                return leftStr + " < " + rightStr;
            case EBinop(OpBoolAnd, left, right):
                var leftStr = convertToElixirCondition(left);
                var rightStr = convertToElixirCondition(right);
                return leftStr + " and " + rightStr;
            case EBinop(OpBoolOr, left, right):
                var leftStr = convertToElixirCondition(left);
                var rightStr = convertToElixirCondition(right);
                return leftStr + " or " + rightStr;
            default:
                return exprToElixir(expr);
        }
    }
    
    static function exprToElixir(expr: Expr): String {
        switch(expr.expr) {
            case EField(obj, field):
                switch(obj.expr) {
                    case EConst(CIdent(_)):
                        return 't.${toSnakeCase(field)}';
                    default:
                        return '${exprToElixir(obj)}.${toSnakeCase(field)}';
                }
            case EConst(CIdent(name)):
                return '^' + name; // Parameter binding
            case EConst(CInt(v)):
                return v;
            case EConst(CString(s, _)):
                return '"$s"';
            default:
                Context.error('Unsupported expression in query', expr.pos);
        }
        return "";
    }
    
    static function parseOrderClauses(expr: Expr): Array<{field: String, direction: String}> {
        var clauses = [];
        
        switch(expr.expr) {
            case EArrayDecl(elements):
                for (elem in elements) {
                    switch(elem.expr) {
                        case EBinop(OpArrow, dirExpr, fieldExpr):
                            var dir = switch(dirExpr.expr) {
                                case EConst(CIdent(d)): d;
                                default: "asc";
                            };
                            var field = extractFieldName(fieldExpr);
                            clauses.push({field: field, direction: dir});
                        default:
                    }
                }
            default:
        }
        
        return clauses;
    }
    
    static function extractFieldName(expr: Expr): String {
        switch(expr.expr) {
            case EField(_, field):
                return field;
            default:
                Context.error('Expected field access', expr.pos);
        }
        return "";
    }
    
    static function extractSelectFields(expr: Expr): Array<{source: String, alias: String}> {
        var fields = [];
        
        switch(expr.expr) {
            case EObjectDecl(fieldExprs):
                for (f in fieldExprs) {
                    var source = extractFieldName(f.expr);
                    fields.push({source: source, alias: f.field});
                }
            default:
        }
        
        return fields;
    }
    
    static function extractAssociationName(expr: Expr): String {
        switch(expr.expr) {
            case EField(_, field):
                return field;
            default:
                Context.error('Expected association field access', expr.pos);
        }
        return "";
    }
    
    static function getJoinTypeString(expr: Expr): String {
        switch(expr.expr) {
            case EConst(CIdent("Left")): return ":left";
            case EConst(CIdent("Right")): return ":right";
            case EConst(CIdent("Inner")): return ":inner";
            case EConst(CIdent("FullOuter")): return ":full_outer";
            default: return ":inner";
        }
    }
    
    static function extractArrayLiterals(expr: Expr): Array<String> {
        switch(expr.expr) {
            case EArrayDecl(elements):
                return elements.map(e -> switch(e.expr) {
                    case EConst(CString(s, _)): s;
                    default: null;
                }).filter(s -> s != null);
            default:
                return [];
        }
    }
}
#end