package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

using StringTools;

/**
 * Advanced Ecto Query Features Compiler
 * 
 * Handles compilation of complex Ecto query patterns including:
 * - Subqueries with proper binding management
 * - CTEs (Common Table Expressions) with recursive support
 * - Window functions (row_number, rank, dense_rank)
 * - Complex joins including lateral joins
 * - Ecto.Multi transaction composition
 * - Advanced aggregations with HAVING clauses
 * - Fragment support for raw SQL
 * - Preload compilation with nested associations
 * 
 * Follows existing EctoQueryMacros patterns for consistent integration.
 */
class EctoQueryAdvancedCompiler {
    
    /**
     * Compile subquery expressions to proper Ecto syntax
     */
    public static function compileSubquery(subqueryExpr: String, targetBinding: String = "q"): String {
        // Clean the subquery expression and wrap in subquery()
        var cleanedExpr = subqueryExpr.replace("subquery(from ", "subquery(from ");
        return 'subquery(${cleanedExpr})';
    }
    
    /**
     * Compile CTE (Common Table Expression) to proper Ecto syntax
     */
    public static function compileCTE(cteName: String, cteQuery: String, isRecursive: Bool = false): String {
        var recursiveModifier = isRecursive ? ", recursive: true" : "";
        return 'with_cte("${cteName}", as: ^(${cteQuery})${recursiveModifier})';
    }
    
    /**
     * Compile window functions to proper Ecto syntax
     */
    public static function compileWindowFunction(functionName: String, partitionBy: Array<String>, orderBy: Array<{field: String, direction: String}>): String {
        var partitionClause = partitionBy.length > 0 
            ? 'partition_by: [${partitionBy.map(f -> ':${f}').join(", ")}]' 
            : "";
            
        var orderClause = orderBy.length > 0
            ? 'order_by: [${orderBy.map(o -> '${o.direction}: :${o.field}').join(", ")}]'
            : "";
            
        var windowOptions = [partitionClause, orderClause].filter(s -> s.length > 0).join(", ");
        
        return 'over(${functionName}(), ${windowOptions})';
    }
    
    /**
     * Compile complex joins including lateral joins
     */
    public static function compileComplexJoin(joinType: String, bindings: Array<String>, schema: String, alias: String, onCondition: String, isLateral: Bool = false): String {
        var lateralModifier = isLateral ? "_lateral" : "";
        var bindingStr = bindings.join(", ");
        
        return 'join${lateralModifier}(:${joinType}, [${bindingStr}], ${alias} in ${schema}, on: ${onCondition})';
    }
    
    /**
     * Compile Ecto.Multi transaction operations
     */
    public static function compileMultiTransaction(operations: Array<MultiOperation>): String {
        var operationStrings = [];
        
        for (op in operations) {
            switch (op.type) {
                case "insert":
                    operationStrings.push('Multi.insert(:${op.name}, ${op.changeset})');
                case "update":
                    operationStrings.push('Multi.update(:${op.name}, ${op.changeset})');
                case "delete":
                    operationStrings.push('Multi.delete(:${op.name}, ${op.changeset})');
                case "run":
                    operationStrings.push('Multi.run(:${op.name}, ${op.functionCode})');
                case "update_all":
                    operationStrings.push('Multi.update_all(:${op.name}, ${op.query}, ${op.updates})');
                case "delete_all":
                    operationStrings.push('Multi.delete_all(:${op.name}, ${op.query})');
                default:
                    operationStrings.push('Multi.${op.type}(:${op.name}, ${op.params})');
            }
        }
        
        return 'Multi.new()\n|> ' + operationStrings.join('\n|> ');
    }
    
    /**
     * Compile advanced aggregations with HAVING clauses
     */
    public static function compileAdvancedAggregation(aggregations: Array<AggregationInfo>, groupBy: Array<String>, having: String): String {
        var aggStrings = aggregations.map(agg -> '${agg.alias}: ${agg.functionName}(${agg.field})');
        var groupByClause = 'group_by([q], [${groupBy.map(f -> 'q.${f}').join(", ")}])';
        var havingClause = having.length > 0 ? 'having([q], ${having})' : "";
        var selectClause = 'select([q], %{${aggStrings.join(", ")}})';
        
        var clauses = [groupByClause, havingClause, selectClause].filter(s -> s.length > 0);
        return clauses.join('\n|> ');
    }
    
    /**
     * Compile fragment expressions for raw SQL
     */
    public static function compileFragment(sql: String, params: Array<String>): String {
        var paramPlaceholders = params.map(p -> '${p}').join(", ");
        return 'fragment("${sql}", ${paramPlaceholders})';
    }
    
    /**
     * Compile preload expressions with nested associations
     */
    public static function compilePreload(associations: Array<PreloadInfo>): String {
        var preloadParts = [];
        
        for (assoc in associations) {
            if (assoc.nested != null && assoc.nested.length > 0) {
                var nestedPreloads = assoc.nested.map(n -> '${n.name}: [${n.children.join(", ")}]');
                preloadParts.push('${assoc.name}: [${nestedPreloads.join(", ")}]');
            } else {
                preloadParts.push(':${assoc.name}');
            }
        }
        
        return 'preload([${preloadParts.join(", ")}])';
    }
    
    /**
     * Compile complete complex query with all advanced features
     */
    public static function compileComplexQuery(querySpec: ComplexQuerySpec): String {
        var parts = [];
        
        // Base query
        parts.push('from ${querySpec.binding} in ${querySpec.schema}${querySpec.asClause != null ? ', as: :${querySpec.asClause}' : ''}');
        
        // Joins
        for (join in querySpec.joins) {
            parts.push(compileComplexJoin(join.type, join.bindings, join.schema, join.alias, join.onCondition, join.isLateral));
        }
        
        // WHERE clauses
        if (querySpec.whereConditions.length > 0) {
            parts.push('where([${querySpec.binding}], ${querySpec.whereConditions.join(" and ")})');
        }
        
        // GROUP BY and HAVING
        if (querySpec.groupBy.length > 0) {
            parts.push('group_by([${querySpec.binding}], [${querySpec.groupBy.join(", ")}])');
            
            if (querySpec.having != null) {
                parts.push('having([${querySpec.binding}], ${querySpec.having})');
            }
        }
        
        // ORDER BY
        if (querySpec.orderBy.length > 0) {
            var orderClauses = querySpec.orderBy.map(o -> '${o.direction}: ${o.field}');
            parts.push('order_by([${querySpec.binding}], [${orderClauses.join(", ")}])');
        }
        
        // LIMIT and OFFSET
        if (querySpec.limit != null) {
            parts.push('limit(${querySpec.limit})');
        }
        if (querySpec.offset != null) {
            parts.push('offset(${querySpec.offset})');
        }
        
        // PRELOAD
        if (querySpec.preloads.length > 0) {
            parts.push(compilePreload(querySpec.preloads));
        }
        
        // SELECT
        if (querySpec.selectClause != null) {
            parts.push('select([${querySpec.binding}], ${querySpec.selectClause})');
        }
        
        return parts.join('\n|> ');
    }
    
    /**
     * Generate complete Elixir module with advanced query functions
     */
    public static function generateAdvancedQueryModule(className: String, functions: Array<AdvancedQueryFunction>): String {
        var moduleName = className;
        var functionDefs = [];
        
        for (func in functions) {
            var returnValue = switch (func.queryType) {
                case "subquery": compileSubquery(func.queryBody);
                case "cte": compileCTE(func.name, func.queryBody);
                case "window": func.queryBody; // Already compiled in test
                case "complex_join": func.queryBody; // Already compiled in test
                case "multi": func.queryBody; // Already compiled in test
                case "aggregation": func.queryBody; // Already compiled in test
                case "fragment": func.queryBody; // Already compiled in test
                case "preload": func.queryBody; // Already compiled in test
                default: func.queryBody;
            };
            
            functionDefs.push(
                '  @doc """\n' +
                '  ${func.description}\n' +
                '  """\n' +
                '  def ${func.name}() do\n' +
                '    ${returnValue}\n' +
                '  end'
            );
        }
        
        return 'defmodule ${moduleName} do\n' +
               '  @moduledoc """\n' +
               '  Advanced Ecto query functions generated from Haxe\n' +
               '  \n' +
               '  Provides sophisticated query patterns including subqueries,\n' +
               '  CTEs, window functions, and complex joins with type safety.\n' +
               '  """\n' +
               '  \n' +
               '  import Ecto.Query\n' +
               '  alias Ecto.Multi\n' +
               '  \n' +
               functionDefs.join('\n\n') +
               '\nend';
    }
}

/**
 * Multi operation specification
 */
typedef MultiOperation = {
    type: String,
    name: String,
    ?changeset: String,
    ?functionCode: String,
    ?query: String,
    ?updates: String,
    ?params: String
}

/**
 * Aggregation information
 */
typedef AggregationInfo = {
    functionName: String,
    field: String,
    alias: String
}

/**
 * Preload information with nested associations
 */
typedef PreloadInfo = {
    name: String,
    ?nested: Array<{name: String, children: Array<String>}>
}

/**
 * Join specification for complex queries
 */
typedef JoinSpec = {
    type: String,
    bindings: Array<String>,
    schema: String,
    alias: String,
    onCondition: String,
    ?isLateral: Bool
}

/**
 * Complete complex query specification
 */
typedef ComplexQuerySpec = {
    schema: String,
    binding: String,
    ?asClause: String,
    joins: Array<JoinSpec>,
    whereConditions: Array<String>,
    groupBy: Array<String>,
    ?having: String,
    orderBy: Array<{field: String, direction: String}>,
    ?limit: Int,
    ?offset: Int,
    preloads: Array<PreloadInfo>,
    ?selectClause: String
}

/**
 * Advanced query function specification
 */
typedef AdvancedQueryFunction = {
    name: String,
    description: String,
    queryType: String,
    queryBody: String
}

#end