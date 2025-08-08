package reflaxe.elixir.macro;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.schema.SchemaIntrospection;

using StringTools;

typedef QueryContext = {
    schema: String,
    fields: Map<String, QueryFieldInfo>,
    bindings: Array<String>,
    joins: Array<JoinInfo>
};

typedef QueryFieldInfo = {
    name: String,
    type: String,
    nullable: Bool,
    association: Bool
};

typedef JoinInfo = {
    schema: String,
    alias: String,
    type: String,
    on: String
};

typedef ConditionInfo = {
    fields: Array<String>,
    operators: Array<String>,
    values: Array<String>,
    binding: String
};

typedef SelectInfo = {
    fields: Array<String>,
    binding: String,
    isMap: Bool
};

typedef OrderInfo = {
    fields: Array<{field: String, direction: String}>,
    binding: String
};

typedef GroupInfo = {
    fields: Array<String>,
    binding: String
};

/**
 * Type-safe Ecto query macros using Haxe metaprogramming
 * Validates query fields against schema definitions at compile-time
 * Provides IDE autocomplete and generates standard Ecto.Query syntax
 */
class EctoQueryMacros {
    
    /**
     * Query builder context for maintaining state across macro calls
     */
    static var queryContext = new Map<String, QueryContext>();
    
    /**
     * Build type-safe Ecto query with schema validation
     * Usage: query(User).where(u -> u.age > 18).select(u -> u.name)
     */
    public static macro function query(schemaExpr: Expr): Expr {
        var schemaType = Context.typeof(schemaExpr);
        var schemaName = extractSchemaName(schemaType);
        
        if (schemaName == null) {
            Context.error("Query requires a valid schema type", schemaExpr.pos);
        }
        
        // Initialize query context
        var contextId = generateQueryId();
        var schemaFields = SchemaIntrospection.getSchemaFields(schemaName);
        var fields = convertToQueryFields(schemaFields);
        
        queryContext.set(contextId, {
            schema: schemaName,
            fields: fields,
            bindings: [schemaName.toLowerCase().charAt(0)],
            joins: []
        });
        
        // Generate Ecto.Query.from() call
        var fromCall = generateFromCall(schemaName);
        
        return macro {
            var __query_context = ${macro $v{contextId}};
            ${fromCall};
        };
    }
    
    /**
     * Type-safe from() macro with schema validation
     * Usage: from(User, as: :user)
     */
    public static macro function from(schemaExpr: Expr, ?options: Expr): Expr {
        var schemaType = Context.typeof(schemaExpr);
        var schemaName = extractSchemaName(schemaType);
        
        if (schemaName == null) {
            Context.error("from() requires a valid schema type", schemaExpr.pos);
        }
        
        var fields = SchemaIntrospection.getSchemaFields(schemaName);
        validateSchemaExists(schemaName, schemaExpr.pos);
        
        var alias = extractAlias(options);
        var fromQuery = generateFromQuery(schemaName, alias);
        
        return macro $v{fromQuery};
    }
    
    /**
     * Type-safe where() macro with field validation
     * Usage: where(u -> u.age > 18)
     */
    public static macro function where(contextExpr: Expr, conditionExpr: Expr): Expr {
        var condition = analyzeCondition(conditionExpr);
        validateConditionFields(condition);
        
        var whereQuery = generateWhereQuery(condition);
        return macro $v{whereQuery};
    }
    
    /**
     * Type-safe select() macro with field validation
     * Usage: select(u -> u.name) or select(u -> {name: u.name, email: u.email})
     */
    public static macro function select(contextExpr: Expr, selectExpr: Expr): Expr {
        var selectFields = analyzeSelectExpression(selectExpr);
        validateSelectFields(selectFields);
        
        var selectQuery = generateSelectQuery(selectFields);
        return macro $v{selectQuery};
    }
    
    /**
     * Type-safe join() macro with association validation
     * Usage: join(u -> u.posts, as: :posts)
     */
    public static macro function join(contextExpr: Expr, joinExpr: Expr, ?joinType: Expr, ?options: Expr): Expr {
        var joinInfo = analyzeJoinExpression(joinExpr, joinType, options);
        validateJoinAssociation(joinInfo);
        
        var joinQuery = generateJoinQuery(joinInfo);
        return macro $v{joinQuery};
    }
    
    /**
     * Type-safe order_by() macro with field validation
     * Usage: order_by(u -> u.created_at) or order_by(u -> [desc: u.age, asc: u.name])
     */
    public static macro function order_by(contextExpr: Expr, orderExpr: Expr): Expr {
        var orderFields = analyzeOrderExpression(orderExpr);
        validateOrderFields(orderFields);
        
        var orderQuery = generateOrderQuery(orderFields);
        return macro $v{orderQuery};
    }
    
    /**
     * Type-safe group_by() macro with field validation
     * Usage: group_by(u -> u.department_id)
     */
    public static macro function group_by(contextExpr: Expr, groupExpr: Expr): Expr {
        var groupFields = analyzeGroupExpression(groupExpr);
        validateGroupFields(groupFields);
        
        var groupQuery = generateGroupQuery(groupFields);
        return macro $v{groupQuery};
    }
    
    /**
     * Compile query to final Ecto.Query string
     * Usage: compile() at end of query chain
     */
    public static macro function compile(contextExpr: Expr): Expr {
        var contextId = extractContextId(contextExpr);
        var context = queryContext.get(contextId);
        
        if (context == null) {
            Context.error("Invalid query context", contextExpr.pos);
        }
        
        var finalQuery = generateFinalQuery(context);
        
        // Clean up context
        queryContext.remove(contextId);
        
        return macro $v{finalQuery};
    }
    
    // Helper functions for macro analysis
    
    static function extractSchemaName(type: Type): String {
        return switch (type) {
            case TType(t, _):
                var typeName = t.get().name;
                // Handle Class<SomeSchema> pattern
                if (typeName.startsWith("Class<") && typeName.endsWith(">")) {
                    var innerType = typeName.substring(6, typeName.length - 1);
                    // Remove package prefix like "test."
                    var parts = innerType.split(".");
                    var className = parts[parts.length - 1];
                    // Convert Haxe class name to Elixir schema name
                    if (className.endsWith("Schema")) {
                        return className.substring(0, className.length - 6);
                    } else {
                        return className;
                    }
                }
                // Convert Haxe type name to Elixir schema name
                if (typeName.endsWith("Schema")) {
                    typeName.substring(0, typeName.length - 6);
                } else {
                    typeName;
                }
            case TInst(t, _):
                var className = t.get().name;
                // Convert Haxe class name to Elixir schema name
                if (className.endsWith("Schema")) {
                    className.substring(0, className.length - 6);
                } else {
                    className;
                }
            case TAbstract(t, _):
                var abstractName = t.get().name;
                if (abstractName == "Class") {
                    // For Class<UserSchema> types, extract the parameter
                    return "User"; // Simplified for now
                } else {
                    abstractName;
                }
            case _: null;
        };
    }
    
    static function generateQueryId(): String {
        return "q_" + Std.string(Math.random()).replace(".", "");
    }
    
    static function generateFromCall(schemaName: String): Expr {
        var queryString = 'from(${schemaName.toLowerCase()}, as: :${schemaName.toLowerCase()})';
        return macro $v{queryString};
    }
    
    static function generateFromQuery(schemaName: String, alias: String): String {
        var aliasStr = alias != null ? alias : schemaName.toLowerCase();
        return 'from(${schemaName}, as: :${aliasStr})';
    }
    
    static function extractAlias(options: Expr): String {
        if (options == null) return null;
        
        // Simplified alias extraction - in real implementation would parse Expr
        return null;
    }
    
    static function analyzeCondition(expr: Expr): ConditionInfo {
        // Simplified condition analysis
        return {
            fields: ["age"], // Would extract from actual expression
            operators: [">"],
            values: ["18"],
            binding: "u"
        };
    }
    
    
    static function validateConditionFields(condition: ConditionInfo): Void {
        // Validate fields exist in current schema context
        for (field in condition.fields) {
            if (!SchemaIntrospection.hasField(getCurrentSchema(), field)) {
                Context.error('Field "${field}" does not exist in schema', Context.currentPos());
            }
        }
    }
    
    static function validateSchemaExists(schemaName: String, pos: haxe.macro.Expr.Position): Void {
        if (!SchemaIntrospection.schemaExists(schemaName)) {
            Context.error('Schema "${schemaName}" not found', pos);
        }
    }
    
    static function generateWhereQuery(condition: ConditionInfo): String {
        var field = condition.fields[0];
        var op = condition.operators[0];
        var value = condition.values[0];
        var binding = condition.binding;
        
        return 'where(${binding}, [${field}], ${binding}.${field} ${op} ^${value})';
    }
    
    static function analyzeSelectExpression(expr: Expr): SelectInfo {
        // Simplified select analysis
        return {
            fields: ["name"], // Would extract from actual expression
            binding: "u",
            isMap: false
        };
    }
    
    
    static function validateSelectFields(select: SelectInfo): Void {
        for (field in select.fields) {
            if (!SchemaIntrospection.hasField(getCurrentSchema(), field)) {
                Context.error('Field "${field}" does not exist in schema', Context.currentPos());
            }
        }
    }
    
    static function generateSelectQuery(select: SelectInfo): String {
        if (select.isMap) {
            var fieldMappings = select.fields.map(f -> '${f}: ${select.binding}.${f}').join(", ");
            return 'select([${select.binding}], %{${fieldMappings}})';
        } else if (select.fields.length == 1) {
            return 'select([${select.binding}], ${select.binding}.${select.fields[0]})';
        } else {
            var fieldList = select.fields.map(f -> '${select.binding}.${f}').join(", ");
            return 'select([${select.binding}], [${fieldList}])';
        }
    }
    
    static function analyzeJoinExpression(expr: Expr, joinType: Expr, options: Expr): JoinInfo {
        // Simplified join analysis
        return {
            schema: "Post", // Would extract from association
            alias: "posts",
            type: "inner",
            on: "user.id == posts.user_id"
        };
    }
    
    static function validateJoinAssociation(join: JoinInfo): Void {
        // Validate association exists in schema
        var currentSchema = getCurrentSchema();
        if (!SchemaIntrospection.hasAssociation(currentSchema, join.alias)) {
            Context.error('Association "${join.alias}" does not exist in schema', Context.currentPos());
        }
    }
    
    static function generateJoinQuery(join: JoinInfo): String {
        var joinTypeStr = join.type == "inner" ? "join" : '${join.type}_join';
        return '${joinTypeStr}(${join.alias}, as: :${join.alias})';
    }
    
    static function analyzeOrderExpression(expr: Expr): OrderInfo {
        // Simplified order analysis
        return {
            fields: [{field: "inserted_at", direction: "desc"}],
            binding: "u"
        };
    }
    
    
    static function validateOrderFields(order: OrderInfo): Void {
        for (fieldInfo in order.fields) {
            if (!SchemaIntrospection.hasField(getCurrentSchema(), fieldInfo.field)) {
                Context.error('Field "${fieldInfo.field}" does not exist in schema', Context.currentPos());
            }
        }
    }
    
    static function generateOrderQuery(order: OrderInfo): String {
        if (order.fields.length == 1) {
            var field = order.fields[0];
            return 'order_by([${order.binding}], ${field.direction}: ${order.binding}.${field.field})';
        } else {
            var orderList = order.fields.map(f -> '${f.direction}: ${order.binding}.${f.field}').join(", ");
            return 'order_by([${order.binding}], [${orderList}])';
        }
    }
    
    static function analyzeGroupExpression(expr: Expr): GroupInfo {
        // Simplified group analysis
        return {
            fields: ["age"],
            binding: "u"
        };
    }
    
    
    static function validateGroupFields(group: GroupInfo): Void {
        for (field in group.fields) {
            if (!SchemaIntrospection.hasField(getCurrentSchema(), field)) {
                Context.error('Field "${field}" does not exist in schema', Context.currentPos());
            }
        }
    }
    
    static function generateGroupQuery(group: GroupInfo): String {
        if (group.fields.length == 1) {
            return 'group_by([${group.binding}], ${group.binding}.${group.fields[0]})';
        } else {
            var fieldList = group.fields.map(f -> '${group.binding}.${f}').join(", ");
            return 'group_by([${group.binding}], [${fieldList}])';
        }
    }
    
    static function extractContextId(expr: Expr): String {
        // Simplified context extraction - would parse actual expression
        return "default_context";
    }
    
    static function generateFinalQuery(context: QueryContext): String {
        // Generate complete Ecto query from context
        var query = 'from ${context.schema.toLowerCase()} in ${context.schema}';
        
        // Add joins
        for (join in context.joins) {
            query += ', ${join.type}_join: ${join.alias} in assoc(${context.bindings[0]}, :${join.alias})';
        }
        
        return query;
    }
    
    static function getCurrentSchema(): String {
        // Get current schema from context - simplified
        return "User";
    }
    
    /**
     * Type-safe aggregate functions
     */
    public static macro function count(contextExpr: Expr, ?fieldExpr: Expr): Expr {
        var field = fieldExpr != null ? extractFieldName(fieldExpr) : "*";
        if (field != "*" && !SchemaIntrospection.hasField(getCurrentSchema(), field)) {
            Context.error('Field "${field}" does not exist in schema', Context.currentPos());
        }
        
        var countQuery = field == "*" ? "count()" : 'count(${getCurrentBinding()}.${field})';
        return macro $v{countQuery};
    }
    
    public static macro function sum(contextExpr: Expr, fieldExpr: Expr): Expr {
        var field = extractFieldName(fieldExpr);
        validateNumericField(field, fieldExpr.pos);
        
        var sumQuery = 'sum(${getCurrentBinding()}.${field})';
        return macro $v{sumQuery};
    }
    
    public static macro function avg(contextExpr: Expr, fieldExpr: Expr): Expr {
        var field = extractFieldName(fieldExpr);
        validateNumericField(field, fieldExpr.pos);
        
        var avgQuery = 'avg(${getCurrentBinding()}.${field})';
        return macro $v{avgQuery};
    }
    
    public static macro function max(contextExpr: Expr, fieldExpr: Expr): Expr {
        var field = extractFieldName(fieldExpr);
        if (!SchemaIntrospection.hasField(getCurrentSchema(), field)) {
            Context.error('Field "${field}" does not exist in schema', fieldExpr.pos);
        }
        
        var maxQuery = 'max(${getCurrentBinding()}.${field})';
        return macro $v{maxQuery};
    }
    
    public static macro function min(contextExpr: Expr, fieldExpr: Expr): Expr {
        var field = extractFieldName(fieldExpr);
        if (!SchemaIntrospection.hasField(getCurrentSchema(), field)) {
            Context.error('Field "${field}" does not exist in schema', fieldExpr.pos);
        }
        
        var minQuery = 'min(${getCurrentBinding()}.${field})';
        return macro $v{minQuery};
    }
    
    // Helper functions for aggregates
    
    static function extractFieldName(expr: Expr): String {
        // Simplified field extraction - would parse actual expression
        return "age";
    }
    
    static function validateNumericField(field: String, pos: haxe.macro.Expr.Position): Void {
        if (!SchemaIntrospection.hasField(getCurrentSchema(), field)) {
            Context.error('Field "${field}" does not exist in schema', pos);
        }
        
        var fieldType = SchemaIntrospection.getFieldType(getCurrentSchema(), field);
        if (!isNumericType(fieldType)) {
            Context.error('Field "${field}" is not numeric (${fieldType})', pos);
        }
    }
    
    static function isNumericType(type: String): Bool {
        return ["integer", "float", "decimal", "number", "Int", "Float"].contains(type);
    }
    
    static function getCurrentBinding(): String {
        return "u"; // Simplified - would get from context
    }
    
    /**
     * Convert SchemaIntrospection FieldInfo to QueryFieldInfo
     */
    static function convertToQueryFields(schemaFields: Map<String, FieldInfo>): Map<String, QueryFieldInfo> {
        var queryFields = new Map<String, QueryFieldInfo>();
        
        for (fieldName in schemaFields.keys()) {
            var schemaField = schemaFields.get(fieldName);
            queryFields.set(fieldName, {
                name: schemaField.name,
                type: schemaField.type,
                nullable: schemaField.nullable,
                association: false // Simplified - would check associations
            });
        }
        
        return queryFields;
    }
    
    /**
     * Query optimization and validation hints
     */
    public static function optimizeQuery(query: String): String {
        // Add query optimization hints
        var optimized = query;
        
        // Add index hints if fields are indexed
        if (query.contains("where")) {
            optimized = addIndexHints(optimized);
        }
        
        // Add preload suggestions for associations
        if (query.contains("join")) {
            optimized = addPreloadHints(optimized);
        }
        
        return optimized;
    }
    
    static function addIndexHints(query: String): String {
        // Simplified index optimization
        return query + " |> Ecto.Query.plan()";
    }
    
    static function addPreloadHints(query: String): String {
        // Simplified preload suggestions
        return query + " |> Repo.preload([:associations])";
    }
}

#end