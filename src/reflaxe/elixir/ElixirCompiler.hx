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
import reflaxe.elixir.ElixirTyper;
import reflaxe.elixir.PhoenixMapper;

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
    
    // Output directory for generated files
    public var outputDirectory: String = "lib/";
    
    // Type mapping system for enhanced enum compilation
    private var typer: reflaxe.elixir.ElixirTyper;
    
    // Pattern matching and guard compilation helpers
    private var patternMatcher: reflaxe.elixir.helpers.PatternMatcher;
    private var guardCompiler: reflaxe.elixir.helpers.GuardCompiler;
    
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
        
        // Use unified annotation system for detection, validation, and routing
        var annotationResult = reflaxe.elixir.helpers.AnnotationSystem.routeCompilation(classType, varFields, funcFields);
        if (annotationResult != null) {
            return annotationResult;
        }
        
        // Use the enhanced ClassCompiler for proper struct/module generation
        var classCompiler = new reflaxe.elixir.helpers.ClassCompiler(this.typer);
        
        // Handle inheritance tracking
        if (classType.superClass != null) {
            addModuleTypeForCompilation(TClassDecl(classType.superClass.t));
        }
        
        // Handle interface tracking
        for (iface in classType.interfaces) {
            addModuleTypeForCompilation(TClassDecl(iface.t));
        }
        
        return classCompiler.compileClass(classType, varFields, funcFields);
    }
    
    /**
     * Compile @:migration annotated class to Ecto migration module
     */
    private function compileMigrationClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.helpers.MigrationDSL.getMigrationConfig(classType);
        var tableName = config.table != null ? config.table : extractTableNameFromClassName(className);
        
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
     * Compile @:schema annotated class to Ecto.Schema module
     */
    private function compileSchemaClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.helpers.SchemaCompiler.getSchemaConfig(classType);
        
        // Generate comprehensive Ecto.Schema module with schema/2 macro and associations
        return reflaxe.elixir.helpers.SchemaCompiler.compileFullSchema(className, config, varFields);
    }
    
    /**
     * Compile @:changeset annotated class to Ecto changeset module
     */
    private function compileChangesetClass(classType: ClassType, varFields: Array<ClassVarData>, funcFields: Array<ClassFuncData>): String {
        var className = classType.name;
        var config = reflaxe.elixir.helpers.ChangesetCompiler.getChangesetConfig(classType);
        var schemaName = config.schema != null ? config.schema : "DefaultSchema";
        
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
        return compileExpression(expr, topLevel);
    }
    
    /**
     * Compile abstract types - currently not fully supported
     */
    public override function compileAbstract(classType: AbstractType): Null<String> {
        // TODO: Implement abstract type compilation
        trace('# Abstract type ${classType.name} not yet fully supported');
        return null;
    }
    
    /**
     * Compile typedef - map to Elixir type aliases
     */
    public override function compileTypedef(defType: DefType): Null<String> {
        // TODO: Implement typedef compilation
        trace('# Typedef ${defType.name} not yet fully supported');
        return null;
    }
    
    
    /**
     * Compile Haxe expressions to Elixir expressions
     */
    public override function compileExpression(expr: TypedExpr, topLevel: Bool = false): Null<String> {
        if (expr == null) return null;
        
        // Comprehensive expression compilation
        return switch (expr.expr) {
            case TConst(constant):
                compileTConstant(constant);
                
            case TLocal(v):
                NamingHelper.toSnakeCase(v.name);
                
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
                compileExpression(e) + "(" + el.map(expr -> compileExpression(expr)).join(", ") + ")";
                
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
                
            case _:
                "# TODO: Implement expression type: " + expr.expr.getName();
        }
    }
    
    /**
     * Compile switch expression to Elixir case statement with enum pattern matching
     */
    private function compileSwitchExpression(switchExpr: TypedExpr, cases: Array<{values: Array<TypedExpr>, expr: TypedExpr}>, defaultExpr: Null<TypedExpr>): String {
        var result = new StringBuf();
        var switchValue = compileExpression(switchExpr);
        
        result.add('case ${switchValue} do\n');
        
        // Process each case
        for (caseItem in cases) {
            for (value in caseItem.values) {
                var pattern = compileEnumPattern(value);
                var caseExpr = compileExpression(caseItem.expr);
                result.add('  ${pattern} ->\n');
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
            result += '    # TODO: Compile function body\n';
            result += '    # ${Std.string(funcField.expr)}\n';
        }
        
        result += '    :ok\n';
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
                var className = NamingHelper.getElixirModuleName(classType.get().getNameOrNative());
                var fieldName = NamingHelper.getElixirFunctionName(classFieldRef.get().name);
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
     * Format expression line for Elixir syntax requirements
     */
    public override function formatExpressionLine(expr: String): String {
        // Elixir doesn't need semicolons, but we might want other formatting
        return expr;
    }
}

#end