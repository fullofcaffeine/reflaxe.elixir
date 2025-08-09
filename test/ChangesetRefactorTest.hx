package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.helpers.ChangesetCompiler;

/**
 * REFACTOR Phase: Enhanced ChangesetCompiler integration tests
 * Tests optimization and integration with ElixirCompiler
 */
class ChangesetRefactorTest {
    public static function main(): Void {
        trace("🔵 Starting REFACTOR Phase: Enhanced ChangesetCompiler Tests");
        
        // Test 1: Advanced validation pipeline generation
        var fields = ["name", "email", "password", "age"];
        var validations = ["validate_required([:name, :email, :password])", "validate_format(:email, ~r/@/)", "validate_length(:password, min: 8)"];
        
        var pipeline = ChangesetCompiler.generateValidationPipeline(fields, validations);
        
        if (pipeline.indexOf("cast(attrs, [:name, :email, :password, :age])") == -1) {
            throw "FAIL: Pipeline should contain proper cast call";
        }
        
        if (pipeline.indexOf("validate_required([:name, :email, :password])") == -1) {
            throw "FAIL: Pipeline should contain validation chain";
        }
        
        trace("✅ Test 1 PASS: Validation pipeline generation");
        
        // Test 2: Custom validation function generation
        var customValidation = ChangesetCompiler.generateCustomValidation("email_unique", "email", "not User.exists?(email: value)");
        
        if (customValidation.indexOf("defp validate_email_unique(changeset, field) do") == -1) {
            throw "FAIL: Custom validation should have proper function signature";
        }
        
        if (customValidation.indexOf("validate_change(changeset, field") == -1) {
            throw "FAIL: Custom validation should use validate_change";
        }
        
        trace("✅ Test 2 PASS: Custom validation generation");
        
        // Test 3: Schema integration validation
        var schemaFields = ["name", "email", "age"];
        var changesetFields = ["name", "email"];
        
        var isValid = ChangesetCompiler.validateFieldsAgainstSchema(changesetFields, "User");
        if (!isValid) {
            throw "FAIL: Schema validation should pass for valid fields";
        }
        
        trace("✅ Test 3 PASS: Schema integration validation");
        
        // Test 4: Batch compilation performance  
        var changesets = [
            {className: "UserChangeset", schema: "User"},
            {className: "PostChangeset", schema: "Post"},
            {className: "CommentChangeset", schema: "Comment"}
        ];
        
        var startTime = haxe.Timer.stamp();
        var batchResult = ChangesetCompiler.compileBatchChangesets(changesets);
        var endTime = haxe.Timer.stamp();
        var batchTime = (endTime - startTime) * 1000;
        
        if (batchTime > 15) {
            throw "FAIL: Batch compilation should be <15ms, got " + batchTime + "ms";
        }
        
        if (batchResult.indexOf("defmodule UserChangeset do") == -1) {
            throw "FAIL: Batch result should contain UserChangeset module";
        }
        
        if (batchResult.indexOf("defmodule PostChangeset do") == -1) {
            throw "FAIL: Batch result should contain PostChangeset module";
        }
        
        trace("✅ Test 4 PASS: Batch compilation performance: " + batchTime + "ms");
        
        // Test 5: Association support
        var associations = ["posts", "comments", "profile"];
        var changesetWithAssocs = ChangesetCompiler.generateChangesetWithAssociations("UserChangeset", "User", associations);
        
        if (changesetWithAssocs.indexOf("cast_assoc(:posts)") == -1) {
            throw "FAIL: Should contain posts association casting";
        }
        
        if (changesetWithAssocs.indexOf("cast_assoc(:profile)") == -1) {
            throw "FAIL: Should contain profile association casting";
        }
        
        trace("✅ Test 5 PASS: Association support");
        
        // Test 6: Complex changeset with all features
        var complexChangeset = ChangesetCompiler.compileFullChangeset("RegistrationChangeset", "User");
        
        // Should contain multiple changeset functions
        if (complexChangeset.indexOf("def changeset(%User{} = struct, attrs) do") == -1) {
            throw "FAIL: Should contain primary changeset function";
        }
        
        // Should be production-ready with proper structure
        var requiredElements = [
            "defmodule RegistrationChangeset do",
            "import Ecto.Changeset", 
            "alias User",
            "@doc"
        ];
        
        for (element in requiredElements) {
            if (complexChangeset.indexOf(element) == -1) {
                throw "FAIL: Missing required element: " + element;
            }
        }
        
        trace("✅ Test 6 PASS: Complex changeset generation");
        
        // Test 7: Memory and performance optimization
        var memoryTestStart = haxe.Timer.stamp();
        var results = new Array<String>();
        
        for (i in 0...100) {
            results.push(ChangesetCompiler.compileFullChangeset("TestChangeset" + i, "TestSchema"));
        }
        
        var memoryTestEnd = haxe.Timer.stamp();
        var totalTime = (memoryTestEnd - memoryTestStart) * 1000;
        var avgTime = totalTime / 100;
        
        if (avgTime > 1) {
            throw "FAIL: Average compilation time should be <1ms, got " + avgTime + "ms";
        }
        
        trace("✅ Test 7 PASS: Memory optimization - avg " + avgTime + "ms per changeset");
        
        trace("🔵 REFACTOR Phase Complete! All enhanced features working!");
        trace("✅ Ready for final integration verification");
    }
}

#end