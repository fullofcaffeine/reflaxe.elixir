package reflaxe.elixir;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr.Binop;
import haxe.macro.Expr.Unop;
import haxe.macro.Expr.Constant as TConstant;

import reflaxe.DirectToStringCompiler;
import reflaxe.data.ClassFuncData;
import reflaxe.data.ClassVarData;  
import reflaxe.data.EnumOptionData;
import reflaxe.elixir.helpers.NamingHelper;
import reflaxe.elixir.helpers.EnumCompiler;
import reflaxe.elixir.helpers.ClassCompiler;
import reflaxe.elixir.helpers.PatternMatcher;
import reflaxe.elixir.helpers.GuardCompiler;
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
class ElixirCompiler extends DirectToStringCompiler {
    
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
     * Compile Haxe enum to Elixir tagged tuples using enhanced EnumCompiler
     */
    public function compileEnumImpl(enumType: EnumType, options: Array<EnumOptionData>): Null<String> {
        if (enumType == null) return null;
        
        // Use the enhanced EnumCompiler helper for proper type integration
        var enumCompiler = new reflaxe.elixir.helpers.EnumCompiler(this.typer);
        return enumCompiler.compileEnum(enumType, options);
    }
    
    /**
     * Compile Haxe expressions to Elixir expressions
     */
    public function compileExpressionImpl(expr: TypedExpr, topLevel: Bool): Null<String> {
        if (expr == null) return null;
        
        // Comprehensive expression compilation
        return switch (expr.expr) {
            case TConst(constant):
                compileConstant(constant);
                
            case TLocal(v):
                NamingHelper.toSnakeCase(v.getNameOrNative());
                
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
                compileExpression(e) + "(" + el.map(compileExpression).join(", ") + ")";
                
            case TArrayDecl(el):
                "[" + el.map(compileExpression).join(", ") + "]";
                
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
                
            case TCall(TField(_, FEnum(enumType, enumField)), args):
                // Parameterized enum pattern: SomeEnum.Option(value) → {:option, value}
                var fieldName = NamingHelper.toSnakeCase(enumField.name);
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
                compileConstant(constant);
                
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
                NamingHelper.toSnakeCase(v.getNameOrNative());
                
            case TConst(constant):
                // Literal in pattern
                compileConstant(constant);
                
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
            params.push(NamingHelper.toSnakeCase(arg.name));
        }
        
        var paramStr = params.join(", ");
        var result = '  @doc "Generated from Haxe ${funcField.field.name}"\n';
        result += '  def ${funcName}(${paramStr}) do\n';
        
        if (funcField.expr != null) {
            result += '    # TODO: Compile function body\n';
            result += '    # ${funcField.expr.toString()}\n';
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
     * Helper: Compile constants to Elixir literals
     */
    private function compileConstant(constant: TConstant): String {
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
     * Override formatExpressionLine for Elixir syntax requirements
     */
    override function formatExpressionLine(expr: String): String {
        // Elixir doesn't need semicolons, but we might want other formatting
        return expr;
    }
}

#end