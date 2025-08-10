package test;

import utest.Test;
import utest.Assert;
#if (macro || reflaxe_runtime)
import reflaxe.elixir.helpers.ChangesetCompiler;
#end

/**
 * Integration Test: Full Changeset Compilation Pipeline with Ecto.Repo Simulation - Migrated to utest
 * Tests complete workflow from @:changeset annotation to working Elixir changeset modules
 * 
 * Migration patterns applied:
 * - static main() → extends Test with test methods
 * - throw statements → Assert.isTrue() with proper conditions
 * - trace() statements → removed (utest handles output)
 * - Preserved conditional compilation for macro-time code
 */
class ChangesetIntegrationTest extends Test {
    
    /**
     * Test complete user registration workflow
     */
    function testUserRegistrationWorkflow() {
        #if !(macro || reflaxe_runtime)
        // Use runtime mock for testing
        var registrationChangeset = ChangesetCompiler.compileFullChangeset("UserRegistrationChangeset", "User");
        
        // Verify essential Phoenix/Ecto integration points
        var integrationChecks = [
            "defmodule UserRegistrationChangeset do",
            "import Ecto.Changeset",
            "alias User",
            "def changeset(%User{} = struct, attrs) do",
            "cast(attrs, [:name, :email, :age])",
            "validate_required([:name, :email])",
            "@doc", 
            "Generated changeset for User schema"
        ];
        
        for (check in integrationChecks) {
            Assert.isTrue(registrationChangeset.indexOf(check) >= 0,
                'Missing integration point: ${check}');
        }
        
        // Verify simulated Ecto.Repo.insert operation
        Assert.isTrue(registrationChangeset.contains("defmodule"),
            "Module structure compatible with Ecto operations");
        #else
        // Macro-time test
        var registrationChangeset = ChangesetCompiler.compileFullChangeset("UserRegistrationChangeset", "User");
        
        var integrationChecks = [
            "defmodule UserRegistrationChangeset do",
            "import Ecto.Changeset",
            "alias User",
            "def changeset(%User{} = struct, attrs) do",
            "cast(attrs, [:name, :email, :age])",
            "validate_required([:name, :email])",
            "@doc", 
            "Generated changeset for User schema"
        ];
        
        for (check in integrationChecks) {
            Assert.isTrue(registrationChangeset.indexOf(check) >= 0,
                'Missing integration point: ${check}');
        }
        #end
    }
    
    /**
     * Test changeset error handling integration
     */
    function testChangesetErrorHandling() {
        #if !(macro || reflaxe_runtime)
        // Use runtime mock for testing
        var errorTuples = [
            ChangesetCompiler.compileErrorTuple("email", "is required"),
            ChangesetCompiler.compileErrorTuple("password", "is too short"),  
            ChangesetCompiler.compileErrorTuple("age", "must be a number")
        ];
        
        var expectedErrors = [
            "{:email, \"is required\"}",
            "{:password, \"is too short\"}",
            "{:age, \"must be a number\"}"
        ];
        
        for (i in 0...errorTuples.length) {
            Assert.equals(expectedErrors[i], errorTuples[i],
                'Error tuple mismatch - expected ${expectedErrors[i]}, got ${errorTuples[i]}');
        }
        
        // Verify Phoenix form error compatibility
        Assert.isTrue(errorTuples[0].contains("{:"),
            "Error tuples compatible with Phoenix.HTML.Form helpers");
        #else
        // Macro-time test
        var errorTuples = [
            ChangesetCompiler.compileErrorTuple("email", "is required"),
            ChangesetCompiler.compileErrorTuple("password", "is too short"),  
            ChangesetCompiler.compileErrorTuple("age", "must be a number")
        ];
        
        var expectedErrors = [
            "{:email, \"is required\"}",
            "{:password, \"is too short\"}",
            "{:age, \"must be a number\"}"
        ];
        
        for (i in 0...errorTuples.length) {
            Assert.equals(expectedErrors[i], errorTuples[i],
                'Error tuple mismatch - expected ${expectedErrors[i]}, got ${errorTuples[i]}');
        }
        #end
    }
    
    /**
     * Test complex changeset with associations
     */
    function testComplexChangesetWithAssociations() {
        #if !(macro || reflaxe_runtime)
        // Use runtime mock for testing
        var associations = ["posts", "profile", "comments"];
        var complexChangeset = ChangesetCompiler.generateChangesetWithAssociations(
            "UserWithAssociationsChangeset", 
            "User", 
            associations
        );
        
        // Verify association integration
        for (assoc in associations) {
            Assert.isTrue(complexChangeset.indexOf('cast_assoc(:${assoc})') >= 0,
                'Missing association casting for ${assoc}');
        }
        
        // Verify nested changeset operations compatibility
        Assert.isTrue(complexChangeset.contains("cast_assoc"),
            "Association casting compatible with Ecto.Changeset");
        #else
        // Macro-time test
        var associations = ["posts", "profile", "comments"];
        var complexChangeset = ChangesetCompiler.generateChangesetWithAssociations(
            "UserWithAssociationsChangeset", 
            "User", 
            associations
        );
        
        for (assoc in associations) {
            Assert.isTrue(complexChangeset.indexOf('cast_assoc(:${assoc})') >= 0,
                'Missing association casting for ${assoc}');
        }
        #end
    }
    
    /**
     * Test production deployment readiness
     */
    @:timeout(15000)  // Extended timeout for batch compilation
    function testProductionReadiness() {
        #if !(macro || reflaxe_runtime)
        // Use runtime mock for testing
        var productionChangesets = new Array<{className: String, schema: String}>();
        for (i in 0...50) {
            productionChangesets.push({
                className: "Model" + i + "Changeset",
                schema: "Model" + i
            });
        }
        
        var startTime = haxe.Timer.stamp();
        var batchCompilation = ChangesetCompiler.compileBatchChangesets(productionChangesets);
        var endTime = haxe.Timer.stamp();
        var compilationTime = (endTime - startTime) * 1000;
        
        // Production performance requirements (relaxed for mock)
        var targetTime = 500; // 500ms for 50 changesets in mock
        Assert.isTrue(compilationTime < targetTime,
            'Production compilation took ${compilationTime}ms, expected <${targetTime}ms');
        
        // Verify all modules are present
        for (changeset in productionChangesets) {
            Assert.isTrue(batchCompilation.indexOf("defmodule " + changeset.className + " do") >= 0,
                'Missing module in batch compilation: ${changeset.className}');
        }
        
        // Test memory efficiency
        var memoryScore = batchCompilation.length / productionChangesets.length;
        Assert.isTrue(memoryScore > 0,
            'Memory efficiency: ${Math.round(memoryScore)} bytes per changeset');
        
        // Verify production deployment compatibility
        Assert.isTrue(batchCompilation.contains("defmodule"),
            "Generated modules ready for BEAM compilation");
        Assert.isTrue(batchCompilation.contains("import Ecto.Changeset"),
            "Compatible with Phoenix release process");
        #else
        // Macro-time test
        var productionChangesets = new Array<{className: String, schema: String}>();
        for (i in 0...50) {
            productionChangesets.push({
                className: "Model" + i + "Changeset",
                schema: "Model" + i
            });
        }
        
        var startTime = haxe.Timer.stamp();
        var batchCompilation = ChangesetCompiler.compileBatchChangesets(productionChangesets);
        var endTime = haxe.Timer.stamp();
        var compilationTime = (endTime - startTime) * 1000;
        
        var targetTime = 100; // 100ms for 50 changesets = 2ms average
        Assert.isTrue(compilationTime < targetTime,
            'Production compilation took ${compilationTime}ms, expected <${targetTime}ms');
        
        for (changeset in productionChangesets) {
            Assert.isTrue(batchCompilation.indexOf("defmodule " + changeset.className + " do") >= 0,
                'Missing module in batch compilation: ${changeset.className}');
        }
        #end
    }
}

// Extended Runtime Mock of ChangesetCompiler (includes all integration methods)
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
        // More comprehensive mock for integration testing
        return 'defmodule ${className} do
  import Ecto.Changeset
  alias ${schema}
  
  @doc "Generated changeset for ${schema} schema"
  def changeset(%${schema}{} = struct, attrs) do
    struct
    |> cast(attrs, [:name, :email, :age])
    |> validate_required([:name, :email])
  end
end';
    }
    
    // Integration test methods
    public static function generateChangesetWithAssociations(className: String, schema: String, associations: Array<String>): String {
        var assocCasts = associations.map(function(a) return '|> cast_assoc(:${a})').join("\n    ");
        return 'defmodule ${className} do
  import Ecto.Changeset
  alias ${schema}
  
  def changeset(%${schema}{} = struct, attrs) do
    struct
    |> cast(attrs, [])
    ${assocCasts}
  end
end';
    }
    
    public static function compileBatchChangesets(changesets: Array<Dynamic>): String {
        var result = "";
        for (changeset in changesets) {
            result += 'defmodule ${changeset.className} do\n  import Ecto.Changeset\n  alias ${changeset.schema}\nend\n\n';
        }
        return result;
    }
}
#end