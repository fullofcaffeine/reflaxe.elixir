package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.helpers.MigrationDSL;

/**
 * REFACTOR Phase: Enhanced MigrationDSL integration tests
 * Tests optimization and integration with ElixirCompiler and Mix tasks
 */
class MigrationRefactorTest {
    public static function main(): Void {
        trace("🔵 Starting REFACTOR Phase: Enhanced MigrationDSL Tests");
        
        // Test 1: Advanced table operations
        var tableName = "users";
        var columnName = "email";
        
        var addColumn = MigrationDSL.generateAddColumn(tableName, columnName, "string", "null: false");
        if (addColumn.indexOf("add :email, :string, null: false") == -1) {
            throw "FAIL: Add column should include options";
        }
        
        var dropColumn = MigrationDSL.generateDropColumn(tableName, columnName);
        if (dropColumn.indexOf("remove :email") == -1) {
            throw "FAIL: Drop column should generate remove statement";
        }
        
        trace("✅ Test 1 PASS: Advanced table operations");
        
        // Test 2: Foreign key constraint generation
        var foreignKey = MigrationDSL.generateForeignKey("posts", "user_id", "users", "id");
        if (foreignKey.indexOf("references(:users, column: :id)") == -1) {
            throw "FAIL: Foreign key should reference users table";
        }
        
        trace("✅ Test 2 PASS: Foreign key constraint generation");
        
        // Test 3: Custom constraint generation
        var constraint = MigrationDSL.generateConstraint("users", "email_format", "check", "email ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$'");
        if (constraint.indexOf("create constraint(:users, :email_format") == -1) {
            throw "FAIL: Constraint should be created on users table";
        }
        
        trace("✅ Test 3 PASS: Custom constraint generation");
        
        // Test 4: CamelCase to snake_case conversion
        var testCases = [
            {input: "CreateUsersTable", expected: "create_users_table"},
            {input: "AlterPostCommentsTable", expected: "alter_post_comments_table"},
            {input: "AddEmailToUsers", expected: "add_email_to_users"}
        ];
        
        for (testCase in testCases) {
            var result = MigrationDSL.camelCaseToSnakeCase(testCase.input);
            if (result != testCase.expected) {
                throw "FAIL: Expected " + testCase.expected + ", got " + result;
            }
        }
        
        trace("✅ Test 4 PASS: CamelCase to snake_case conversion");
        
        // Test 5: Timestamp generation
        var timestamp1 = MigrationDSL.generateTimestamp();
        var timestamp2 = MigrationDSL.generateTimestamp(); 
        
        if (timestamp1.length != 14) {
            throw "FAIL: Timestamp should be 14 characters (YYYYMMDDHHMMSS)";
        }
        
        // Timestamps should be different (assuming test runs quickly)
        if (timestamp1 == timestamp2) {
            // This might fail occasionally, but generally timestamps should differ
            trace("⚠️ Warning: Timestamps are identical - this is rare but possible");
        }
        
        trace("✅ Test 5 PASS: Timestamp generation");
        
        // Test 6: Data migration generation
        var dataMigration = MigrationDSL.generateDataMigration(
            "MigrateUserEmails",
            "execute(\"UPDATE users SET email = LOWER(email)\")",
            "execute(\"-- No rollback for data transformation\")"
        );
        
        if (dataMigration.indexOf("defmodule Repo.Migrations.MigrateUserEmails do") == -1) {
            throw "FAIL: Data migration should have proper module name";
        }
        
        if (dataMigration.indexOf("UPDATE users SET email") == -1) {
            throw "FAIL: Data migration should include SQL update";
        }
        
        trace("✅ Test 6 PASS: Data migration generation");
        
        // Test 7: Batch compilation performance with complex migrations
        var complexMigrations = new Array<Dynamic>();
        for (i in 0...20) {
            complexMigrations.push({
                className: "ComplexMigration" + i,
                timestamp: "2025080818000" + (i < 10 ? "0" + i : Std.string(i)),
                tableName: "complex_table_" + i,
                columns: ["id:integer", "name:string", "email:string", "created_at:datetime", "updated_at:datetime"]
            });
        }
        
        var startTime = haxe.Timer.stamp();
        var batchResult = MigrationDSL.compileBatchMigrations(complexMigrations);
        var endTime = haxe.Timer.stamp();
        var batchTime = (endTime - startTime) * 1000;
        
        if (batchTime > 15) {
            throw "FAIL: Batch compilation should be <15ms, got " + batchTime + "ms";
        }
        
        // Verify all migrations are in batch result
        for (migration in complexMigrations) {
            if (batchResult.indexOf("defmodule Repo.Migrations." + migration.className) == -1) {
                throw "FAIL: Batch result should contain " + migration.className;
            }
        }
        
        trace("✅ Test 7 PASS: Batch compilation performance: " + batchTime + "ms for 20 migrations");
        
        // Test 8: Schema validation integration
        var existingTables = ["users", "posts", "comments"];
        var migrationData = {
            className: "CreateProfilesTable",
            tableName: "profiles",
            columns: ["user_id:integer", "bio:text"]
        };
        
        var isValid = MigrationDSL.validateMigrationAgainstSchema(migrationData, existingTables);
        if (!isValid) {
            throw "FAIL: Valid migration should pass schema validation";
        }
        
        trace("✅ Test 8 PASS: Schema validation integration");
        
        // Test 9: Migration filename and path generation  
        var filename = MigrationDSL.generateMigrationFilename("CreateUsersTable", "20250808180000");
        var expectedFilename = "20250808180000_create_users_table.exs";
        
        if (filename != expectedFilename) {
            throw "FAIL: Expected filename " + expectedFilename + ", got " + filename;
        }
        
        var filepath = MigrationDSL.generateMigrationFilePath("CreateUsersTable", "20250808180000");
        var expectedPath = "priv/repo/migrations/20250808180000_create_users_table.exs";
        
        if (filepath != expectedPath) {
            throw "FAIL: Expected path " + expectedPath + ", got " + filepath;
        }
        
        trace("✅ Test 9 PASS: Migration filename and path generation");
        
        // Test 10: Complex migration with all features
        var advancedMigration = {
            className: "CreateAdvancedUsersTable",
            timestamp: "20250808180000",
            tableName: "advanced_users", 
            columns: [
                "name:string",
                "email:string", 
                "age:integer",
                "active:boolean",
                "profile_data:text",
                "created_at:datetime",
                "updated_at:datetime"
            ]
        };
        
        var compiledAdvanced = MigrationDSL.compileFullMigration(advancedMigration);
        
        var advancedChecks = [
            "defmodule Repo.Migrations.CreateAdvancedUsersTable do",
            "use Ecto.Migration",
            "create table(:advanced_users) do",
            "add :name, :string",
            "add :email, :string", 
            "add :age, :integer",
            "add :active, :boolean",
            "timestamps()",
            "create unique_index(:advanced_users, [:email])"
        ];
        
        for (check in advancedChecks) {
            if (compiledAdvanced.indexOf(check) == -1) {
                throw "FAIL: Advanced migration missing: " + check;
            }
        }
        
        trace("✅ Test 10 PASS: Complex migration with all features");
        
        trace("🔵 REFACTOR Phase Complete! All enhanced features working!");
        trace("✅ Ready for final integration verification");
    }
}

#end