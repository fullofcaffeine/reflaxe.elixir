package reflaxe.elixir.ast.transformers;

#if (macro || reflaxe_runtime)

import haxe.macro.Context;
import haxe.macro.Expr;
import reflaxe.elixir.ast.ElixirAST;
import reflaxe.elixir.ast.ElixirAST.makeAST;
import reflaxe.elixir.ast.ElixirAST.makeASTWithMeta;
import reflaxe.elixir.ast.ElixirASTTransformer;
import reflaxe.elixir.ast.ElixirASTPrinter;

typedef MigrationCallStep = {name: String, args: Array<ElixirAST>};
typedef MigrationCallChain = {base: ElixirAST, calls: Array<MigrationCallStep>};
typedef MigrationColumnTypeInfo = {typeExpr: ElixirAST, extraOptions: Array<ElixirAST.EKeywordPair>};

/**
 * EctoMigrationExsTransforms
 *
 * WHAT
 * - When `-D ecto_migrations_exs` is enabled, rewrites Haxe-authored `@:migration` modules
 *   (which currently compile into nested builder calls like
 *     `_ = TableBuilder.add_column(Migration.create_table(struct, ...), ...)`)
 *   into runnable Ecto migrations:
 *     - Adds `use Ecto.Migration`
 *     - Rewrites `up/1` and `down/1` into `up/0` and `down/0`
 *     - Converts the builder chain into Ecto.Migration DSL calls (`create table(...) do ... end`,
 *       `create(index(...))`, `create(constraint(...))`, `drop(table(...))`)
 *
 * WHY
 * - Ecto only executes migrations from `priv/repo/migrations/*.exs` and expects each file to define
 *   a module using `Ecto.Migration` with arity-0 callbacks. The builder-chain output is useful for
 *   typed authoring/validation, but it is not runnable by Ecto.
 *
 * HOW
 * - Detect migration modules by presence of `def up`/`def down` (same gate as the stub pass).
 * - Parse each statement in the `up/1` and `down/1` bodies:
 *     - unwrap `_ = ...` matches (emitted to avoid unused-variable warnings), then
 *     - walk the nested builder call structure where each operation takes the previous builder
 *       as its first argument.
 * - Map recognized operations into Ecto DSL AST nodes.
 * - Replace the module body with a minimal `use` + `up/0` + `down/0` implementation.
 *
 * EXAMPLES
 * Haxe (authored):
 *   @:migration({timestamp: "20240101120000"})
 *   class CreateUsers extends Migration {
 *     public function up():Void createTable("users").addColumn("email", String(), {nullable:false}).addIndex(["email"], {unique:true});
 *     public function down():Void dropTable("users");
 *   }
 * Elixir (generated .exs):
 *   defmodule MyApp.Repo.Migrations.CreateUsers do
 *     use Ecto.Migration
 *     def up do
 *       create table(:users) do
 *         add(:email, :string, [null: false])
 *       end
 *       create(unique_index(:users, [:email]))
 *     end
 *     def down do
 *       drop(table(:users))
 *     end
 *   end
 */
class EctoMigrationExsTransforms {
    public static function transformPass(ast: ElixirAST): ElixirAST {
        #if !ecto_migrations_exs
        return ast;
        #else
        return ElixirASTTransformer.transformNode(ast, function(node: ElixirAST): ElixirAST {
            return switch (node.def) {
                case EModule(name, _attrs, body):
                    if (!isMigrationModule(node, body)) return node;
                    transformMigrationModule(name, node, body);
                default:
                    node;
            }
        });
        #end
    }

    static function isMigrationModule(node: ElixirAST, body: Array<ElixirAST>): Bool {
        // Prefer explicit metadata when available
        if (node.metadata != null && node.metadata.ectoContext != null) switch (node.metadata.ectoContext) {
            case Migration:
                return true;
            default:
        }

        var hasUpDown = false;
        for (b in body) switch (b.def) {
            case EDef("up", _, _, _) | EDef("down", _, _, _):
                hasUpDown = true;
            default:
        }
        return hasUpDown;
    }

    static function transformMigrationModule(name: String, node: ElixirAST, body: Array<ElixirAST>): ElixirAST {
        var upSource = findFunctionBody(body, "up");
        var downSource = findFunctionBody(body, "down");

        var upStatements = (upSource != null) ? buildUpStatements(upSource, node.pos) : null;
        var downStatements = (downSource != null) ? buildDownStatements(downSource, node.pos) : null;

        if (upStatements == null && downStatements == null) {
            return node;
        }

        var newBody: Array<ElixirAST> = [];
        newBody.push(makeAST(EUse("Ecto.Migration", [])));

        if (upStatements != null) {
            newBody.push(makeAST(EDef("up", [], null, makeAST(EBlock(upStatements)))));
        }
        if (downStatements != null) {
            newBody.push(makeAST(EDef("down", [], null, makeAST(EBlock(downStatements)))));
        }

        return makeASTWithMeta(EModule(name, [], newBody), node.metadata, node.pos);
    }

    static function findFunctionBody(body: Array<ElixirAST>, functionName: String): Null<ElixirAST> {
        for (b in body) {
            switch (b.def) {
                case EDef(name, _args, _guards, fnBody) if (name == functionName):
                    return fnBody;
                default:
            }
        }
        return null;
    }

    static function buildUpStatements(body: ElixirAST, pos: Position): Null<Array<ElixirAST>> {
        var statements = unwrapStatements(body);
        var out: Array<ElixirAST> = [];

        for (statement in statements) {
            var chain = extractCallChain(statement);
            if (chain == null) {
                if (isIgnorableStatement(statement)) continue;
                var rendered = ElixirASTPrinter.print(statement, 0);
                if (rendered.length > 220) rendered = rendered.substr(0, 220) + "...";
                compilerError('Unsupported migration up/0 body shape. Expected a builder call chain. Got: ${rendered}', pos);
                return null;
            }

            var built = buildUpStatementsFromChain(chain, pos);
            if (built == null) return null;
            out = out.concat(built);
        }

        if (out.length == 0) {
            compilerError("Unsupported migration up/0: no supported statements found.", pos);
            return null;
        }

        return out;
    }

    static function buildDownStatements(body: ElixirAST, pos: Position): Null<Array<ElixirAST>> {
        var statements = unwrapStatements(body);
        var out: Array<ElixirAST> = [];

        for (statement in statements) {
            var chain = extractCallChain(statement);
            if (chain == null) {
                if (isIgnorableStatement(statement)) continue;
                var rendered = ElixirASTPrinter.print(statement, 0);
                if (rendered.length > 220) rendered = rendered.substr(0, 220) + "...";
                compilerError('Unsupported migration down/0 body shape. Expected a builder call chain. Got: ${rendered}', pos);
                return null;
            }

            var built = buildDownStatementsFromChain(chain, pos);
            if (built == null) return null;
            out = out.concat(built);
        }

        if (out.length == 0) {
            compilerError("Unsupported migration down/0: no supported statements found.", pos);
            return null;
        }

        return out;
    }

    static function buildUpStatementsFromChain(chain: MigrationCallChain, pos: Position): Null<Array<ElixirAST>> {
        var first = chain.calls[0];
        return if (first.name == "create_table") {
            buildCreateTableStatementsFromChain(chain, pos);
        } else if (first.name == "alter_table") {
            buildAlterTableStatementsFromChain(chain, pos);
        } else {
            compilerError("Unsupported migration up/0: expected create_table(\"table\") or alter_table(\"table\").", pos);
            null;
        };
    }

    static function buildDownStatementsFromChain(chain: MigrationCallChain, pos: Position): Null<Array<ElixirAST>> {
        var first = chain.calls[0];
        if (first.name == "drop_table" && first.args.length >= 1) {
            var tableName = extractString(first.args[0]);
            if (tableName == null || tableName == "") {
                compilerError("Unsupported migration down/0: drop_table table name must be a string literal.", pos);
                return null;
            }
            var tableExpr = makeAST(ECall(null, "table", [makeAtom(tableName)]));
            return [makeAST(ECall(null, "drop", [tableExpr]))];
        }

        if (first.name == "alter_table") {
            return buildAlterTableStatementsFromChain(chain, pos);
        }

        compilerError("Unsupported migration down/0: expected drop_table(\"table\") or alter_table(\"table\").", pos);
        return null;
    }

    // ======================================================================
    // Builders
    // ======================================================================

    static function buildCreateTableStatementsFromChain(chain: MigrationCallChain, pos: Position): Null<Array<ElixirAST>> {
        var first = chain.calls[0];
        if (first.args.length < 1) {
            compilerError("Unsupported migration: create_table requires a string literal table name.", pos);
            return null;
        }

        var tableName = extractString(first.args[0]);
        if (tableName == null || tableName == "") {
            compilerError("Unsupported migration: create_table table name must be a string literal.", pos);
            return null;
        }

        var tableAtom = makeAtom(tableName);

        var tableBody: Array<ElixirAST> = [];
        var afterTable: Array<ElixirAST> = [];

        for (i in 1...chain.calls.length) {
            var call = chain.calls[i];
            switch (call.name) {
                case "add_id":
                    compilerError(
                        "Unsupported migration up/0: add_id is not supported in ecto_migrations_exs builds (custom primary keys require create table(..., primary_key: false)). Write a manual Elixir migration for custom primary keys.",
                        pos
                    );
                    return null;

                case "add_timestamps":
                    tableBody.push(makeAST(ECall(null, "timestamps", [])));

                case "add_column":
                    var columnName = (call.args.length > 0) ? extractString(call.args[0]) : null;
                    if (columnName == "id") {
                        compilerError(
                            "Unsupported migration up/0: adding an explicit \"id\" column is not supported in ecto_migrations_exs builds (create table defaults to an id primary key). Write a manual Elixir migration for custom primary keys.",
                            pos
                        );
                        return null;
                    }
                    var addStmt = buildAddColumn(call.args, pos);
                    if (addStmt != null) tableBody.push(addStmt);

                case "add_reference" | "add_foreign_key":
                    // add_foreign_key is an alias for add_reference/3 in the builder DSL.
                    var refStmt = buildAddReference(call.args, pos);
                    if (refStmt != null) tableBody.push(refStmt);

                case "add_index":
                    var indexStmt = buildCreateIndex(tableAtom, call.args, pos);
                    if (indexStmt != null) afterTable.push(indexStmt);

                case "add_unique_constraint":
                    var uniqueStmt = buildUniqueConstraint(tableAtom, call.args, pos);
                    if (uniqueStmt != null) afterTable.push(uniqueStmt);

                case "add_check_constraint":
                    var checkStmt = buildCheckConstraint(tableAtom, call.args, pos);
                    if (checkStmt != null) afterTable.push(checkStmt);

                default:
                    compilerError('Unsupported migration operation: ${call.name}.', pos);
                    return null;
            }
        }

        var tableExpr = makeAST(ECall(null, "table", [tableAtom]));
        var createTable = makeAST(EMacroCall("create", [tableExpr], makeAST(EBlock(tableBody))));
        return [createTable].concat(afterTable);
    }

    static function buildAlterTableStatementsFromChain(chain: MigrationCallChain, pos: Position): Null<Array<ElixirAST>> {
        var first = chain.calls[0];
        if (first.args.length < 1) {
            compilerError("Unsupported migration: alter_table requires a string literal table name.", pos);
            return null;
        }

        var tableName = extractString(first.args[0]);
        if (tableName == null || tableName == "") {
            compilerError("Unsupported migration: alter_table table name must be a string literal.", pos);
            return null;
        }

        var tableAtom = makeAtom(tableName);
        var tableExpr = makeAST(ECall(null, "table", [tableAtom]));

        var tableBody: Array<ElixirAST> = [];
        for (i in 1...chain.calls.length) {
            var call = chain.calls[i];
            switch (call.name) {
                case "add_column":
                    var addStmt = buildAddColumn(call.args, pos);
                    if (addStmt != null) tableBody.push(addStmt);

                case "remove_column":
                    var removeStmt = buildRemoveColumn(call.args, pos);
                    if (removeStmt != null) tableBody.push(removeStmt);

                case "modify_column":
                    var modifyStmt = buildModifyColumn(call.args, pos);
                    if (modifyStmt != null) tableBody.push(modifyStmt);

                default:
                    compilerError('Unsupported alter_table operation: ${call.name}.', pos);
                    return null;
            }
        }

        return [makeAST(EMacroCall("alter", [tableExpr], makeAST(EBlock(tableBody))))];
    }

    static function buildAddColumn(args: Array<ElixirAST>, pos: Position): Null<ElixirAST> {
        if (args.length < 2) {
            compilerError("addColumn expects at least (name, type).", pos);
            return null;
        }

        var columnName = extractString(args[0]);
        if (columnName == null || columnName == "") {
            compilerError("addColumn column name must be a string literal.", pos);
            return null;
        }

        var typeInfo = normalizeColumnType(args[1], pos);
        var keywordPairs = (args.length >= 3) ? normalizeColumnOptions(args[2], pos) : [];
        keywordPairs = keywordPairs.concat(typeInfo.extraOptions);

        var callArgs: Array<ElixirAST> = [makeAtom(columnName), typeInfo.typeExpr];
        if (keywordPairs.length > 0) {
            callArgs.push(makeAST(EKeywordList(keywordPairs)));
        }

        return makeAST(ECall(null, "add", callArgs));
    }

    static function buildRemoveColumn(args: Array<ElixirAST>, pos: Position): Null<ElixirAST> {
        if (args.length < 1) {
            compilerError("removeColumn expects (name).", pos);
            return null;
        }

        var columnName = extractString(args[0]);
        if (columnName == null || columnName == "") {
            compilerError("removeColumn column name must be a string literal.", pos);
            return null;
        }

        return makeAST(ECall(null, "remove", [makeAtom(columnName)]));
    }

    static function buildModifyColumn(args: Array<ElixirAST>, pos: Position): Null<ElixirAST> {
        if (args.length < 2) {
            compilerError("modifyColumn expects at least (name, type).", pos);
            return null;
        }

        var columnName = extractString(args[0]);
        if (columnName == null || columnName == "") {
            compilerError("modifyColumn column name must be a string literal.", pos);
            return null;
        }

        var typeInfo = normalizeColumnType(args[1], pos);
        var keywordPairs = (args.length >= 3) ? normalizeColumnOptions(args[2], pos) : [];
        keywordPairs = keywordPairs.concat(typeInfo.extraOptions);

        var callArgs: Array<ElixirAST> = [makeAtom(columnName), typeInfo.typeExpr];
        if (keywordPairs.length > 0) {
            callArgs.push(makeAST(EKeywordList(keywordPairs)));
        }

        return makeAST(ECall(null, "modify", callArgs));
    }

    static function buildAddReference(args: Array<ElixirAST>, pos: Position): Null<ElixirAST> {
        if (args.length < 2) {
            compilerError("addReference expects at least (columnName, referencedTable).", pos);
            return null;
        }

        var columnName = extractString(args[0]);
        var referencedTable = extractString(args[1]);
        if (columnName == null || referencedTable == null || columnName == "" || referencedTable == "") {
            compilerError("addReference expects string literal columnName and referencedTable.", pos);
            return null;
        }

        var refPairs = (args.length >= 3) ? normalizeReferenceOptions(args[2], pos) : [];
        var refCallArgs: Array<ElixirAST> = [makeAtom(referencedTable)];
        if (refPairs.length > 0) refCallArgs.push(makeAST(EKeywordList(refPairs)));

        var referencesCall = makeAST(ECall(null, "references", refCallArgs));
        return makeAST(ECall(null, "add", [makeAtom(columnName), referencesCall]));
    }

    static function buildCreateIndex(tableAtom: ElixirAST, args: Array<ElixirAST>, pos: Position): Null<ElixirAST> {
        if (args.length < 1) {
            compilerError("addIndex expects columns array.", pos);
            return null;
        }

        var columns = normalizeColumnsList(args[0], pos);
        if (columns == null) return null;

        var indexPairs = (args.length >= 2) ? normalizeIndexOptions(args[1], pos) : [];

        var isUnique = false;
        for (p in indexPairs) if (p.key == "unique") {
            switch (p.value.def) { case EBoolean(true): isUnique = true; default: }
        }

        // Prefer unique_index/3 over index(unique: true)
        var filteredPairs = indexPairs.filter(function(p) return p.key != "unique");
        var indexFn = isUnique ? "unique_index" : "index";

        var indexArgs: Array<ElixirAST> = [tableAtom, columns];
        if (filteredPairs.length > 0) indexArgs.push(makeAST(EKeywordList(filteredPairs)));
        var indexCall = makeAST(ECall(null, indexFn, indexArgs));
        return makeAST(ECall(null, "create", [indexCall]));
    }

    static function buildUniqueConstraint(tableAtom: ElixirAST, args: Array<ElixirAST>, pos: Position): Null<ElixirAST> {
        if (args.length < 1) {
            compilerError("addUniqueConstraint expects columns array.", pos);
            return null;
        }
        var columns = normalizeColumnsList(args[0], pos);
        if (columns == null) return null;

        var pairs: Array<ElixirAST.EKeywordPair> = [];
        if (args.length >= 2) {
            var name = extractString(args[1]);
            if (name != null && name != "") pairs.push({key: "name", value: makeAtom(name)});
        }

        var indexArgs: Array<ElixirAST> = [tableAtom, columns];
        if (pairs.length > 0) indexArgs.push(makeAST(EKeywordList(pairs)));
        var indexCall = makeAST(ECall(null, "unique_index", indexArgs));
        return makeAST(ECall(null, "create", [indexCall]));
    }

    static function buildCheckConstraint(tableAtom: ElixirAST, args: Array<ElixirAST>, pos: Position): Null<ElixirAST> {
        if (args.length < 2) {
            compilerError("addCheckConstraint expects (name, expression).", pos);
            return null;
        }

        var name = extractString(args[0]);
        var expression = extractString(args[1]);
        if (name == null || expression == null || name == "") {
            compilerError("addCheckConstraint expects string literal name and expression.", pos);
            return null;
        }

        var constraintCall = makeAST(ECall(null, "constraint", [
            tableAtom,
            makeAtom(name),
            makeAST(EKeywordList([{key: "check", value: makeAST(EString(expression))}]))
        ]));
        return makeAST(ECall(null, "create", [constraintCall]));
    }

    // ======================================================================
    // Normalizers
    // ======================================================================

    static function extractCallChain(expr: ElixirAST): Null<MigrationCallChain> {
        var current = unwrapStatement(expr);
        var reversedSteps: Array<MigrationCallStep> = [];

        while (true) {
            switch (current.def) {
                case ECall(_target, funcName, args):
                    if (args.length == 0) break;

                    var builder = unwrapStatement(args[0]);
                    var stepArgs = (args.length > 1) ? args.slice(1) : [];
                    reversedSteps.push({name: canonicalizeCallName(funcName), args: stepArgs});
                    current = builder;

                case ERemoteCall(_module, funcName, args):
                    if (args.length == 0) break;

                    var builder = unwrapStatement(args[0]);
                    var stepArgs = (args.length > 1) ? args.slice(1) : [];
                    reversedSteps.push({name: canonicalizeCallName(funcName), args: stepArgs});
                    current = builder;
                default:
                    break;
            }
        }

        if (reversedSteps.length == 0) return null;
        reversedSteps.reverse();
        return {base: current, calls: reversedSteps};
    }

    static inline function unwrap(expr: ElixirAST): ElixirAST {
        return switch (expr.def) {
            case EParen(inner):
                inner;
            default:
                expr;
        };
    }

    static function unwrapStatement(expr: ElixirAST): ElixirAST {
        var current = unwrap(expr);
        return switch (current.def) {
            case EMatch(_pattern, value):
                unwrapStatement(value);
            default:
                current;
        };
    }

    static function canonicalizeCallName(name: String): String {
        return switch (name) {
            case "createTable": "create_table";
            case "dropTable": "drop_table";
            case "alterTable": "alter_table";
            case "addId": "add_id";
            case "addTimestamps": "add_timestamps";
            case "addColumn": "add_column";
            case "removeColumn": "remove_column";
            case "modifyColumn": "modify_column";
            case "renameColumn": "rename_column";
            case "addReference": "add_reference";
            case "addForeignKey": "add_foreign_key";
            case "addIndex": "add_index";
            case "addUniqueConstraint": "add_unique_constraint";
            case "addCheckConstraint": "add_check_constraint";
            default: name;
        };
    }

    static function unwrapStatements(body: ElixirAST): Array<ElixirAST> {
        var unwrapped = unwrap(body);
        return switch (unwrapped.def) {
            case EBlock(expressions):
                expressions;
            case EDo(expressions):
                expressions;
            default:
                [unwrapped];
        };
    }

    static function isIgnorableStatement(statement: ElixirAST): Bool {
        return switch (unwrapStatement(statement).def) {
            case ENil:
                true;
            case EUnderscore:
                true;
            default:
                false;
        };
    }

    static function extractString(expr: ElixirAST): Null<String> {
        return switch (unwrap(expr).def) {
            case EString(value):
                value;
            default:
                null;
        };
    }

    static function makeAtom(value: String): ElixirAST {
        return makeAST(EAtom(value));
    }

    static function normalizeColumnsList(expr: ElixirAST, pos: Position): Null<ElixirAST> {
        return switch (unwrap(expr).def) {
            case EList(elements):
                var atoms: Array<ElixirAST> = [];
                for (element in elements) {
                    var str = extractString(element);
                    if (str == null) {
                        compilerError("Index columns must be string literals in Haxe (will become atoms).", pos);
                        return null;
                    }
                    atoms.push(makeAtom(str));
                }
                makeAST(EList(atoms));
            default:
                compilerError("Index columns must be a literal array in Haxe (will become an Elixir list).", pos);
                null;
        };
    }

    static function normalizeColumnType(expr: ElixirAST, pos: Position): MigrationColumnTypeInfo {
        var unwrapped = unwrap(expr);
        return switch (unwrapped.def) {
            case ETuple(elements) if (elements.length >= 1):
                switch (elements[0].def) {
                    case EAtom(typeAtom):
                        var tag = Std.string(typeAtom);
                        return normalizeColumnTuple(tag, elements, pos);
                    default:
                        {typeExpr: unwrapped, extraOptions: []};
                }
            case EAtom(_):
                {typeExpr: unwrapped, extraOptions: []};
            default:
                {typeExpr: unwrapped, extraOptions: []};
        };
    }

    static function normalizeColumnTuple(tag: String, elements: Array<ElixirAST>, pos: Position): MigrationColumnTypeInfo {
        return switch (tag) {
            case "string":
                // {:string} or {:string, length}
                if (elements.length >= 2) {
                    switch (elements[1].def) {
                        case EInteger(size):
                            return {
                                typeExpr: makeAtom("string"),
                                extraOptions: [{key: "size", value: makeAST(EInteger(size))}]
                            };
                        default:
                    }
                }
                {typeExpr: makeAtom("string"), extraOptions: []};

            case "decimal":
                // {:decimal, precision, scale}
                if (elements.length >= 3) {
                    var precision = elements[1];
                    var scale = elements[2];
                    return {
                        typeExpr: makeAtom("decimal"),
                        extraOptions: [
                            {key: "precision", value: precision},
                            {key: "scale", value: scale}
                        ]
                    };
                }
                {typeExpr: makeAtom("decimal"), extraOptions: []};

            case "array":
                // {:array, innerType} stays a tuple in Ecto
                if (elements.length >= 2) {
                    var inner = normalizeColumnType(elements[1], pos);
                    return {typeExpr: makeAST(ETuple([makeAtom("array"), inner.typeExpr])), extraOptions: inner.extraOptions};
                }
                {typeExpr: makeAST(ETuple([makeAtom("array"), makeAtom("string")])), extraOptions: []};

            case "date_time":
                // Haxe ColumnType.DateTime is modeled as NaiveDateTime in app code.
                {typeExpr: makeAtom("naive_datetime"), extraOptions: []};

            case "timestamp":
                {typeExpr: makeAtom("utc_datetime"), extraOptions: []};

            case "big_integer":
                {typeExpr: makeAtom("bigint"), extraOptions: []};

            case "json":
                {typeExpr: makeAtom("map"), extraOptions: []};

            case "json_array":
                {typeExpr: makeAST(ETuple([makeAtom("array"), makeAtom("map")])), extraOptions: []};

            case "references":
                // {:references, "users"} -> references(:users)
                if (elements.length >= 2) {
                    var referencedTable = extractString(elements[1]);
                    if (referencedTable != null && referencedTable != "") {
                        return {typeExpr: makeAST(ECall(null, "references", [makeAtom(referencedTable)])), extraOptions: []};
                    }
                }
                {typeExpr: makeAST(ECall(null, "references", [makeAtom("users")])), extraOptions: []};

            // All other atom-only constructors: map {:text} -> :text, {:integer} -> :integer, etc.
            default:
                {typeExpr: makeAtom(tag), extraOptions: []};
        };
    }

    static function normalizeColumnOptions(expr: ElixirAST, pos: Position): Array<ElixirAST.EKeywordPair> {
        var pairs = normalizeMapPairs(expr, pos);
        var out: Array<ElixirAST.EKeywordPair> = [];

        for (p in pairs) {
            switch (p.key) {
                case "nullable":
                    // Ecto uses `null: false` to enforce NOT NULL. Only emit when false.
                    switch (p.value.def) {
                        case EBoolean(false):
                            out.push({key: "null", value: makeAST(EBoolean(false))});
                        default:
                    }
                case "default_value":
                    out.push({key: "default", value: p.value});
                case "primary_key":
                    out.push(p);
                default:
                    // Ignore other builder-only column options for now
            }
        }

        return out;
    }

    static function normalizeReferenceOptions(expr: ElixirAST, pos: Position): Array<ElixirAST.EKeywordPair> {
        var pairs = normalizeMapPairs(expr, pos);
        var out: Array<ElixirAST.EKeywordPair> = [];

	        for (p in pairs) {
	            switch (p.key) {
	                case "on_delete":
	                    var mappedOnDelete = mapOnDelete(p.value);
	                    if (mappedOnDelete != null) out.push({key: "on_delete", value: mappedOnDelete});
	                case "on_update":
	                    var mappedOnUpdate = mapOnUpdate(p.value);
	                    if (mappedOnUpdate != null) out.push({key: "on_update", value: mappedOnUpdate});
	                case "column":
	                    var col = extractString(p.value);
	                    if (col != null && col != "") out.push({key: "column", value: makeAtom(col)});
	                default:
	            }
        }

        return out;
    }

    static function normalizeIndexOptions(expr: ElixirAST, pos: Position): Array<ElixirAST.EKeywordPair> {
        var pairs = normalizeMapPairs(expr, pos);
        var out: Array<ElixirAST.EKeywordPair> = [];

        for (p in pairs) {
            switch (p.key) {
                case "unique":
                    out.push({key: "unique", value: p.value});
                case "name":
                    var n = extractString(p.value);
                    if (n != null && n != "") out.push({key: "name", value: makeAtom(n)});
                case "where":
                    var w = extractString(p.value);
                    if (w != null && w != "") out.push({key: "where", value: makeAST(EString(w))});
                case "concurrently":
                    out.push({key: "concurrently", value: p.value});
                case "method":
                    var usingAtom = mapIndexMethod(p.value);
                    if (usingAtom != null) out.push({key: "using", value: usingAtom});
                default:
            }
        }

        return out;
    }

    static function normalizeMapPairs(expr: ElixirAST, pos: Position): Array<{key: String, value: ElixirAST}> {
        return switch (unwrap(expr).def) {
            case EMap(mapPairs):
                var out: Array<{key: String, value: ElixirAST}> = [];
                for (pair in mapPairs) {
                    var keyString = switch (pair.key.def) {
                        case EAtom(atomKey): Std.string(atomKey);
                        case EString(strKey): strKey;
                        default: null;
                    };
                    if (keyString != null) out.push({key: keyString, value: pair.value});
                }
                out;
            case ENil:
                [];
            default:
                compilerError("Expected options map.", pos);
                [];
        };
    }

    static function mapOnDelete(value: ElixirAST): Null<ElixirAST> {
        // Haxe enum atoms are emitted as {:cascade}, {:set_null}, etc.
        return switch (unwrap(value).def) {
            case ETuple(elements) if (elements.length >= 1):
                switch (elements[0].def) {
                    case EAtom(atomTag):
                        switch (Std.string(atomTag)) {
                            case "cascade": return makeAtom("delete_all");
                            case "set_null": return makeAtom("nilify_all");
                            case "restrict": return makeAtom("restrict");
                            case "no_action": return makeAtom("nothing");
                            default: return makeAtom("nothing");
                        }
                    default:
                        null;
                }
            default:
                null;
        };
    }

    static function mapOnUpdate(value: ElixirAST): Null<ElixirAST> {
        return switch (unwrap(value).def) {
            case ETuple(elements) if (elements.length >= 1):
                switch (elements[0].def) {
                    case EAtom(atomTag):
                        switch (Std.string(atomTag)) {
                            case "cascade": return makeAtom("update_all");
                            case "set_null": return makeAtom("nilify_all");
                            case "restrict": return makeAtom("restrict");
                            case "no_action": return makeAtom("nothing");
                            default: return makeAtom("nothing");
                        }
                    default:
                        null;
                }
            default:
                null;
        };
    }

    static function mapIndexMethod(value: ElixirAST): Null<ElixirAST> {
        return switch (unwrap(value).def) {
            case ETuple(elements) if (elements.length >= 1):
                switch (elements[0].def) {
                    case EAtom(atomTag):
                        var raw = Std.string(atomTag);
                        // Ecto expects :btree, but NameUtils emits :b_tree for Haxe enum BTree.
                        return makeAtom(raw == "b_tree" ? "btree" : raw);
                    default:
                        null;
                }
            default:
                null;
        };
    }

    static inline function compilerError(message: String, pos: Position): Void {
        #if macro
        Context.error(message, pos);
        #else
        // Runtime compilation has no Context; fail soft (tests will catch).
        #end
    }
}

#end
