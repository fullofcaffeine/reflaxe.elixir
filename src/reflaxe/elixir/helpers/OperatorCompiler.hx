package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import reflaxe.elixir.ElixirCompiler;import haxe.macro.Expr;
import reflaxe.elixir.ElixirCompiler;import haxe.macro.Expr.Binop;
import reflaxe.elixir.ElixirCompiler;import haxe.macro.Expr.Unop;
import reflaxe.elixir.ElixirCompiler;import reflaxe.BaseCompiler;
import reflaxe.elixir.ElixirCompiler;
using reflaxe.helpers.NullHelper;
using reflaxe.helpers.NameMetaHelper;
using reflaxe.helpers.SyntaxHelper;
using reflaxe.helpers.TypedExprHelper;
using StringTools;

/**
 * Operator Compiler for Reflaxe.Elixir
 * 
 * WHY: The compileElixirExpressionInternal function contained ~453 lines of operator compilation
 * logic scattered across TBinop and TUnop cases. This massive complexity included string
 * concatenation handling, assignment operators, arithmetic operations, logical operators,
 * and special Elixir-specific transformations. Having all this in one function violated
 * Single Responsibility Principle and made operator logic difficult to maintain and extend.
 * 
 * WHAT: Specialized compiler for all binary and unary operator expressions in Haxe-to-Elixir transpilation:
 * - Binary operators (TBinop) → Elixir arithmetic, logical, and assignment operations
 * - String concatenation detection → Elixir <> operator instead of +
 * - Assignment operators → Proper Elixir variable assignment and struct updates
 * - Compound assignment (+=, -=, etc.) → Elixir pattern matching updates
 * - Comparison operators → Elixir comparison with proper type handling
 * - Logical operators → Elixir and/or/not with short-circuit evaluation
 * - Unary operators (TUnop) → Elixir negation, increment, decrement patterns
 * - Type-aware operator selection based on operand types
 * 
 * HOW: The compiler implements sophisticated operator transformation patterns:
 * 1. Receives TBinop/TUnop expressions from ExpressionDispatcher
 * 2. Analyzes operand types to determine appropriate Elixir operator
 * 3. Applies string concatenation detection and <>  transformation
 * 4. Handles struct field assignment with proper pattern matching
 * 5. Generates idiomatic Elixir operators with correct precedence
 * 6. Integrates with LiteralCompiler for string escaping reuse
 * 
 * ARCHITECTURE BENEFITS:
 * - Single Responsibility: Focused solely on operator expression compilation
 * - Type Safety: Proper operand type analysis for operator selection
 * - Code Reuse: Leverages LiteralCompiler for string escaping utilities
 * - Maintainability: Clear separation from control flow and variable logic
 * - Testability: Operator logic can be independently tested and verified
 * - Extensibility: Easy to add new operator patterns and transformations
 * 
 * EDGE CASES:
 * - String concatenation detection with mixed string/non-string operands
 * - Compound assignment to struct fields requiring pattern matching syntax
 * - Type conversion for mixed-type arithmetic operations
 * - Short-circuit evaluation for logical operators
 * - Operator precedence handling in complex expressions
 * 
 * @see documentation/OPERATOR_COMPILATION_PATTERNS.md - Complete operator transformation patterns
 */
@:nullSafety(Off)
class OperatorCompiler {
    
    var compiler: reflaxe.elixir.ElixirCompiler; // ElixirCompiler reference
    var literalCompiler: LiteralCompiler; // For string escaping reuse
    
    /**
     * Create a new operator compiler
     * 
     * @param compiler The main ElixirCompiler instance
     * @param literalCompiler LiteralCompiler for string utility reuse
     */
    public function new(compiler: Dynamic, literalCompiler: LiteralCompiler) {
        this.compiler = compiler;
        this.literalCompiler = literalCompiler;
    }
    
    /**
     * Compile TBinop binary operator expressions
     * 
     * WHY: Binary operators need complex type-aware transformation for idiomatic Elixir
     * 
     * WHAT: Transform Haxe binary operators to appropriate Elixir equivalents with proper typing
     * 
     * HOW:
     * 1. Analyze operator type and operand types
     * 2. Apply string concatenation detection (+ → <>)
     * 3. Handle assignment and compound assignment operators
     * 4. Generate proper Elixir operator expressions with correct precedence
     * 
     * @param op Binary operator type
     * @param e1 Left operand expression
     * @param e2 Right operand expression
     * @return Compiled Elixir binary operator expression
     */
    public function compileBinaryOperation(op: Binop, e1: TypedExpr, e2: TypedExpr): String {
        #if debug_operator_compiler
        trace("[XRay OperatorCompiler] BINARY OPERATION START");
        trace('[XRay OperatorCompiler] Operator: ${op}');
        trace('[XRay OperatorCompiler] Left type: ${e1.t}');
        trace('[XRay OperatorCompiler] Right type: ${e2.t}');
        #end
        
        // BASIC IMPLEMENTATION: Handle common binary operators
        // Special handling for OpAssign with _this variable
        var left = if (op == OpAssign) {
            switch (e1.expr) {
                case TLocal(v) if (v.name == "_this" && compiler.currentFunctionParameterMap.exists("_this")):
                    // Replace _this with mapped parameter name (usually "struct")
                    compiler.currentFunctionParameterMap.get("_this");
                default:
                    compiler.compileExpression(e1);
            }
        } else {
            compiler.compileExpression(e1);
        }
        // Also handle _this in right-hand expressions (especially in struct updates)
        var compiledRight = compiler.compileExpression(e2);
        var right = if (op == OpAssign && compiler.currentFunctionParameterMap.exists("_this")) {
            // Replace _this references in struct updates or any assignment right-hand side
            var structParam = compiler.currentFunctionParameterMap.get("_this");
            StringTools.replace(compiledRight, "_this", structParam);
        } else {
            compiledRight;
        };
        
        var result = switch(op) {
            // Arithmetic operators
            case OpAdd: 
                // Handle string concatenation vs numeric addition
                if (isStringConcatenation(e1, e2)) {
                    compileStringConcatenation(e1, e2);
                } else {
                    '(${left} + ${right})';
                }
            case OpSub: '(${left} - ${right})';
            case OpMult: '(${left} * ${right})';
            case OpDiv: '(${left} / ${right})';
            case OpMod: 'rem(${left}, ${right})'; // Elixir uses rem() for modulo
            
            // Comparison operators
            case OpEq: '(${left} == ${right})';
            case OpNotEq: '(${left} != ${right})';
            case OpGt: '(${left} > ${right})';
            case OpGte: '(${left} >= ${right})';
            case OpLt: '(${left} < ${right})';
            case OpLte: '(${left} <= ${right})';
            
            // Logical operators
            case OpAnd: '(${left} and ${right})';
            case OpOr: '(${left} or ${right})';
            
            // Bitwise operators (using Elixir's Bitwise module)
            case OpXor: 'Bitwise.bxor(${left}, ${right})';
            case OpShl: 'Bitwise.bsl(${left}, ${right})'; // Bit shift left
            case OpShr: 'Bitwise.bsr(${left}, ${right})'; // Bit shift right
            case OpUShr: 'Bitwise.bsr(${left}, ${right})'; // Unsigned right shift (same as signed in Elixir)
            
            // Assignment operators
            case OpAssign: 
                // Handle field assignments differently - they need Map update syntax in Elixir
                if (isFieldAssignment(e1)) {
                    compileFieldAssignment(e1, e2);
                } else {
                    '${left} = ${right}';
                }
            case OpAssignOp(op):
                // Compound assignment operators (+=, -=, etc.)
                compileCompoundAssignment(op, e1, e2, left, right);
            
            // Special operators
            case OpBoolAnd: '(${left} && ${right})'; // Short-circuit boolean and
            case OpBoolOr: '(${left} || ${right})';  // Short-circuit boolean or
            case OpInterval: '${left}..${right}';    // Range operator for Elixir ranges
            case OpArrow: '${left} -> ${right}';     // Lambda arrow (used in pattern matching)
            case OpIn: '${left} in ${right}';        // Iteration operator (used in for-in loops)
            case OpNullCoal: '${left} || ${right}';  // Null coalescing operator
        };
        
        #if debug_operator_compiler
        trace('[XRay OperatorCompiler] Generated binary op: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        trace("[XRay OperatorCompiler] BINARY OPERATION END");
        #end
        
        return result;
    }
    
    /**
     * Compile TUnop unary operator expressions
     * 
     * WHY: Unary operators need proper transformation to Elixir equivalents
     * 
     * WHAT: Transform Haxe unary operators to idiomatic Elixir unary expressions
     * 
     * HOW:
     * 1. Analyze unary operator type and operand
     * 2. Handle negation, increment, decrement operations
     * 3. Generate appropriate Elixir unary operator syntax
     * 
     * @param op Unary operator type
     * @param postFix Whether operator is postfix
     * @param e Operand expression
     * @return Compiled Elixir unary operator expression
     */
    public function compileUnaryOperation(op: Unop, postFix: Bool, e: TypedExpr): String {
        #if debug_operator_compiler
        trace("[XRay OperatorCompiler] UNARY OPERATION START");
        trace('[XRay OperatorCompiler] Operator: ${op}');
        trace('[XRay OperatorCompiler] Postfix: ${postFix}');
        trace('[XRay OperatorCompiler] Operand type: ${e.t}');
        #end
        
        // BASIC IMPLEMENTATION: Handle common unary operators
        var operand = compiler.compileExpression(e);
        
        var result = switch(op) {
            case OpNot: 'not ${operand}';
            case OpNeg: '-${operand}';
            case OpNegBits: 'Bitwise.bnot(${operand})'; // Bitwise NOT
            
            // Increment/Decrement - Convert to idiomatic Elixir patterns
            case OpIncrement: 
                // Elixir doesn't have ++ operator, convert to addition
                if (postFix) {
                    // For postfix, we need to return old value but this is complex in functional context
                    // For now, just do the increment
                    '${operand} + 1';
                } else {
                    '${operand} + 1';
                }
            case OpDecrement:
                // Elixir doesn't have -- operator, convert to subtraction
                if (postFix) {
                    // For postfix, we need to return old value but this is complex in functional context
                    '${operand} - 1';
                } else {
                    '${operand} - 1';
                }
            
            // Type operations
            case OpSpread: '...${operand}'; // Spread operator for pattern matching
        };
        
        #if debug_operator_compiler
        trace('[XRay OperatorCompiler] Generated unary op: ${result != null ? result.substring(0, 100) + "..." : "null"}');
        trace("[XRay OperatorCompiler] UNARY OPERATION END");
        #end
        
        return result;
    }
    
    /**
     * Utility: Detect string concatenation in binary operations
     * 
     * WHY: String concatenation needs to use <> operator in Elixir, not +
     * 
     * @param e1 Left operand
     * @param e2 Right operand
     * @return True if this should be string concatenation
     */
    private function isStringConcatenation(e1: TypedExpr, e2: TypedExpr): Bool {
        return compiler.isStringType(e1.t) || compiler.isStringType(e2.t);
    }
    
    /**
     * Utility: Compile string concatenation with proper escaping
     * 
     * WHY: String concatenation needs proper escaping and <> operator usage
     * 
     * @param e1 Left operand
     * @param e2 Right operand
     * @return Compiled Elixir string concatenation
     */
    private function compileStringConcatenation(e1: TypedExpr, e2: TypedExpr): String {
        var left = switch (e1.expr) {
            case TConst(TString(s)): 
                literalCompiler.compileStringLiteral(s);
            case _: 
                compiler.compileExpression(e1);
        };
        
        var right = switch (e2.expr) {
            case TConst(TString(s)): 
                literalCompiler.compileStringLiteral(s);
            case _: 
                compiler.compileExpression(e2);
        };
        
        // Convert non-string operands to strings
        if (!compiler.isStringType(e1.t) && compiler.isStringType(e2.t)) {
            left = convertToString(e1, left);
        } else if (compiler.isStringType(e1.t) && !compiler.isStringType(e2.t)) {
            right = convertToString(e2, right);
        }
        
        return '${left} <> ${right}';
    }
    
    /**
     * Utility: Convert expression to string for concatenation
     * 
     * @param expr Original expression
     * @param compiled Compiled expression string
     * @return String conversion expression
     */
    private function convertToString(expr: TypedExpr, compiled: String): String {
        return switch (expr.t) {
            case TInst(t, _) if (t.get().name == "Int"): 'Integer.to_string(${compiled})';
            case TInst(t, _) if (t.get().name == "Float"): 'Float.to_string(${compiled})';
            case TAbstract(t, _) if (t.get().name == "Bool"): 'Atom.to_string(${compiled})';
            case _: 'to_string(${compiled})';
        };
    }
    
    /**
     * Compile compound assignment operators (+=, -=, *=, etc.)
     * 
     * WHY: Compound assignments need to handle Elixir's immutability patterns.
     * With state threading, field compound assignments need special transformation.
     * 
     * WHAT: Transform x += y to x = x + y, with special handling for struct fields
     * in state threading mode.
     * 
     * HOW:
     * - Normal: x += y becomes x = x + y
     * - State threading field: this.count += 1 becomes struct = %{struct | count: struct.count + 1}
     * 
     * @param op The inner binary operator (+, -, *, etc.)
     * @param e1 Left side expression (variable being assigned to)
     * @param e2 Right side expression (value being operated with)
     * @param left Compiled left side
     * @param right Compiled right side
     * @return Compiled Elixir compound assignment
     */
    private function compileCompoundAssignment(op: Binop, e1: TypedExpr, e2: TypedExpr, left: String, right: String): String {
        #if debug_operator_compiler
        trace("[XRay OperatorCompiler] COMPOUND ASSIGNMENT START");
        trace('[XRay OperatorCompiler] Inner operator: ${op}');
        #end
        
        /**
         * STATE THREADING CHECK FOR COMPOUND ASSIGNMENTS
         * 
         * WHY: Field compound assignments need Map update syntax in state threading
         * WHAT: Check if this is a field assignment that needs transformation
         * HOW: Transform this.field += value to struct = %{struct | field: struct.field + value}
         */
        if (compiler.isStateThreadingEnabled() && isFieldAssignment(e1)) {
            switch (e1.expr) {
                case TField(obj, fieldAccess):
                    // Check if this is a 'this' field access
                    var isThisAccess = switch (obj.expr) {
                        case TConst(TThis): true;
                        case TLocal(v) if (v.name == "this" || v.name == "_this"): true;
                        case _: false;
                    };
                    
                    if (isThisAccess) {
                        // Extract field name
                        var fieldName = switch (fieldAccess) {
                            case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf): 
                                NamingHelper.toSnakeCase(cf.get().name);
                            case FEnum(_, ef): 
                                NamingHelper.toSnakeCase(ef.name);
                            case FClosure(_, cf): 
                                NamingHelper.toSnakeCase(cf.get().name);
                            case FDynamic(s): 
                                NamingHelper.toSnakeCase(s);
                            case _: 
                                "unknown_field";
                        };
                        
                        // Build the operation expression
                        var operation = switch(op) {
                            case OpAdd: 
                                if (isStringConcatenation(e1, e2)) {
                                    'struct.${fieldName} <> ${right}';
                                } else {
                                    'struct.${fieldName} + ${right}';
                                }
                            case OpSub: 'struct.${fieldName} - ${right}';
                            case OpMult: 'struct.${fieldName} * ${right}';
                            case OpDiv: 'struct.${fieldName} / ${right}';
                            case OpMod: 'rem(struct.${fieldName}, ${right})';
                            case OpXor: 'Bitwise.bxor(struct.${fieldName}, ${right})';
                            case OpShl: 'Bitwise.bsl(struct.${fieldName}, ${right})';
                            case OpShr: 'Bitwise.bsr(struct.${fieldName}, ${right})';
                            case OpUShr: 'Bitwise.bsr(struct.${fieldName}, ${right})';
                            case OpOr: 'struct.${fieldName} or ${right}';
                            case OpAnd: 'struct.${fieldName} and ${right}';
                            default: 'struct.${fieldName} UNKNOWN_COMPOUND_OP_${op} ${right}';
                        };
                        
                        #if debug_state_threading
                        trace('[OperatorCompiler] State threading compound assignment: this.${fieldName} ${op}= value');
                        trace('[OperatorCompiler] Transforming to: struct = %{struct | ${fieldName}: ${operation}}');
                        #end
                        
                        // Return the struct update
                        return 'struct = %{struct | ${fieldName}: ${operation}}';
                    }
                case _:
                    // Not a field assignment
            }
        }
        
        // Normal compound assignment expansion: x += y → x = x + y
        var expandedOp = switch(op) {
            case OpAdd: 
                if (isStringConcatenation(e1, e2)) {
                    '${left} <> ${right}';
                } else {
                    '${left} + ${right}';
                }
            case OpSub: '${left} - ${right}';
            case OpMult: '${left} * ${right}';
            case OpDiv: '${left} / ${right}';
            case OpMod: 'rem(${left}, ${right})';
            case OpXor: 'Bitwise.bxor(${left}, ${right})';
            case OpShl: 'Bitwise.bsl(${left}, ${right})';
            case OpShr: 'Bitwise.bsr(${left}, ${right})';
            case OpUShr: 'Bitwise.bsr(${left}, ${right})';
            case OpOr: '${left} or ${right}';
            case OpAnd: '${left} and ${right}';
            default: '${left} UNKNOWN_COMPOUND_OP_${op} ${right}';
        };
        
        var result = '${left} = ${expandedOp}';
        
        #if debug_operator_compiler
        trace('[XRay OperatorCompiler] Generated compound assignment: ${result}');
        trace("[XRay OperatorCompiler] COMPOUND ASSIGNMENT END");
        #end
        
        return result;
    }
    
    /**
     * Check if expression is a field assignment (obj.field = value)
     * 
     * WHY: Field assignments need special handling in Elixir due to immutability
     * WHAT: Detects when the left-hand side of assignment is a field access
     * HOW: Checks if expression is TField accessing object property
     * 
     * @param expr Expression to check
     * @return True if this is a field assignment
     */
    private function isFieldAssignment(expr: TypedExpr): Bool {
        return switch (expr.expr) {
            case TField(obj, fieldAccess): true; // obj.field pattern
            case _: false;
        };
    }

    /**
     * Check if an expression is a complex field assignment with variable reassignment
     * 
     * WHY: Complex patterns like "struct = struct.buf; struct.b = ..." need special handling
     * WHAT: Detect variable reassignment followed by field assignment on the same variable
     * HOW: Analyze if variable is being reassigned to a field access of itself
     * 
     * @param left Left side of assignment (variable name)
     * @param right Right side of assignment (field access expression)
     * @param varName Variable name being assigned to
     * @return True if this is a variable reassignment that will lead to field mutations
     */
    private function isComplexFieldAssignment(left: TypedExpr, right: TypedExpr, varName: String): Bool {
        // Check if we're assigning a variable to a field access of itself
        // Pattern: struct = struct.buf (variable = variable.field)
        return switch(right.expr) {
            case TField(obj, fieldAccess): 
                // Check if the object being accessed matches the variable being assigned
                switch(obj.expr) {
                    case TLocal(localVar): localVar.name == varName;
                    case _: false;
                };
            case _: false;
        };
    }
    
    /**
     * Compile field assignment using Elixir Map update syntax
     * 
     * WHY: Elixir structs/maps are immutable, can't use obj.field = value syntax.
     * With state threading enabled, we also need to update the struct variable itself.
     * 
     * WHAT: Transform field assignment to Map update pattern, with special handling
     * for state threading mode where assignments must update the struct variable.
     * 
     * HOW: 
     * - Normal mode: Generate %{obj | field: value}
     * - State threading: Generate struct = %{struct | field: value}
     * 
     * EDGE CASES:
     * - Nested field updates (this.data.value)
     * - Field updates with operations (this.count += 1)
     * - Complex update patterns (struct.b = struct.b <> "text")
     * 
     * @param fieldExpr The field access expression (left-hand side)
     * @param valueExpr The value expression (right-hand side) 
     * @return Compiled Elixir Map update expression
     */
    private function compileFieldAssignment(fieldExpr: TypedExpr, valueExpr: TypedExpr): String {
        switch (fieldExpr.expr) {
            case TField(obj, fieldAccess):
                /**
                 * STATE THREADING CHECK
                 * 
                 * WHY: When state threading is enabled, field assignments must update the struct variable
                 * WHAT: Check if we're in state threading mode and if the object is 'this'
                 * HOW: Transform this.field = value to struct = %{struct | field: value}
                 */
                var isStateThreading = compiler.isStateThreadingEnabled();
                var isThisAccess = false;
                
                // Check if we're accessing 'this' (which maps to 'struct' in state threading)
                switch (obj.expr) {
                    case TConst(TThis):
                        isThisAccess = true;
                    case TLocal(v) if (v.name == "this" || v.name == "_this"):
                        isThisAccess = true;
                    case _:
                        // Not a 'this' access
                }
                
                // In state threading mode with 'this' access, use 'struct' directly
                var objCompiled = if (isStateThreading && isThisAccess) {
                    "struct";
                } else {
                    compiler.compileExpression(obj);
                };
                var valueCompiled = compiler.compileExpression(valueExpr);
                
                // Extract field name and convert to snake_case for Elixir
                var fieldName = switch (fieldAccess) {
                    case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf): 
                        NamingHelper.toSnakeCase(cf.get().name);
                    case FEnum(_, ef): 
                        NamingHelper.toSnakeCase(ef.name);
                    case FClosure(_, cf): 
                        NamingHelper.toSnakeCase(cf.get().name);
                    case FDynamic(s): 
                        NamingHelper.toSnakeCase(s);
                    case _: 
                        "unknown_field";
                };
                
                // Check if this is a complex field assignment that needs special handling
                // Pattern: struct.b = struct.b <> "something" where struct was just reassigned
                if (isComplexFieldUpdatePattern(objCompiled, fieldName, valueExpr)) {
                    var complexUpdate = compileComplexFieldUpdate(objCompiled, fieldName, valueExpr);
                    
                    // Apply state threading transformation if needed
                    if (isStateThreading && isThisAccess) {
                        return 'struct = ${complexUpdate}';
                    }
                    return complexUpdate;
                }
                
                // Generate Map update syntax
                var mapUpdate = '%{${objCompiled} | ${fieldName}: ${valueCompiled}}';
                
                /**
                 * STATE THREADING TRANSFORMATION
                 * 
                 * WHY: In state threading mode, we need to update the struct variable
                 * WHAT: Wrap the map update in a struct assignment
                 * HOW: struct = %{struct | field: value}
                 */
                if (isStateThreading && isThisAccess) {
                    #if debug_state_threading
                    trace('[OperatorCompiler] State threading field assignment: this.${fieldName} = value');
                    trace('[OperatorCompiler] Transforming to: struct = %{struct | ${fieldName}: value}');
                    #end
                    
                    return 'struct = ${mapUpdate}';
                }
                
                // Normal mode - just return the map update
                return mapUpdate;
                
            case _:
                // Fallback - shouldn't happen but handle gracefully
                return '${compiler.compileExpression(fieldExpr)} = ${compiler.compileExpression(valueExpr)}';
        }
    }

    /**
     * Check if this is a complex field update pattern that needs transformation
     * 
     * WHY: Patterns like struct.b = struct.b <> "text" need special handling in immutable context
     * WHAT: Detect when field assignment references the same field in the value expression
     * HOW: Analyze if the value expression contains a field access to the same object/field
     * 
     * @param objCompiled The compiled object expression
     * @param fieldName The field being assigned to
     * @param valueExpr The value expression being assigned
     * @return True if this is a complex field update pattern
     */
    private function isComplexFieldUpdatePattern(objCompiled: String, fieldName: String, valueExpr: TypedExpr): Bool {
        // Look for patterns where the value expression references the same field
        // Example: struct.b = struct.b <> "text"
        switch (valueExpr.expr) {
            case TBinop(op, e1, e2):
                // Check if left operand is a field access to the same field
                switch (e1.expr) {
                    case TField(obj, fieldAccess):
                        var leftFieldName = switch (fieldAccess) {
                            case FInstance(_, _, cf) | FStatic(_, cf) | FAnon(cf): cf.get().name;
                            case FEnum(_, ef): ef.name;
                            case FClosure(_, cf): cf.get().name;
                            case FDynamic(s): s;
                            case _: "unknown_field";
                        };
                        
                        var leftObjCompiled = compiler.compileExpression(obj);
                        
                        // Check if it's the same object and field
                        return leftObjCompiled == objCompiled && leftFieldName == fieldName;
                    case _: return false;
                }
            case _: return false;
        }
    }

    /**
     * Compile complex field update pattern with proper Map syntax
     * 
     * WHY: Transform struct.b = struct.b <> "text" to proper immutable update
     * WHAT: Generate Map update that handles the field reference correctly
     * HOW: Transform to %{obj | field: obj.field <> "text"} or similar pattern
     * 
     * @param objCompiled The compiled object expression
     * @param fieldName The field being updated
     * @param valueExpr The value expression (contains the operation)
     * @return Compiled Map update expression
     */
    private function compileComplexFieldUpdate(objCompiled: String, fieldName: String, valueExpr: TypedExpr): String {
        var valueCompiled = compiler.compileExpression(valueExpr);
        
        // For complex updates, we need to generate the proper Map update syntax
        // The value expression already contains the field reference, so we can use it directly
        return '%{${objCompiled} | ${fieldName}: ${valueCompiled}}';
    }
    
    /**
     * TODO: Future implementation will contain the extracted logic:
     * 
     * - Full TBinop compilation with all operator types
     * - String concatenation detection and transformation
     * - Assignment and compound assignment operators
     * - Struct field assignment with pattern matching
     * - Type-aware operator selection
     * - Full TUnop compilation with increment/decrement patterns
     * - Operator precedence handling
     * - Short-circuit evaluation for logical operators
     * 
     * Each method above will be filled with the actual extracted logic
     * from the original compileElixirExpressionInternal function.
     */
}

#end