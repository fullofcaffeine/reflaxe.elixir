package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

/**
 * Advanced Ecto Query Compiler
 * 
 * Handles complex query compilation including:
 * - Joins (inner, left, right, cross)
 * - Aggregations (sum, avg, count, min, max)
 * - Subqueries and CTEs
 * - Window functions
 * - Fragments for raw SQL
 * - Preloading and associations
 * 
 * Follows established ElixirCompiler helper delegation pattern.
 */
class QueryCompiler {
    
    /**
     * Compile join operations for Ecto queries
     */
    public static function compileJoin(type: String, binding: String, schema: String, onCondition: String): String {
        // Handle null or empty type gracefully
        var safeType = type != null ? type : "inner";
        
        var joinType = switch(safeType.toLowerCase()) {
            case "inner": "join";
            case "left": "left_join";
            case "right": "right_join";
            case "cross": "cross_join";
            case "inner_lateral": "join_lateral";
            case "left_lateral": "left_join_lateral";
            default: "join";
        };
        
        return '|> ${joinType}(:${safeType.toLowerCase()}, ${binding}, ${schema}, on: ${onCondition})';
    }
    
    /**
     * Compile multiple joins with proper binding management
     */
    public static function compileMultipleJoins(joins: Array<JoinDefinition>): String {
        var output = new StringBuf();
        var currentBindings = ["q"]; // Start with the main query binding
        
        for (join in joins) {
            var newBinding = generateBinding(join.alias);
            currentBindings.push(newBinding);
            
            var bindingList = "[" + currentBindings.join(", ") + "]";
            var onClause = compileOnClause(join.on, currentBindings);
            
            output.add('\n|> join(:${join.type}, ${bindingList}, ${newBinding} in ${join.schema}, on: ${onClause})');
        }
        
        return output.toString();
    }
    
    /**
     * Compile aggregation functions
     */
    public static function compileAggregation(func: String, field: String, binding: String = "q"): String {
        // Handle null function gracefully
        var safeFunc = func != null ? func : "count";
        
        return switch(safeFunc.toLowerCase()) {
            case "count": 'count(${binding}.${field})';
            case "sum": 'sum(${binding}.${field})';
            case "avg": 'avg(${binding}.${field})';
            case "max": 'max(${binding}.${field})';
            case "min": 'min(${binding}.${field})';
            case "count_distinct": 'count(${binding}.${field}, :distinct)';
            default: 'count(*)';
        };
    }
    
    /**
     * Compile GROUP BY clause with HAVING support
     */
    public static function compileGroupBy(fields: Array<String>, havingClause: Null<String> = null): String {
        var output = new StringBuf();
        
        // GROUP BY
        var groupFields = fields.map(f -> 'q.${f}').join(", ");
        output.add('|> group_by([q], [${groupFields}])');
        
        // HAVING clause if present
        if (havingClause != null) {
            output.add('\n|> having([q], ${havingClause})');
        }
        
        return output.toString();
    }
    
    /**
     * Compile subquery
     */
    public static function compileSubquery(subquery: String, alias: String): String {
        return 'subquery(from ${alias} in (${subquery}), select: ${alias})';
    }
    
    /**
     * Compile CTE (Common Table Expression)
     */
    public static function compileCTE(name: String, query: String): String {
        return 'with_cte("${name}", as: ^${query})';
    }
    
    /**
     * Compile window function
     */
    public static function compileWindowFunction(func: String, partitionBy: Null<String> = null, orderBy: Null<String> = null): String {
        var output = new StringBuf();
        // Handle null or empty function gracefully
        var safeFunc = (func != null && func != "") ? func : "row_number";
        output.add('over(${safeFunc}()');
        
        var options = [];
        if (partitionBy != null) {
            options.push('partition_by: ${partitionBy}');
        }
        if (orderBy != null) {
            options.push('order_by: ${orderBy}');
        }
        
        if (options.length > 0) {
            output.add(', ');
            output.add(options.join(", "));
        }
        
        output.add(')');
        return output.toString();
    }
    
    /**
     * Compile Ecto.Multi transaction
     */
    public static function compileMulti(operations: Array<MultiOperation>): String {
        var output = new StringBuf();
        output.add('Multi.new()');
        
        for (op in operations) {
            var opResult = switch(op.type) {
                case "insert":
                    'Multi.insert(:${op.name}, ${op.changeset})';
                case "update":
                    'Multi.update(:${op.name}, ${op.changeset})';
                case "delete":
                    'Multi.delete(:${op.name}, ${op.record})';
                case "run":
                    'Multi.run(:${op.name}, fn repo, changes -> ${op.funcStr} end)';
                case "merge":
                    'Multi.merge(fn changes -> ${op.funcStr} end)';
                case "update_all":
                    'Multi.update_all(:${op.name}, ${op.query}, ${op.updates})';
                case "delete_all":
                    'Multi.delete_all(:${op.name}, ${op.query})';
                default:
                    null; // Skip invalid operations
            };
            
            // Only add valid operations
            if (opResult != null) {
                output.add('\n|> ');
                output.add(opResult);
            }
        }
        
        return output.toString();
    }
    
    /**
     * Compile fragment for raw SQL
     */
    public static function compileFragment(sql: String, params: Array<String>): String {
        var paramList = params.length > 0 ? ", " + params.join(", ") : "";
        return 'fragment("${sql}"${paramList})';
    }
    
    /**
     * Compile preload with nested associations
     */
    public static function compilePreload(associations: PreloadDefinition): String {
        return '|> preload(${formatPreloadList(associations)})';
    }
    
    /**
     * Compile named bindings for complex queries
     */
    public static function compileNamedBindings(bindings: Map<String, String>): String {
        var output = [];
        for (name => schema in bindings) {
            output.push('${name}: ${schema}');
        }
        return "[" + output.join(", ") + "]";
    }
    
    /**
     * Compile a complete complex query
     */
    public static function compileComplexQuery(query: ComplexQueryDefinition): String {
        var output = new StringBuf();
        
        // FROM clause
        output.add('from ${query.binding} in ${query.schema}');
        if (query.alias != null) {
            output.add(', as: :${query.alias}');
        }
        
        // JOINs
        if (query.joins != null && query.joins.length > 0) {
            output.add(compileMultipleJoins(query.joins));
        }
        
        // WHERE clause
        if (query.where != null) {
            output.add('\n|> where([${query.binding}], ${query.where})');
        }
        
        // GROUP BY
        if (query.groupBy != null && query.groupBy.length > 0) {
            output.add('\n' + compileGroupBy(query.groupBy, query.having));
        }
        
        // ORDER BY
        if (query.orderBy != null && query.orderBy.length > 0) {
            var orderFields = query.orderBy.map(o -> '${o.direction}: ${query.binding}.${o.field}').join(", ");
            output.add('\n|> order_by([${query.binding}], [${orderFields}])');
        }
        
        // LIMIT and OFFSET
        if (query.limit != null) {
            output.add('\n|> limit(${query.limit})');
        }
        if (query.offset != null) {
            output.add('\n|> offset(${query.offset})');
        }
        
        // PRELOAD
        if (query.preload != null) {
            output.add('\n' + compilePreload(query.preload));
        }
        
        // SELECT
        if (query.select != null) {
            output.add('\n|> select([${query.binding}], ${query.select})');
        }
        
        return output.toString();
    }
    
    // Helper functions
    
    private static function generateBinding(alias: String): String {
        // Generate a binding variable from an alias
        return alias != null ? alias.charAt(0).toLowerCase() : "x";
    }
    
    private static function compileOnClause(condition: String, bindings: Array<String>): String {
        // Parse and compile the ON clause for joins
        // This is simplified - real implementation would parse the condition properly
        return condition;
    }
    
    private static function formatPreloadList(preload: PreloadDefinition): String {
        if (preload.simple != null && preload.simple.length > 0) {
            return "[" + preload.simple.map(s -> ':${s}').join(", ") + "]";
        }
        
        if (preload.nested != null) {
            var items = [];
            for (key => value in preload.nested) {
                if (value.length > 0) {
                    items.push('${key}: [' + value.map(v -> ':${v}').join(", ") + ']');
                } else {
                    items.push('${key}: []');
                }
            }
            return "[" + items.join(", ") + "]";
        }
        
        if (preload.custom != null) {
            return preload.custom;
        }
        
        return "[]";
    }
    
    /**
     * Performance optimization: batch compile multiple queries
     */
    public static function batchCompileQueries(queries: Array<ComplexQueryDefinition>): Array<String> {
        var startTime = Sys.time();
        var results = [];
        
        for (query in queries) {
            results.push(compileComplexQuery(query));
        }
        
        var totalTime = Sys.time() - startTime;
        if (totalTime > 0.015) { // 15ms performance target
            trace('Warning: Query compilation took ${totalTime * 1000}ms, exceeding 15ms target');
        }
        
        return results;
    }
    
    /**
     * Compile lateral join for advanced join scenarios
     */
    public static function compileLateralJoin(binding: String, schema: String, onCondition: String): String {
        return '|> join_lateral(:inner, ${binding}, ${schema}, on: ${onCondition})';
    }
    
    /**
     * Compile union/union_all operations for combining queries
     */
    public static function compileUnion(query1: String, query2: String, unionAll: Bool = false): String {
        var unionType = unionAll ? "union_all" : "union";
        return '${query1}\n|> ${unionType}(${query2})';
    }
    
    /**
     * Compile with_recursive for recursive CTEs
     */
    public static function compileRecursiveCTE(name: String, baseQuery: String, recursiveQuery: String): String {
        return 'with_recursive(\"${name}\", as: ^(${baseQuery} |> union_all(${recursiveQuery})))';
    }
    
    /**
     * Compile advanced CASE expressions
     */
    public static function compileCaseExpression(conditions: Array<{condition: String, result: String}>, elseResult: String = "nil"): String {
        var output = new StringBuf();
        output.add('case do\n');
        
        for (cond in conditions) {
            output.add('  ${cond.condition} -> ${cond.result}\n');
        }
        
        output.add('  true -> ${elseResult}\n');
        output.add('end');
        
        return output.toString();
    }
    
    /**
     * Compile COALESCE function for null handling
     */
    public static function compileCoalesce(fields: Array<String>): String {
        return 'coalesce(${fields.join(", ")})';
    }
    
    /**
     * Compile JSON operations for PostgreSQL
     */
    public static function compileJsonPath(field: String, path: String): String {
        return 'json_extract_path(${field}, ${path})';
    }
    
    /**
     * Compile array operations
     */
    public static function compileArrayOperation(field: String, operation: String, value: String): String {
        return switch(operation.toLowerCase()) {
            case "contains": '${value} = any(${field})';
            case "contained_by": '${field} <@ array[${value}]';
            case "overlap": '${field} && array[${value}]';
            case "length": 'array_length(${field}, 1)';
            default: '${field} ${operation} ${value}';
        };
    }
}

// Type definitions

typedef JoinDefinition = {
    type: String,
    schema: String,
    alias: String,
    on: String
}

typedef MultiOperation = {
    type: String,
    name: String,
    ?changeset: String,
    ?record: String,
    ?query: String,
    ?updates: String,
    ?funcStr: String
}

typedef PreloadDefinition = {
    ?simple: Array<String>,
    ?nested: Map<String, Array<String>>,
    ?custom: String
}

typedef ComplexQueryDefinition = {
    schema: String,
    binding: String,
    ?alias: String,
    ?joins: Array<JoinDefinition>,
    ?where: String,
    ?groupBy: Array<String>,
    ?having: String,
    ?orderBy: Array<{field: String, direction: String}>,
    ?limit: Int,
    ?offset: Int,
    ?preload: PreloadDefinition,
    ?select: String
}

#end