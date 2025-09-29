package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.ElixirASTDef;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.EPattern;
import reflaxe.elixir.ast.ElixirAST.EBinaryOp;
import reflaxe.elixir.CompilationContext;
import reflaxe.elixir.ast.analyzers.VariableAnalyzer;
import reflaxe.elixir.ast.NameUtils;

/**
 * ObjectBuilder: Handles object declaration compilation
 * 
 * WHY: Centralizes complex object pattern detection from ElixirASTBuilder
 * - Extracts ~250 lines of object-to-map transformation logic
 * - Handles tuple patterns, supervisor options, child specs
 * - Manages null coalescing in field values
 * - Detects and transforms special OTP patterns
 * 
 * WHAT: Transforms Haxe TObjectDecl to appropriate Elixir structures
 * - Anonymous objects with _1, _2 fields → Tuples
 * - Supervisor option objects → Keyword lists
 * - Child spec objects → Maps with special handling
 * - Regular objects → Maps with snake_case keys
 * - Null coalescing patterns in field values
 * 
 * HOW: Pattern detection and targeted transformation
 * - Detect tuple patterns by field naming (_1, _2, etc.)
 * - Identify supervisor options by characteristic fields
 * - Recognize child specs by id/start fields
 * - Transform field names from camelCase to snake_case
 * - Handle null coalescing in field expressions
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused on object transformations
 * - Open/Closed: Easy to add new object patterns
 * - Testability: Object patterns testable independently
 * - Maintainability: ~250 lines extracted to focused module
 * - Performance: Pattern detection optimized in one place
 * 
 * EDGE CASES:
 * - Empty objects → Empty maps
 * - Tuple-like objects → Proper tuple ordering
 * - Nested objects → Recursive transformation
 * - Variable renaming → Uses tempVarRenameMap
 * - Null coalescing → Inline if expressions
 */
@:nullSafety(Off)
class ObjectBuilder {
    
    /**
     * Build object declaration with pattern detection
     * 
     * WHY: Objects in Haxe map to different Elixir structures based on usage
     * WHAT: Detects patterns and generates appropriate Elixir structure
     * HOW: Multi-phase pattern detection with priority ordering
     * 
     * @param fields Object field declarations
     * @param context Compilation context
     * @return ElixirASTDef for the object or transformed structure
     */
    public static function build(fields: Array<{name: String, expr: TypedExpr}>, context: CompilationContext): Null<ElixirASTDef> {
        #if debug_ast_builder
        trace('[ObjectBuilder] Building object with ${fields.length} fields');
        for (field in fields) {
            trace('[ObjectBuilder]   Field "${field.name}" expr type: ${Type.enumConstructor(field.expr.expr)}');
        }
        #end
        
        // ====================================================================
        // PATTERN 1: Tuple Pattern (Anonymous structure with _1, _2, etc.)
        // ====================================================================
        if (isTuplePattern(fields)) {
            #if debug_ast_builder
            trace('[ObjectBuilder] ✓ Detected tuple pattern, generating Elixir tuple');
            #end
            return buildTuple(fields, context);
        }
        
        // ====================================================================
        // PATTERN 2: Supervisor Options (strategy, max_restarts, max_seconds)
        // ====================================================================
        if (isSupervisorOptions(fields)) {
            #if debug_ast_builder
            trace('[ObjectBuilder] ✓ Detected supervisor options, generating keyword list');
            #end
            return buildSupervisorOptions(fields, context);
        }
        
        // ====================================================================
        // PATTERN 3: Child Spec (id, start, type, etc.)
        // ====================================================================
        if (isChildSpec(fields)) {
            #if debug_ast_builder
            trace('[ObjectBuilder] ✓ Detected child spec, generating map with special handling');
            #end
            return buildChildSpec(fields, context);
        }
        
        // ====================================================================
        // DEFAULT: Regular Object → Map
        // ====================================================================
        #if debug_ast_builder
        trace('[ObjectBuilder] Building as regular map');
        #end
        return buildRegularMap(fields, context);
    }
    
    /**
     * Check if fields represent a tuple pattern
     * 
     * WHY: Anonymous objects with _1, _2 fields are Haxe's tuple representation
     * WHAT: Checks if all fields follow _N naming pattern
     * HOW: Regex matching on field names
     */
    static function isTuplePattern(fields: Array<{name: String, expr: TypedExpr}>): Bool {
        if (fields.length == 0) return false;
        
        for (field in fields) {
            if (!~/^_\d+$/.match(field.name)) {
                return false;
            }
        }
        return true;
    }
    
    /**
     * Build tuple from ordered fields
     * 
     * WHY: Tuples need elements in correct numerical order
     * WHAT: Sorts fields by index and builds tuple
     * HOW: Parse indices from field names and sort
     */
    static function buildTuple(fields: Array<{name: String, expr: TypedExpr}>, context: CompilationContext): ElixirASTDef {
        // Sort fields by index to ensure correct order
        var sortedFields = fields.copy();
        sortedFields.sort(function(a, b) {
            var aIndex = Std.parseInt(a.name.substr(1));
            var bIndex = Std.parseInt(b.name.substr(1));
            return aIndex - bIndex;
        });
        
        // Build tuple elements in order
        var tupleElements = [];
        for (field in sortedFields) {
            tupleElements.push(context.compiler.compileExpressionImpl(field.expr, false));
        }
        
        return ETuple(tupleElements);
    }
    
    /**
     * Check if fields represent supervisor options
     * 
     * WHY: Supervisor options need keyword list format for OTP
     * WHAT: Detects characteristic supervisor option fields
     * HOW: Check for strategy and restart fields
     */
    static function isSupervisorOptions(fields: Array<{name: String, expr: TypedExpr}>): Bool {
        var hasStrategy = false;
        var hasMaxRestarts = false;
        var hasMaxSeconds = false;
        
        for (field in fields) {
            switch(field.name) {
                case "strategy": hasStrategy = true;
                case "max_restarts": hasMaxRestarts = true;
                case "max_seconds": hasMaxSeconds = true;
                case _:
            }
        }
        
        return hasStrategy && (hasMaxRestarts || hasMaxSeconds);
    }
    
    /**
     * Build supervisor options as keyword list
     * 
     * WHY: OTP supervisors expect keyword list format
     * WHAT: Transforms object fields to keyword pairs
     * HOW: Convert field names to snake_case atoms
     */
    static function buildSupervisorOptions(fields: Array<{name: String, expr: TypedExpr}>, context: CompilationContext): ElixirASTDef {
        var keywordPairs: Array<EKeywordPair> = [];
        
        for (field in fields) {
            // Convert field names to snake_case for idiomatic Elixir atoms
            var atomName = NameUtils.toSnakeCase(field.name);
            var fieldValue = context.compiler.compileExpressionImpl(field.expr, false);
            keywordPairs.push({key: atomName, value: fieldValue});
        }
        
        return EKeywordList(keywordPairs);
    }
    
    /**
     * Check if fields represent a child spec
     * 
     * WHY: Child specs have specific structure for OTP
     * WHAT: Detects id and start fields
     * HOW: Check for required child spec fields
     */
    static function isChildSpec(fields: Array<{name: String, expr: TypedExpr}>): Bool {
        var hasId = false;
        var hasStart = false;
        
        for (field in fields) {
            switch(field.name) {
                case "id": hasId = true;
                case "start": hasStart = true;
                case _:
            }
        }
        
        return hasId && hasStart;
    }
    
    /**
     * Build child spec with special handling
     * 
     * WHY: Child specs need specific format for OTP
     * WHAT: Transforms object to map with special start field handling
     * HOW: Convert module/func/args to tuple format
     */
    static function buildChildSpec(fields: Array<{name: String, expr: TypedExpr}>, context: CompilationContext): ElixirASTDef {
        var pairs = [];
        
        for (field in fields) {
            // Convert camelCase field names to snake_case for Elixir atoms
            var atomName = NameUtils.toSnakeCase(field.name);
            var key = makeAST(EAtom(atomName));
            
            // Special handling for the start field in child specs
            var fieldValue = if (field.name == "start") {
                handleChildSpecStartField(field.expr, context);
            } else if (field.name == "type" || field.name == "restart" || field.name == "shutdown") {
                // These fields should be atoms when they're strings
                handleAtomField(field.expr, context);
            } else {
                // Standard field value compilation
                context.compiler.compileExpressionImpl(field.expr, false);
            };
            
            pairs.push({key: key, value: fieldValue});
        }
        
        return EMap(pairs);
    }
    
    /**
     * Handle start field in child spec
     * 
     * WHY: Start field needs {Module, :func, args} tuple format
     * WHAT: Transforms object to tuple if it has module/func/args
     * HOW: Extract fields and build tuple
     */
    static function handleChildSpecStartField(expr: TypedExpr, context: CompilationContext): ElixirAST {
        switch(expr.expr) {
            case TObjectDecl(startFields):
                var moduleField = null;
                var funcField = null;
                var argsField = null;
                
                for (sf in startFields) {
                    switch(sf.name) {
                        case "module": moduleField = sf;
                        case "func": funcField = sf;
                        case "args": argsField = sf;
                        case _:
                    }
                }
                
                if (moduleField != null && funcField != null && argsField != null) {
                    // Convert to tuple format {Module, :func, args}
                    var moduleAst = switch(moduleField.expr.expr) {
                        case TConst(TString(s)):
                            // Convert string module name to atom
                            makeAST(EVar(s));
                        case _:
                            context.compiler.compileExpressionImpl(moduleField.expr, false);
                    };
                    
                    var funcAst = switch(funcField.expr.expr) {
                        case TConst(TString(s)):
                            // Convert string function name to atom
                            makeAST(EAtom(s));
                        case _:
                            context.compiler.compileExpressionImpl(funcField.expr, false);
                    };
                    
                    var argsAst = context.compiler.compileExpressionImpl(argsField.expr, false);
                    
                    // Create tuple {Module, :func, args}
                    return makeAST(ETuple([moduleAst, funcAst, argsAst]));
                } else {
                    // Not the expected format, compile normally
                    return context.compiler.compileExpressionImpl(expr, false);
                }
                
            case _:
                // Not an object, compile normally
                return context.compiler.compileExpressionImpl(expr, false);
        }
    }
    
    /**
     * Handle fields that should be atoms
     * 
     * WHY: Certain OTP fields expect atoms not strings
     * WHAT: Convert string constants to atoms
     * HOW: Check for TConst(TString) and generate EAtom
     */
    static function handleAtomField(expr: TypedExpr, context: CompilationContext): ElixirAST {
        switch(expr.expr) {
            case TConst(TString(s)):
                return makeAST(EAtom(s));
            case _:
                return context.compiler.compileExpressionImpl(expr, false);
        }
    }
    
    /**
     * Build regular object as map
     * 
     * WHY: Most objects map to Elixir maps
     * WHAT: Transform object fields to map pairs
     * HOW: Convert field names to snake_case atoms, handle null coalescing
     */
    static function buildRegularMap(fields: Array<{name: String, expr: TypedExpr}>, context: CompilationContext): ElixirASTDef {
        var pairs = [];
        
        for (field in fields) {
            // Convert camelCase field names to snake_case for Elixir atoms
            var atomName = NameUtils.toSnakeCase(field.name);
            var key = makeAST(EAtom(atomName));
            
            // Handle field value with null coalescing detection
            var fieldValue = handleFieldValue(field, context);
            
            pairs.push({key: key, value: fieldValue});
        }
        
        return EMap(pairs);
    }
    
    /**
     * Handle field value with null coalescing detection
     * 
     * WHY: Haxe's ?? operator becomes a TBlock with specific pattern
     * WHAT: Detect and transform null coalescing to inline if
     * HOW: Pattern match on TBlock structure
     */
    static function handleFieldValue(field: {name: String, expr: TypedExpr}, context: CompilationContext): ElixirAST {
        switch(field.expr.expr) {
            // Detect null coalescing pattern
            case TBlock([{expr: TVar(tmpVar, init)}, {expr: TBinop(OpNullCoal, {expr: TLocal(v)}, defaultExpr)}]) 
                if (v.id == tmpVar.id && init != null):
                // Transform null coalescing pattern to idiomatic Elixir
                var initAst = context.compiler.compileExpressionImpl(init, false);
                var defaultAst = context.compiler.compileExpressionImpl(defaultExpr, false);
                var tmpVarName = VariableAnalyzer.toElixirVarName(
                    tmpVar.name.charAt(0) == "_" ? tmpVar.name.substr(1) : tmpVar.name
                );
                
                var ifExpr = makeAST(EIf(
                    makeAST(EBinary(EBinaryOp.NotEqual, 
                        makeAST(EMatch(PVar(tmpVarName), initAst)),
                        makeAST(ENil)
                    )),
                    makeAST(EVar(tmpVarName)),
                    defaultAst
                ));
                
                // Mark for inline rendering to maintain compact syntax
                if (ifExpr.metadata == null) ifExpr.metadata = {};
                ifExpr.metadata.keepInlineInAssignment = true;
                return ifExpr;
                
            case TLocal(v):
                // Check if the variable has been renamed
                var idKey = Std.string(v.id);
                
                // Check tempVarRenameMap for renamed variables
                if (context.tempVarRenameMap.exists(idKey)) {
                    var mappedName = context.tempVarRenameMap.get(idKey);
                    #if debug_variable_renaming
                    trace('[ObjectBuilder] Field "${field.name}" using tempVarRenameMap: "${v.name}" -> "${mappedName}"');
                    #end
                    return makeAST(EVar(mappedName));
                } else {
                    // No mapping, compile normally
                    return context.compiler.compileExpressionImpl(field.expr, false);
                }
                
            case _:
                // Standard field value compilation
                return context.compiler.compileExpressionImpl(field.expr, false);
        }
    }
}

#end