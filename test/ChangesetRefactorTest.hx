package test;

import utest.Test;
import utest.Assert;
#if (macro || reflaxe_runtime)
import reflaxe.elixir.helpers.ChangesetCompiler;
#end

/**
 * REFACTOR Phase: Enhanced ChangesetCompiler integration tests - Migrated to utest
 * Tests optimization and integration with ElixirCompiler
 * 
 * Migration patterns applied:
 * - static main() → extends Test with test methods
 * - throw statements → Assert.isTrue() with proper conditions
 * - trace() statements → removed (utest handles output)
 * - Preserved conditional compilation
 */
class ChangesetRefactorTest extends Test {
    
    function testAdvancedValidationPipelineGeneration() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var fields = ["name", "email", "password", "age"];
        var validations = ["validate_required([:name, :email, :password])", "validate_format(:email, ~r/@/)", "validate_length(:password, min: 8)"];
        
        var pipeline = ChangesetCompiler.generateValidationPipeline(fields, validations);
        
        Assert.isTrue(pipeline.indexOf("cast(attrs, [:name, :email, :password, :age])") >= 0,
            "Pipeline should contain proper cast call");
        
        Assert.isTrue(pipeline.indexOf("validate_required([:name, :email, :password])") >= 0,
            "Pipeline should contain validation chain");
    }
    
    function testCustomValidationFunctionGeneration() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var customValidation = ChangesetCompiler.generateCustomValidation("email_unique", "email", "not User.exists?(email: value)");
        
        Assert.isTrue(customValidation.indexOf("defp validate_email_unique(changeset, field) do") >= 0,
            "Custom validation should have proper function signature");
        
        Assert.isTrue(customValidation.indexOf("validate_change(changeset, field") >= 0,
            "Custom validation should use validate_change");
    }
    
    function testSchemaIntegrationValidation() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var schemaFields = ["name", "email", "age"];
        var changesetFields = ["name", "email"];
        
        var isValid = ChangesetCompiler.validateFieldsAgainstSchema(changesetFields, "User");
        Assert.isTrue(isValid, "Schema validation should pass for valid fields");
    }
    
    function testBatchCompilationPerformance() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var changesets = [
            {className: "UserChangeset", schema: "User"},
            {className: "PostChangeset", schema: "Post"},
            {className: "CommentChangeset", schema: "Comment"}
        ];
        
        var startTime = haxe.Timer.stamp();
        var batchResult = ChangesetCompiler.compileBatchChangesets(changesets);
        var endTime = haxe.Timer.stamp();
        var batchTime = (endTime - startTime) * 1000;
        
        Assert.isTrue(batchTime < 15,
            'Batch compilation should be <15ms, got ${batchTime}ms');
        
        Assert.isTrue(batchResult.indexOf("defmodule UserChangeset do") >= 0,
            "Batch result should contain UserChangeset module");
        
        Assert.isTrue(batchResult.indexOf("defmodule PostChangeset do") >= 0,
            "Batch result should contain PostChangeset module");
    }
    
    function testAssociationSupport() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var associations = ["posts", "comments", "profile"];
        var changesetWithAssocs = ChangesetCompiler.generateChangesetWithAssociations("UserChangeset", "User", associations);
        
        Assert.isTrue(changesetWithAssocs.indexOf("cast_assoc(:posts)") >= 0,
            "Should contain posts association casting");
        
        Assert.isTrue(changesetWithAssocs.indexOf("cast_assoc(:profile)") >= 0,
            "Should contain profile association casting");
    }
    
    function testComplexChangesetWithAllFeatures() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var complexChangeset = ChangesetCompiler.compileFullChangeset("RegistrationChangeset", "User");
        
        // Should contain multiple changeset functions
        Assert.isTrue(complexChangeset.indexOf("def changeset(%User{} = struct, attrs) do") >= 0,
            "Should contain primary changeset function");
        
        // Should be production-ready with proper structure
        var requiredElements = [
            "defmodule RegistrationChangeset do",
            "import Ecto.Changeset", 
            "alias User",
            "@doc"
        ];
        
        for (element in requiredElements) {
            Assert.isTrue(complexChangeset.indexOf(element) >= 0,
                'Missing required element: ${element}');
        }
    }
    
    function testMemoryAndPerformanceOptimization() {
        #if !(macro || reflaxe_runtime)
        return;
        #end
        
        var memoryTestStart = haxe.Timer.stamp();
        var results = new Array<String>();
        
        for (i in 0...100) {
            results.push(ChangesetCompiler.compileFullChangeset("TestChangeset" + i, "TestSchema"));
        }
        
        var memoryTestEnd = haxe.Timer.stamp();
        var totalTime = (memoryTestEnd - memoryTestStart) * 1000;
        var avgTime = totalTime / 100;
        
        Assert.isTrue(avgTime < 1,
            'Average compilation time should be <1ms, got ${avgTime}ms');
    }
}

// Extended Runtime Mock of ChangesetCompiler (with refactor methods)
#if !(macro || reflaxe_runtime)
class ChangesetCompiler {
    // Basic methods from ChangesetCompilerTest
    public static function isChangesetClass(className: String): Bool {
        return className != null && className.indexOf("Changeset") != -1;
    }
    
    public static function compileValidation(field: String, rule: String): String {
        return 'validate_${rule}(changeset, [:${field}])';
    }
    
    public static function generateChangesetModule(className: String): String {
        return 'defmodule ${className} do\n  import Ecto.Changeset\nend';
    }
    
    public static function compileCastFields(fieldNames: Array<String>): String {
        return '[:${fieldNames.join(", :")}]';
    }
    
    public static function compileErrorTuple(field: String, error: String): String {
        return '{:${field}, "${error}"}';
    }
    
    public static function compileFullChangeset(className: String, schema: String): String {
        return 'defmodule ${className} do\n  import Ecto.Changeset\n  alias ${schema}\n  @doc "Changeset function"\n  def changeset(%${schema}{} = struct, attrs) do\n    struct\n    |> cast(attrs, [])\n  end\nend';
    }
    
    // Refactor test methods
    public static function generateValidationPipeline(fields: Array<String>, validations: Array<String>): String {
        var cast = 'cast(attrs, [:${fields.join(", :")}])';
        return cast + "\n    |> " + validations.join("\n    |> ");
    }
    
    public static function generateCustomValidation(name: String, field: String, condition: String): String {
        return 'defp validate_${name}(changeset, field) do\n  validate_change(changeset, field, fn _, value ->\n    ${condition}\n  end)\nend';
    }
    
    public static function validateFieldsAgainstSchema(fields: Array<String>, schema: String): Bool {
        // Mock validation - in real implementation would check against actual schema
        return true;
    }
    
    public static function compileBatchChangesets(changesets: Array<Dynamic>): String {
        var result = "";
        for (changeset in changesets) {
            result += 'defmodule ${changeset.className} do\n  import Ecto.Changeset\nend\n\n';
        }
        return result;
    }
    
    public static function generateChangesetWithAssociations(className: String, schema: String, associations: Array<String>): String {
        var assocCasts = associations.map(function(a) return '|> cast_assoc(:${a})').join("\n    ");
        return 'defmodule ${className} do\n  ${assocCasts}\nend';
    }
}
#end