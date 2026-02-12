package phoenix.hxx.ast;

/**
 * HeexNode (TSX template AST)
 *
 * WHAT
 * - Compile-time-only template node AST for TSX-mode HEEx authoring.
 *
 * WHY
 * - Inline/splice-only templates cannot express typed loops/conditionals without falling back to
 *   string-building (which HEEx escapes) or verbose helper calls.
 * - A real template AST lets the backend emit proper HEEx blocks (`for` / `if`) while keeping all
 *   embedded expressions as real Haxe AST (syntax + type checked).
 *
 * HOW
 * - TSX template macros parse markup into `HeexNode`/`HeexAttr` constructors.
 * - The backend recognizes `HeexTemplate.root_ast(node)` and prints HEEx directly.
 *
 * NOTE
 * - This module is compile-time only and is suppressed from emission in Elixir outputs.
 */
enum HeexNode {
	Text(value:String);
	ExprText<T>(value:T);

	Fragment(children:Array<HeexNode>);

	Element(name:String, attrs:Array<HeexAttr>, children:Array<HeexNode>);

	If(cond:Bool, thenBranch:HeexNode, elseBranch:Null<HeexNode>);

	For<T>(items:Iterable<T>, render:T->HeexNode);
}
