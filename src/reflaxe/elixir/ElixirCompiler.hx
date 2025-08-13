package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Type.TConstant;
import haxe.macro.Type.AbstractType;
import haxe.macro.Type.DefType;
import haxe.macro.Expr.Binop;
import haxe.macro.Expr.Unop;
import haxe.macro.Expr;
import haxe.macro.Expr.Constant;

import reflaxe.BaseCompiler;
import reflaxe.compiler.TargetCodeInjection;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;  
import reflaxe.data.EnumOptionData;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.EnumCompiler;
import reflaxe.elixir.helpers.ClassCompiler;
import reflaxe.elixir.helpers.PatternMatcher;
import reflaxe.elixir.helpers.GuardCompiler;
import reflaxe.elixir.helpers.TemplateCompiler;
import reflaxe.elixir.helpers.SchemaCompiler;
import reflaxe.elixir.helpers.ProtocolCompiler;
import reflaxe.elixir.helpers.BehaviorCompiler;
import reflaxe.elixir.helpers.RouterCompiler;
import reflaxe.elixir.helpers.AnnotationSystem;
import reflaxe.elixir.helpers.EctoQueryAdvancedCompiler;
import reflaxe.elixir.helpers.RepositoryCompiler;
import reflaxe.elixir.helpers.EctoErrorReporter;
import reflaxe.elixir.helpers.TypedefCompiler;
import reflaxe.elixir.helpers.LLMDocsGenerator;
import reflaxe.elixir.ElixirTyper;
import reflaxe.elixir.PhoenixMapper;
import reflaxe.elixir.SourceMapWriter;

using StringTools;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.TypedExprHelper;
using reflaxe.helpers.TypeHelper;

/**
 * Reflaxe.Elixir compiler for generating Elixir code from Haxe
 * Supports Phoenix applications with gradual typing
 */
class ElixirCompiler extends BaseCompiler {
    
    // File extension for generated Elixir files
    public var fileExtension: String = ".ex";
    
    // Output directory for generated files (dynamically set by Reflaxe)
    public var outputDirectory: String = "lib/";
    
    // Type mapping system for enhanced enum compilation
    private var typer: reflaxe.elixir.ElixirTyper;
    
    // Pattern matching and guard compilation helpers
    private var patternMatcher: reflaxe.elixir.helpers.PatternMatcher;
    private var guardCompiler: reflaxe.elixir.helpers.GuardCompiler;
    
    // Source mapping support for debugging and LLM workflows
    private var currentSourceMapWriter: Null<SourceMapWriter> = null;
    private var sourceMapOutputEnabled: Bool = false;
    
    // Parameter mapping system for abstract type implementation methods
    private var currentFunctionParameterMap: Map<String, String> = new Map();
    private var isCompilingAbstractMethod: Bool = false;
    
    /**
     * Constructor - Initialize the compiler with type mapping and pattern matching systems
     */
    public function new() {
        super();
        this.typer = new reflaxe.elixir.ElixirTyper();
        this.patternMatcher = new reflaxe.elixir.helpers.PatternMatcher();
        this.guardCompiler = new reflaxe.elixir.helpers.GuardCompiler();
        
        // Set compiler reference for delegation
        this.patternMatcher.setCompiler(this);
        
        // Enable source mapping if requested
        this.sourceMapOutputEnabled = Context.defined("source-map") || Context.defined("debug");
        
        // Initialize LLM documentation generator (optional)
        if (Context.defined("generate-llm-docs")) {
            LLMDocsGenerator.initialize();
        }
    }
    
    /**
     * Initialize source map writer for a specific output file
     */
    private function initSourceMapWriter(outputPath: String): Void {
        if (!sourceMapOutputEnabled) return;
        
        currentSourceMapWriter = new SourceMapWriter(outputPath);
    }
    
    /**
     * Finalize source map writer and generate .ex.map file
     */
    private function finalizeSourceMapWriter(): Null<String> {
        if (!sourceMapOutputEnabled || currentSourceMapWriter == null) return null;
        
        var sourceMapPath = currentSourceMapWriter.generateSourceMap();
        currentSourceMapWriter = null;
        return sourceMapPath;
    }
    
    /**
     * Convert Haxe names to Elixir naming conventions
     * Delegates to NamingHelper for consistency
     */
    public function toElixirName(haxeName: String): String {
        return NamingHelper.toSnakeCase(haxeName);
    }
    
    /**
     * Compile Haxe class to Elixir module using enhanced ClassCompiler
     * @param classType The Haxe class type
     * @param varFields Class variables
     * @param funcFields Class functions
     * @return Generated Elixir module string
     */
    public function compileClassImpl(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): Null<String> {
        if (classType == null) return null;
        
        // Initialize source mapping for this class
        if (sourceMapOutputEnabled) {
            var className = classType.name;
            var actualOutputDir = this.output.outputDir != null ? this.output.outputDir : outputDirectory;
            var outputPath = haxe.io.Path.join([actualOutputDir, className + fileExtension]);
            initSourceMapWriter(outputPath);
        }
        
        // Use unified annotation system for detection, validation, and routing
        var annotationResult = reflaxe.elixir.helpers.AnnotationSystem.routeCompilation(classType, varFields, funcFields);
        if (annotationResult != null) {
            // Generate source map for annotated compilation
            if (sourceMapOutputEnabled) {
                finalizeSourceMapWriter();
            }
            return annotationResult;
        }
        
        // Use the enhanced ClassCompiler for proper struct/module generation
        var classCompiler = new reflaxe.elixir.helpers.ClassCompiler(this.typer);
        classCompiler.setCompiler(this);
        
        // Handle inheritance tracking
        if (classType.superClass != null) {
            addModuleTypeForCompilation(TClassDecl(classType.superClass.t));
        }
        
        // Handle interface tracking
        for (iface in classType.interfaces) {
            addModuleTypeForCompilation(TClassDecl(iface.t));
        }
        
        var result = classCompiler.compileClass(classType, varFields, funcFields);
        
        // Finalize source mapping for this class
        if (sourceMapOutputEnabled) {
            finalizeSourceMapWriter();
        }
        
        return result;
    }
    
    /**
     * Compile @:migration annotated class to Ecto migration module
     */
    private function compileMigrationClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        try {
            var className = classType.name;
            var config = reflaxe.elixir.helpers.MigrationDSL.getMigrationConfig(classType);
            var tableName = config.table != null ? config.table : "default_table";
            
            // Validate table name
            if (tableName == "default_table") {
                reflaxe.elixir.helpers.EctoErrorReporter.warnAboutPattern(
                    "Migration using default table name",
                    "Specify a table name with @:migration({table: \"your_table\"})",
                    classType.pos
                );
            }
            
            // Extract table operations from class variables and functions
            var columns = varFields.map(field -> '${field.field.name}:${mapHaxeTypeToElixir(field.field.type)}');
            
            // Create migration data structure
            var migrationData = {
                className: className,
                timestamp: reflaxe.elixir.helpers.MigrationDSL.generateTimestamp(),
                tableName: tableName,
                columns: columns
            };
            
            // Generate comprehensive migration with table operations
            var migrationModule = reflaxe.elixir.helpers.MigrationDSL.compileFullMigration(migrationData);
        
        // Add custom migration functions if present in funcFields
        var customOperations = new Array<String>();
        for (func in funcFields) {
            if (func.field.name.indexOf("migrate") == 0) {
                var operationName = func.field.name.substring(7); // Remove "migrate" prefix
                var customOperation = generateCustomMigrationOperation(operationName, tableName);
                customOperations.push(customOperation);
            }
        }
        
        // Append custom operations to the migration if any exist
        if (customOperations.length > 0) {
            migrationModule += "\n\n  # Custom migration operations\n" + customOperations.join("\n");
        }
        
        return migrationModule;
        } catch (e: Dynamic) {
            // Dynamic used here because migration compilation can throw various error types
            reflaxe.elixir.helpers.EctoErrorReporter.reportMigrationError(
                "create_table",
                Std.string(e),
                classType.pos
            );
            return "";
        }
    }
    
    /**
     * Extract table name from migration class name
     */
    private function extractTableNameFromClassName(className: String): String {
        // Convert CreateUsersTable -> users, AlterPostsTable -> posts, etc.
        var tableName = className;
        
        // Remove common prefixes
        if (tableName.indexOf("Create") == 0) {
            tableName = tableName.substring(6);
        } else if (tableName.indexOf("Alter") == 0) {
            tableName = tableName.substring(5);
        } else if (tableName.indexOf("Drop") == 0) {
            tableName = tableName.substring(4);
        }
        
        // Remove Table suffix
        if (tableName.endsWith("Table")) {
            tableName = tableName.substring(0, tableName.length - 5);
        }
        
        // Convert to snake_case
        return reflaxe.elixir.helpers.MigrationDSL.camelCaseToSnakeCase(tableName);
    }
    
    /**
     * Map Haxe types to Elixir migration types
     */
    private function mapHaxeTypeToElixir(haxeType: Dynamic): String {
        // Simplified type mapping - would use ElixirTyper for full implementation
        return "string"; // Default to string for now
    }
    
    /**
     * Generate custom migration operation
     */
    private function generateCustomMigrationOperation(operationName: String, tableName: String): String {
        return '  # Custom operation: ${operationName}\n' +
               '  # Add custom migration logic for ${tableName} table';
    }
    
    /**
     * Compile @:template annotated class to Phoenix template module
     */
    private function compileTemplateClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.helpers.TemplateCompiler.getTemplateConfig(classType);
        
        // Generate comprehensive template module with Phoenix.Component integration
        return reflaxe.elixir.helpers.TemplateCompiler.compileFullTemplate(className, config);
    }
    
    /**
     * Compile @:schema annotated class to Ecto.Schema module with enhanced error reporting
     */
    private function compileSchemaClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var pos = classType.pos;
        
        try {
            var config = reflaxe.elixir.helpers.SchemaCompiler.getSchemaConfig(classType);
            
            // Validate schema fields before compilation
            var fields = varFields.map(function(field) {
                var meta = field.field.meta.get();
                var fieldMeta = null;
                
                // Extract field metadata
                for (m in meta) {
                    if (m.name == ":field") {
                        fieldMeta = m.params.length > 0 ? m.params[0] : null;
                    }
                }
                
                return {
                    name: field.field.name,
                    type: mapHaxeTypeToElixir(field.field.type),
                    meta: fieldMeta
                };
            });
            
            // Validate fields using error reporter
            if (!EctoErrorReporter.validateSchemaFields(fields, pos)) {
                return ""; // Error already reported
            }
            
            // Generate comprehensive Ecto.Schema module with schema/2 macro and associations
            return reflaxe.elixir.helpers.SchemaCompiler.compileFullSchema(className, config, varFields);
        } catch (e: Dynamic) {
            // Dynamic used here because Haxe's catch can throw various error types
            // Converting to String for error reporting
            EctoErrorReporter.reportSchemaError(className, Std.string(e), pos);
            return "";
        }
    }
    
    /**
     * Compile @:changeset annotated class to Ecto changeset module with enhanced error reporting
     */
    private function compileChangesetClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var pos = classType.pos;
        
        try {
            var config = reflaxe.elixir.helpers.ChangesetCompiler.getChangesetConfig(classType);
            var schemaName = config.schema != null ? config.schema : "DefaultSchema";
            
            // Validate changeset configuration
            if (!EctoErrorReporter.validateChangesetConfig(className, config, pos)) {
                return ""; // Error already reported
            }
            
            // Extract field information from class variables for validation
            var fieldNames = varFields.map(field -> field.field.name);
            
            // Generate comprehensive changeset with schema integration
            var changesetModule = reflaxe.elixir.helpers.ChangesetCompiler.compileFullChangeset(className, schemaName);
            
            // Add custom validation functions if present in funcFields
            var customValidations = new Array<String>();
            for (func in funcFields) {
                if (func.field.name.indexOf("validate") == 0) {
                    var validationName = func.field.name.substring(8); // Remove "validate" prefix
                    var customValidation = reflaxe.elixir.helpers.ChangesetCompiler.generateCustomValidation(
                        validationName, 
                        "field", 
                        "true" // Simplified condition
                    );
                    customValidations.push(customValidation);
                }
            }
            
            // Append custom validations to the module
            if (customValidations.length > 0) {
                changesetModule += "\n\n" + customValidations.join("\n");
            }
            
            return changesetModule;
        } catch (e: Dynamic) {
            // Dynamic used here because Haxe's catch can throw various error types
            // Converting to String for error reporting
            EctoErrorReporter.reportChangesetError(className, Std.string(e), pos);
            return "";
        }
    }
    
    /**
     * Compile @:genserver annotated class to OTP GenServer module
     */
    private function compileGenServerClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.helpers.OTPCompiler.getGenServerConfig(classType);
        
        // Extract state from class variables
        var initialState = "%{";
        var stateFields = [];
        for (field in varFields) {
            var fieldName = field.field.name;
            var defaultValue = switch(Std.string(field.field.type)) {
                case "Int": "0";
                case "String": '""';
                case "Bool": "false";
                default: "nil";
            };
            stateFields.push('${fieldName}: ${defaultValue}');
        }
        initialState += stateFields.join(", ") + "}";
        
        // Extract methods and categorize into calls vs casts
        var callMethods = [];
        var castMethods = [];
        
        for (func in funcFields) {
            var methodName = func.field.name;
            
            // Methods starting with "get" or returning values are synchronous calls
            if (methodName.indexOf("get") == 0 || methodName.indexOf("is") == 0) {
                callMethods.push({name: methodName, returns: "Dynamic"});
            }
            // Methods that modify state are asynchronous casts
            else if (methodName.indexOf("set") == 0 || methodName.indexOf("update") == 0 || methodName.indexOf("increment") == 0) {
                castMethods.push({name: methodName, modifies: "value"});
            }
        }
        
        // Create GenServer data structure
        var genServerData = {
            className: className,
            initialState: initialState,
            callMethods: callMethods,
            castMethods: castMethods
        };
        
        // Generate comprehensive GenServer with all callbacks
        return reflaxe.elixir.helpers.OTPCompiler.compileFullGenServer(genServerData);
    }
    
    /**
     * Compile @:liveview annotated class to Phoenix LiveView module  
     */
    private function compileLiveViewClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.LiveViewCompiler.getLiveViewConfig(classType);
        
        // Generate LiveView module using existing LiveViewCompiler
        return reflaxe.elixir.LiveViewCompiler.compileFullLiveView(className, config);
    }
    
    /**
     * Compile Haxe enum to Elixir tagged tuples using enhanced EnumCompiler
     */
    public function compileEnumImpl(enumType: EnumType, options: Array<EnumOptionData>): Null<String> {
        if (enumType == null) return null;
        
        // Use the enhanced EnumCompiler helper for proper type integration
        var enumCompiler = new reflaxe.elixir.helpers.EnumCompiler(this.typer);
        return enumCompiler.compileEnum(enumType, options);
    }
    
    /**
     * Compile expression - required by BaseCompiler (implements abstract method)
     */
    public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<String> {
        return compileElixirExpressionInternal(expr, topLevel);
    }
    
    /**
     * Compile abstract types - generates proper Elixir type aliases and implementation modules
     * Abstract types in Haxe become type aliases in Elixir with implementation modules for operators
     */
    public override function compileAbstract(abstractType: AbstractType): Null<String> {
        // Skip core Haxe types that are handled elsewhere
        if (isBuiltinAbstractType(abstractType.name)) {
            return null;
        }
        
        // Generate Elixir type alias for the abstract
        final typeName = abstractType.name;
        final underlyingType = getElixirTypeFromHaxeType(abstractType.type);
        
        // Create type alias definition
        final typeAlias = '@type ${typeName.toLowerCase()}_t() :: ${underlyingType}';
        
        // Add type alias to current module output
        var currentModuleContent = getCurrentModuleContent(abstractType);
        if (currentModuleContent != null) {
            currentModuleContent = addTypeDefinition(currentModuleContent, typeAlias);
            updateCurrentModuleContent(abstractType, currentModuleContent);
        }
        
        trace('Generated Elixir type alias for abstract ${typeName}: ${typeAlias}');
        
        // Return null to indicate we handled this through side effects
        return null;
    }
    
    /**
     * Check if this is a built-in Haxe abstract type that should be handled by core type system
     */
    private function isBuiltinAbstractType(name: String): Bool {
        return switch (name) {
            case "Int" | "Float" | "Bool" | "String" | "Dynamic" | "Void" | "Any" | "Null" | 
                 "Function" | "Class" | "Enum" | "EnumValue" | "Int32" | "Int64" | "Map" | "CallStack":
                true;
            default:
                false;
        };
    }
    
    /**
     * Get Elixir type representation from Haxe type
     */
    private function getElixirTypeFromHaxeType(type: Type): String {
        return switch (type) {
            case TInst(_.get() => classType, _):
                switch (classType.name) {
                    case "String": "String.t()";
                    case "Array": "list()";
                    default: "term()";
                }
            case TAbstract(_.get() => abstractType, _):
                switch (abstractType.name) {
                    case "Int": "integer()";
                    case "Float": "float()";
                    case "Bool": "boolean()";
                    default: "term()";
                }
            default:
                "term()";
        };
    }
    
    /**
     * Helper methods for managing module content - simplified for now
     */
    private function getCurrentModuleContent(abstractType: AbstractType): Null<String> {
        // For now, return a simple placeholder
        return "";
    }
    
    private function addTypeDefinition(content: String, typeAlias: String): String {
        return content + "\n  " + typeAlias + "\n";
    }
    
    private function updateCurrentModuleContent(abstractType: AbstractType, content: String): Void {
        // For now, this is a placeholder - in a full implementation,
        // this would update the module's content in the output system
    }
    
    /**
     * Compile typedef - Returns null to ignore typedefs as BaseCompiler recommends.
     * This prevents generating invalid StdTypes.ex files with @typedoc/@type outside modules.
     */
    public override function compileTypedef(defType: DefType): Null<String> {
        // Following BaseCompiler recommendation: ignore typedefs since
        // "Haxe redirects all types automatically" - no standalone typedef files needed
        // 
        // Returning null prevents generating invalid StdTypes.ex files with 
        // @typedoc/@type directives outside modules.
        // 
        // TODO: Future refactor should extend DirectToStringCompiler instead of BaseCompiler
        // to properly support typedef compilation with module wrapping if needed.
        return null;
    }
    
    
    /**
     * Compile Haxe expressions to Elixir expressions with source mapping support
     */
    public override function compileExpression(expr: TypedExpr, topLevel: Bool = false): Null<String> {
        if (expr == null) return null;
        
        // Check for target code injection (__elixir__ calls)
        if (options.targetCodeInjectionName != null) {
            final result = TargetCodeInjection.checkTargetCodeInjection(options.targetCodeInjectionName, expr, this);
            if (result != null) {
                return result;
            }
        }
        
        // Add source mapping before compiling expression
        if (sourceMapOutputEnabled && currentSourceMapWriter != null && expr.pos != null) {
            currentSourceMapWriter.mapPosition(expr.pos);
        }
        
        var result = compileElixirExpressionInternal(expr, topLevel);
        
        // Track generated code length for accurate column positioning  
        if (sourceMapOutputEnabled && currentSourceMapWriter != null && result != null) {
            currentSourceMapWriter.stringWritten(result);
        }
        
        return result;
    }
    
    /**
     * Internal Elixir expression compilation
     */
    private function compileElixirExpressionInternal(expr: TypedExpr, topLevel: Bool = false): Null<String> {
        
        // Comprehensive expression compilation
        return switch (expr.expr) {
            case TConst(constant):
                compileTConstant(constant);
                
            case TLocal(v):
                // Use parameter mapping if we're compiling an abstract method
                var varName = v.name;
                if (isCompilingAbstractMethod && currentFunctionParameterMap.exists(varName)) {
                    currentFunctionParameterMap.get(varName);
                } else {
                    NamingHelper.toSnakeCase(varName);
                }
                
            case TBinop(op, e1, e2):
                compileExpression(e1) + " " + compileBinop(op) + " " + compileExpression(e2);
                
            case TUnop(op, postFix, e):
                var expr_str = compileExpression(e);
                switch (op) {
                    case OpIncrement: postFix ? '${expr_str} + 1' : '${expr_str} + 1'; // Elixir doesn't have ++
                    case OpDecrement: postFix ? '${expr_str} - 1' : '${expr_str} - 1'; // Elixir doesn't have --
                    case OpNot: '!${expr_str}';
                    case OpNeg: '-${expr_str}';
                    case OpNegBits: 'bnot(${expr_str})';
                    case _: '${expr_str}';
                }
                
            case TField(e, fa):
                compileFieldAccess(e, fa);
                
            case TCall(e, el):
                compileMethodCall(e, el);
                
            case TArrayDecl(el):
                "[" + el.map(expr -> compileExpression(expr)).join(", ") + "]";
                
            case TObjectDecl(fields):
                "%{" + fields.map(f -> f.name + ": " + compileExpression(f.expr)).join(", ") + "}";
                
            case TVar(tvar, expr):
                var varName = NamingHelper.toSnakeCase(tvar.getNameOrNative());
                if (expr != null) {
                    '${varName} = ${compileExpression(expr)}';
                } else {
                    '${varName} = nil';
                }
                
            case TBlock(el):
                if (el.length == 0) {
                    "nil";
                } else if (el.length == 1) {
                    compileExpression(el[0]);
                } else {
                    "(\n" + el.map(e -> "  " + compileExpression(e)).join("\n") + "\n)";
                }
                
            case TIf(econd, eif, eelse):
                var cond = compileExpression(econd);
                var ifExpr = compileExpression(eif);
                var elseExpr = eelse != null ? compileExpression(eelse) : "nil";
                'if ${cond}, do: ${ifExpr}, else: ${elseExpr}';
                
            case TReturn(expr):
                if (expr != null) {
                    compileExpression(expr); // Elixir uses implicit returns
                } else {
                    "nil";
                }
                
            case TParenthesis(e):
                "(" + compileExpression(e) + ")";
                
            case TSwitch(e, cases, edef):
                compileSwitchExpression(e, cases, edef);
                
            case TWhile(econd, ebody, normalWhile):
                var condition = compileExpression(econd);
                var body = compileExpression(ebody);
                normalWhile ? 
                    'while ${condition} do\n  ${body}\nend' :
                    'until !${condition} do\n  ${body}\nend';
                
            case TArray(e1, e2):
                var arrayExpr = compileExpression(e1);
                var indexExpr = compileExpression(e2);
                'Enum.at(${arrayExpr}, ${indexExpr})';
                
            case TNew(c, _, el):
                var className = NamingHelper.getElixirModuleName(c.toString());
                var args = el.map(expr -> compileExpression(expr)).join(", ");
                args.length > 0 ? 
                    '${className}.new(${args})' :
                    '${className}.new()';
                
            case TFunction(func):
                var args = func.args.map(arg -> NamingHelper.toSnakeCase(arg.v.name)).join(", ");
                var body = compileExpression(func.expr);
                'fn ${args} -> ${body} end';
                
            case TMeta(metadata, expr):
                // Compile metadata wrapper - just compile the inner expression
                compileExpression(expr);
                
            case TTry(tryExpr, catches):
                var tryBody = compileExpression(tryExpr);
                var result = 'try do\n  ${tryBody}\n';
                
                for (catchItem in catches) {
                    var catchVar = NamingHelper.toSnakeCase(catchItem.v.name);
                    var catchBody = compileExpression(catchItem.expr);
                    result += 'rescue\n  ${catchVar} ->\n    ${catchBody}\n';
                }
                
                result + 'end';
                
            case TThrow(expr):
                var throwExpr = compileExpression(expr);
                'throw(${throwExpr})';
                
            case TCast(expr, moduleType):
                // Simple cast - just compile the expression
                // In Elixir, we rely on pattern matching for type safety
                compileExpression(expr);
                
            case TTypeExpr(moduleType):
                // Type expression - convert to Elixir module name
                switch (moduleType) {
                    case TClassDecl(c): NamingHelper.getElixirModuleName(c.get().name);
                    case TEnumDecl(e): NamingHelper.getElixirModuleName(e.get().name);
                    case TAbstract(a): NamingHelper.getElixirModuleName(a.get().name);
                    case _: "Dynamic";
                }
                
            case _:
                "# TODO: Implement expression type: " + expr.expr.getName();
        }
    }
    
    /**
     * Compile switch expression to Elixir case statement with advanced pattern matching
     * Supports enum patterns, guard clauses, binary patterns, and pin operators
     */
    private function compileSwitchExpression(switchExpr: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, defaultExpr: Null<TypedExpr>): String {
        // Use PatternMatcher for advanced pattern compilation
        if (patternMatcher == null) {
            patternMatcher = new reflaxe.elixir.helpers.PatternMatcher();
            patternMatcher.setCompiler(this);
        }
        
        var result = new StringBuf();
        var switchValue = compileExpression(switchExpr);
        
        result.add('case ${switchValue} do\n');
        
        // Process each case with advanced pattern support
        for (caseItem in cases) {
            for (value in caseItem.values) {
                // Use PatternMatcher for all pattern types
                var pattern = patternMatcher.compilePattern(value);
                
                // Check for guard expressions (if the field exists)
                var guardClause = "";
                // Guards are typically embedded in the value patterns in Haxe switch statements
                // We'll need to extract them from the pattern if present
                
                var caseExpr = compileExpression(caseItem.expr);
                result.add('  ${pattern}${guardClause} ->\n');
                result.add('    ${caseExpr}\n');
            }
        }
        
        // Add default case if present
        if (defaultExpr != null) {
            var defaultCode = compileExpression(defaultExpr);
            result.add('  _ ->\n');
            result.add('    ${defaultCode}\n');
        }
        
        result.add('end');
        
        return result.toString();
    }
    
    /**
     * Compile enum constructor pattern for case matching
     */
    private function compileEnumPattern(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TField(_, FEnum(enumType, enumField)):
                // Simple enum pattern: SomeEnum.Option → :option
                var fieldName = NamingHelper.toSnakeCase(enumField.name);
                ':${fieldName}';
                
            case TCall(e, args) if (isEnumFieldAccess(e)):
                // Parameterized enum pattern: SomeEnum.Option(value) → {:option, value}
                var fieldName = extractEnumFieldName(e);
                if (args.length == 0) {
                    ':${fieldName}';
                } else if (args.length == 1) {
                    var argPattern = compilePatternArgument(args[0]);
                    '{:${fieldName}, ${argPattern}}';
                } else {
                    var argPatterns = args.map(compilePatternArgument);
                    '{:${fieldName}, ${argPatterns.join(', ')}}';
                }
                
            case TConst(constant):
                // Literal constants in switch
                compileTConstant(constant);
                
            case _:
                // Fallback - compile as regular expression
                compileExpression(expr);
        }
    }
    
    /**
     * Compile pattern argument (variable binding or literal)
     */
    private function compilePatternArgument(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TLocal(v):
                // Variable binding in pattern
                NamingHelper.toSnakeCase(v.name);
                
            case TConst(constant):
                // Literal in pattern
                compileTConstant(constant);
                
            case _:
                // Wildcard or complex pattern
                "_";
        }
    }
    
    /**
     * Helper: Compile struct definition from class variables
     */
    private function compileStruct(varFields: Array<ClassVarData>): String {
        var result = '  defstruct [';
        var fieldNames = [];
        
        for (field in varFields) {
            var fieldName = toElixirName(field.field.name);
            fieldNames.push('${fieldName}: nil');
        }
        
        result += fieldNames.join(', ');
        result += ']\n\n';
        
        return result;
    }
    
    /**
     * Helper: Compile function definition
     */
    private function compileFunction(funcField: ClassFuncData, isStatic: Bool = false): String {
        var funcName = NamingHelper.getElixirFunctionName(funcField.field.name);
        
        // Build parameter list
        var params = [];
        for (arg in funcField.args) {
            params.push(NamingHelper.toSnakeCase(arg.name != null ? arg.name : "arg"));
        }
        
        var paramStr = params.join(", ");
        var result = '  @doc "Generated from Haxe ${funcField.field.name}"\n';
        result += '  def ${funcName}(${paramStr}) do\n';
        
        if (funcField.expr != null) {
            // Compile the actual function body
            var compiledBody = compileExpression(funcField.expr);
            if (compiledBody != null && compiledBody != "") {
                result += '    ${compiledBody}\n';
            } else {
                result += '    # TODO: Implement function body\n';
                result += '    nil\n';
            }
        } else {
            result += '    # TODO: Implement function body\n';
            result += '    nil\n';
        }
        result += '  end\n\n';
        
        return result;
    }
    
    /**
     * Helper: Check if class has instance variables (non-static)
     */
    private function hasInstanceVars(varFields: Array<ClassVarData>): Bool {
        for (field in varFields) {
            if (!field.isStatic) return true;
        }
        return false;
    }
    
    /**
     * Helper: Check if expression is enum field access
     */
    private function isEnumFieldAccess(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TField(_, FEnum(_, _)): true;
            case _: false;
        }
    }
    
    /**
     * Helper: Extract enum field name from TField expression
     */
    private function extractEnumFieldName(expr: TypedExpr): String {
        return switch (expr.expr) {
            case TField(_, FEnum(_, enumField)): NamingHelper.toSnakeCase(enumField.name);
            case _: "unknown";
        }
    }
    
    /**
     * Helper: Compile constants to Elixir literals
     */
    private function compileConstant(constant: Constant): String {
        return switch (constant) {
            case CInt(i, _): i;
            case CFloat(s, _): s;
            case CString(s, _): '"${s}"';
            case CIdent(s): s;
            case CRegexp(r, opt): '~r/${r}/${opt}';
            case _: "nil";
        }
    }
    
    /**
     * Helper: Compile TConstant (typed constants) to Elixir literals
     */
    private function compileTConstant(constant: TConstant): String {
        return switch (constant) {
            case TInt(i): Std.string(i);
            case TFloat(s): s;
            case TString(s): '"${s}"';
            case TBool(b): b ? "true" : "false";
            case TNull: "nil";
            case TThis: "self()"; // Will need context-specific handling
            case TSuper: "super()"; // Will need context-specific handling
            case _: "nil";
        }
    }
    
    /**
     * Helper: Compile binary operators to Elixir
     */
    private function compileBinop(op: Binop): String {
        return switch (op) {
            case OpAdd: "+";
            case OpMult: "*";
            case OpDiv: "/";
            case OpSub: "-";
            case OpAssign: "=";
            case OpEq: "==";
            case OpNotEq: "!=";
            case OpGt: ">";
            case OpGte: ">=";
            case OpLt: "<";
            case OpLte: "<=";
            case OpAnd: "and";
            case OpOr: "or";
            case OpXor: "xor"; // Elixir has xor
            case OpBoolAnd: "&&";
            case OpBoolOr: "||";
            case OpShl: "<<<"; // Bitwise shift left in Elixir
            case OpShr: ">>>"; // Bitwise shift right in Elixir
            case OpUShr: ">>>"; // Unsigned right shift -> regular right shift
            case OpMod: "rem"; // Remainder in Elixir
            case OpAssignOp(op): compileBinop(op) + "=";
            case OpInterval: ".."; // Range operator in Elixir
            case OpArrow: "->"; // Function arrow
            case OpIn: "in"; // Membership test
            case OpNullCoal: "||"; // Null coalescing -> or
        }
    }
    
    /**
     * Helper: Compile field access
     */
    private function compileFieldAccess(e: TypedExpr, fa: FieldAccess): String {
        var expr = compileExpression(e);
        
        return switch (fa) {
            case FInstance(classType, _, classFieldRef):
                var fieldName = NamingHelper.toSnakeCase(classFieldRef.get().name);
                '${expr}.${fieldName}'; // Map access syntax
                
            case FStatic(classType, classFieldRef):
                var cls = classType.get();
                var className = NamingHelper.getElixirModuleName(cls.getNameOrNative());
                var fieldName = classFieldRef.get().name;
                
                // Special handling for StringTools extern
                if (cls.name == "StringTools" && cls.isExtern) {
                    className = "StringTools";
                    // Map Haxe method names to Elixir function names
                    fieldName = switch(fieldName) {
                        case "isSpace": "is_space";
                        case "urlEncode": "url_encode";
                        case "urlDecode": "url_decode";
                        case "htmlEscape": "html_escape";
                        case "htmlUnescape": "html_unescape";
                        case "startsWith": "starts_with?";
                        case "endsWith": "ends_with?";
                        case "fastCodeAt": "fast_code_at";
                        case "unsafeCodeAt": "unsafe_code_at";
                        case "isEof": "is_eof";
                        case "utf16CodePointAt": "utf16_code_point_at";
                        case "keyValueIterator": "key_value_iterator";
                        case "quoteUnixArg": "quote_unix_arg";
                        case "quoteWinArg": "quote_win_arg";
                        case "winMetaCharacters": "win_meta_characters";
                        case other: NamingHelper.toSnakeCase(other);
                    };
                } else {
                    fieldName = NamingHelper.getElixirFunctionName(fieldName);
                }
                
                '${className}.${fieldName}'; // Module function call
                
            case FAnon(classFieldRef):
                var fieldName = NamingHelper.toSnakeCase(classFieldRef.get().name);
                '${expr}.${fieldName}'; // Map access
                
            case FDynamic(s):
                var fieldName = NamingHelper.toSnakeCase(s);
                '${expr}.${fieldName}'; // Dynamic access
                
            case FClosure(_, classFieldRef):
                var fieldName = NamingHelper.toSnakeCase(classFieldRef.get().name);
                '&${expr}.${fieldName}/0'; // Function capture syntax
                
            case FEnum(enumType, enumField):
                var enumName = NamingHelper.getElixirModuleName(enumType.get().getNameOrNative());
                var optionName = NamingHelper.toSnakeCase(enumField.name);
                '${enumName}.${optionName}()'; // Enum constructor call
        }
    }
    
    /**
     * Set up parameter mapping for function compilation
     */
    public function setFunctionParameterMapping(args: Array<reflaxe.data.ClassFuncArg>): Void {
        currentFunctionParameterMap.clear();
        isCompilingAbstractMethod = true;
        
        if (args != null) {
            for (i in 0...args.length) {
                var arg = args[i];
                if (arg.name != null) {
                    currentFunctionParameterMap.set(arg.name, 'arg${i}');
                    
                    // Also handle common abstract type parameter patterns
                    if (arg.name == "this") {
                        currentFunctionParameterMap.set("this1", 'arg${i}');
                    }
                }
            }
        }
    }
    
    /**
     * Clear parameter mapping after function compilation
     */
    public function clearFunctionParameterMapping(): Void {
        currentFunctionParameterMap.clear();
        isCompilingAbstractMethod = false;
    }
    
    /**
     * Compile method calls with repository operation detection
     */
    private function compileMethodCall(e: TypedExpr, args: Array<TypedExpr>): String {
        // Check for repository operations (Repo.method calls)
        switch (e.expr) {
            case TField(obj, fa):
                var methodName = getFieldName(fa);
                var objStr = compileExpression(obj);
                
                // Detect Repo operations
                if (objStr == "Repo") {
                    var compiledArgs = args.map(arg -> compileExpression(arg));
                    var schemaName = detectSchemaFromArgs(args);
                    
                    // Special handling for @:native methods like get!
                    if (methodName == "getBang") {
                        methodName = "get!";
                    }
                    
                    return RepositoryCompiler.compileRepoCall(methodName, compiledArgs, schemaName);
                }
                
                // Check if this is a String method call
                switch (obj.t) {
                    case TInst(t, _) if (t.get().name == "String"):
                        return compileStringMethod(objStr, methodName, args);
                    case _:
                        // Continue with normal method call handling
                }
                
                // Handle other method calls normally
                var compiledArgs = args.map(arg -> compileExpression(arg));
                return '${objStr}.${methodName}(${compiledArgs.join(", ")})';
                
            case _:
                // Regular function call
                var compiledArgs = args.map(arg -> compileExpression(arg));
                return compileExpression(e) + "(" + compiledArgs.join(", ") + ")";
        }
    }
    
    /**
     * Compile String method calls to Elixir equivalents
     */
    private function compileStringMethod(objStr: String, methodName: String, args: Array<TypedExpr>): String {
        var compiledArgs = args.map(arg -> compileExpression(arg));
        
        return switch (methodName) {
            case "charCodeAt":
                // s.charCodeAt(pos) → String.to_charlist(s) |> Enum.at(pos) 
                if (compiledArgs.length > 0) {
                    'case String.at(${objStr}, ${compiledArgs[0]}) do nil -> nil; c -> :binary.first(c) end';
                } else {
                    'nil';
                }
            case "charAt":
                // s.charAt(pos) → String.at(s, pos)
                if (compiledArgs.length > 0) {
                    'String.at(${objStr}, ${compiledArgs[0]})';
                } else {
                    '""';
                }
            case "toLowerCase":
                'String.downcase(${objStr})';
            case "toUpperCase":
                'String.upcase(${objStr})';
            case "substr" | "substring":
                // Handle substr/substring with Elixir's String.slice
                if (compiledArgs.length >= 2) {
                    'String.slice(${objStr}, ${compiledArgs[0]}, ${compiledArgs[1]})';
                } else if (compiledArgs.length == 1) {
                    'String.slice(${objStr}, ${compiledArgs[0]}..-1)';
                } else {
                    objStr;
                }
            case "indexOf":
                // s.indexOf(substr) → find index or -1
                if (compiledArgs.length > 0) {
                    'case :binary.match(${objStr}, ${compiledArgs[0]}) do {pos, _} -> pos; :nomatch -> -1 end';
                } else {
                    '-1';
                }
            case "split":
                if (compiledArgs.length > 0) {
                    'String.split(${objStr}, ${compiledArgs[0]})';
                } else {
                    '[${objStr}]';
                }
            case "trim":
                'String.trim(${objStr})';
            case "length":
                'String.length(${objStr})';
            case _:
                // Default: try to call as a regular method (might fail at runtime)
                '${objStr}.${methodName}(${compiledArgs.join(", ")})';
        };
    }
    
    /**
     * Detect schema name from repository operation arguments
     */
    private function detectSchemaFromArgs(args: Array<TypedExpr>): Null<String> {
        if (args.length == 0) return null;
        
        // Try to detect schema from first argument type
        var firstArgType = args[0].t;
        switch (firstArgType) {
            case TInst(t, _):
                var classType = t.get();
                // Check if this is a schema class
                if (classType.meta.has(":schema")) {
                    return classType.name;
                }
            case _:
        }
        
        return null;
    }
    
    /**
     * Get field name from field access
     */
    private function getFieldName(fa: FieldAccess): String {
        return switch (fa) {
            case FInstance(_, _, cf) | FStatic(_, cf) | FClosure(_, cf): cf.get().name;
            case FAnon(cf): cf.get().name;
            case FDynamic(s): s;
            case FEnum(_, ef): ef.name;
        };
    }
    
    /**
     * Format expression line for Elixir syntax requirements
     */
    public override function formatExpressionLine(expr: String): String {
        // Elixir doesn't need semicolons, but we might want other formatting
        return expr;
    }
    
}

#end