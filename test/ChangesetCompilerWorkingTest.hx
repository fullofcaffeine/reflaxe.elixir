package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.helpers.ChangesetCompiler;

/**
 * Working test to verify ChangesetCompiler GREEN phase implementation
 */
class ChangesetCompilerWorkingTest {
    public static function main(): Void {
        trace("🟢 Starting GREEN Phase: ChangesetCompiler Tests");
        
        // Test 1: Changeset annotation detection
        var result1 = ChangesetCompiler.isChangesetClass("UserChangeset");
        if (result1 != true) {
            throw "FAIL: Changeset detection should return true for UserChangeset";
        }
        trace("✅ Test 1 PASS: Changeset annotation detection");
        
        // Test 2: Validation compilation
        var validation = ChangesetCompiler.compileValidation("email", "required");
        var expectedValidation = "validate_required(changeset, [:email])";
        if (validation.indexOf("validate_required") == -1) {
            throw "FAIL: Validation compilation should contain validate_required";
        }
        trace("✅ Test 2 PASS: Validation compilation");
        
        // Test 3: Module generation
        var module = ChangesetCompiler.generateChangesetModule("UserChangeset");
        if (module.indexOf("defmodule UserChangeset do") == -1) {
            throw "FAIL: Module should contain defmodule UserChangeset do";
        }
        if (module.indexOf("import Ecto.Changeset") == -1) {
            throw "FAIL: Module should contain import Ecto.Changeset";
        }
        trace("✅ Test 3 PASS: Module generation");
        
        // Test 4: Cast fields compilation
        var castFields = ChangesetCompiler.compileCastFields(["name", "age", "email"]);
        var expectedCast = "[:name, :age, :email]";
        if (castFields != expectedCast) {
            throw "FAIL: Expected " + expectedCast + ", got " + castFields;
        }
        trace("✅ Test 4 PASS: Cast fields compilation");
        
        // Test 5: Error tuple compilation
        var errorTuple = ChangesetCompiler.compileErrorTuple("email", "is required");
        var expectedError = "{:email, \"is required\"}";
        if (errorTuple != expectedError) {
            throw "FAIL: Expected " + expectedError + ", got " + errorTuple;
        }
        trace("✅ Test 5 PASS: Error tuple compilation");
        
        // Test 6: Full changeset compilation
        var fullChangeset = ChangesetCompiler.compileFullChangeset("UserRegistrationChangeset", "User");
        if (fullChangeset.indexOf("defmodule UserRegistrationChangeset do") == -1) {
            throw "FAIL: Full changeset should contain module definition";
        }
        if (fullChangeset.indexOf("def changeset(%User{} = struct, attrs) do") == -1) {
            throw "FAIL: Full changeset should contain typed changeset function";
        }
        trace("✅ Test 6 PASS: Full changeset compilation");
        
        // Performance test
        var startTime = haxe.Timer.stamp();
        for (i in 0...10) {
            ChangesetCompiler.compileFullChangeset("TestChangeset" + i, "TestModel");
        }
        var endTime = haxe.Timer.stamp();
        var compilationTime = (endTime - startTime) * 1000;
        
        if (compilationTime > 15) {
            throw "FAIL: Performance target missed - " + compilationTime + "ms > 15ms";
        }
        trace("✅ Test 7 PASS: Performance target met: " + compilationTime + "ms < 15ms");
        
        trace("🟢 GREEN Phase Complete! All ChangesetCompiler tests passed!");
        trace("🔵 Ready for REFACTOR Phase");
    }
}

#end