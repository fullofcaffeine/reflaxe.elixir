defmodule CompleteErrorIntegrationTest do
  @moduledoc """
  Complete end-to-end test of Haxe error parsing with real compiler output samples.
  
  This test validates:
  1. Real Haxe compiler error format parsing
  2. Error storage and retrieval
  3. JSON serialization for LLM agents
  4. Mix task integration
  5. Complete debugging workflow
  """
  
  use ExUnit.Case, async: false

  alias HaxeCompiler

  setup do
    # Ensure clean state for each test
    HaxeCompiler.clear_compilation_errors()
    :ok
  end

  describe "complete error parsing integration" do
    test "processes all real Haxe error types correctly" do
      # All error types from real Haxe compiler output
      real_compiler_output = """
      Invalid commandline class : TypeNotFound should be test.sample_errors.TypeNotFound
      test/sample_errors/TypeNotFound.hx:5: characters 22-33 : Type not found : UnknownType
      test/sample_errors/FieldNotFound.hx:12: characters 19-35 : test.sample_errors.FieldNotFound has no field nonExistentField
      test/sample_errors/SyntaxError.hx:7: characters 9-12 : Missing ;
      Warning : Unused import in src_haxe/Post.hx
      """
      
      errors = HaxeCompiler.parse_haxe_errors(real_compiler_output)
      
      # Should parse 4 valid errors (ignore commandline error)
      assert length(errors) == 4
      
      # Check each error type
      compilation_errors = Enum.filter(errors, & &1.type == :compilation_error)
      assert length(compilation_errors) == 3
      
      warnings = Enum.filter(errors, & &1.type == :warning)
      assert length(warnings) == 1
      
      # Verify all have unique error IDs
      error_ids = Enum.map(errors, & &1.error_id)
      assert Enum.uniq(error_ids) == error_ids
      
      # Verify all have timestamps
      assert Enum.all?(errors, fn error -> 
        match?(%DateTime{}, error.timestamp)
      end)
      
      # Verify warning has file extracted
      warning = hd(warnings)
      assert warning.file == "src_haxe/Post.hx"
      assert warning.message == "Unused import"
    end

    test "generates correct error metadata for LLM debugging" do
      real_error = "test/sample_errors/TypeNotFound.hx:5: characters 22-33 : Type not found : UnknownType"
      
      errors = HaxeCompiler.parse_haxe_errors(real_error)
      error = hd(errors)
      
      # All required fields for LLM debugging
      assert error.type == :compilation_error
      assert error.level == :haxe  # LLM knows to debug at Haxe level
      assert String.ends_with?(error.file, "test/sample_errors/TypeNotFound.hx")
      assert error.line == 5
      assert error.column_start == 22
      assert error.column_end == 33
      assert error.error_type == "Type not found"
      assert error.message == "UnknownType"
      assert String.contains?(error.error_id, "haxe_error_")
      assert %DateTime{} = error.timestamp
      assert error.raw_line == real_error
      assert error.stacktrace == []
    end

    test "JSON serialization for programmatic LLM access" do
      mixed_errors = """
      test/sample_errors/TypeNotFound.hx:5: characters 22-33 : Type not found : UnknownType
      Warning : Unused import in src_haxe/Post.hx
      """
      
      _parsed_errors = HaxeCompiler.parse_haxe_errors(mixed_errors)
      
      # Get JSON representation
      json_errors = HaxeCompiler.get_compilation_errors(:json)
      assert is_binary(json_errors)
      
      {:ok, decoded_errors} = Jason.decode(json_errors)
      assert is_list(decoded_errors)
      assert length(decoded_errors) == 2
      
      # Verify JSON structure for LLM consumption
      compilation_error = Enum.find(decoded_errors, & &1["type"] == "compilation_error")
      assert compilation_error["level"] == "haxe"
      assert compilation_error["error_type"] == "Type not found"
      assert compilation_error["line"] == 5
      assert compilation_error["column_start"] == 22
      assert compilation_error["column_end"] == 33
      
      warning = Enum.find(decoded_errors, & &1["type"] == "warning")
      assert warning["level"] == "haxe"
      assert warning["file"] == "src_haxe/Post.hx"
      assert warning["message"] == "Unused import"
    end

    test "performance meets LLM iteration requirements" do
      # Create large error output (50 real errors)
      large_error_output = 
        1..50
        |> Enum.map(fn i -> 
          "test/sample_errors/Module#{i}.hx:#{i}: characters 1-10 : Type not found : BadType#{i}"
        end)
        |> Enum.join("\n")
      
      start_time = System.monotonic_time(:millisecond)
      errors = HaxeCompiler.parse_haxe_errors(large_error_output)
      parse_time = System.monotonic_time(:millisecond) - start_time
      
      # Should parse all errors quickly for LLM compatibility
      assert length(errors) == 50
      assert parse_time < 100, "Should parse 50 errors in <100ms for LLM iteration, took #{parse_time}ms"
      
      # Test JSON serialization performance
      start_time = System.monotonic_time(:millisecond)
      json_output = HaxeCompiler.get_compilation_errors(:json)
      json_time = System.monotonic_time(:millisecond) - start_time
      
      assert String.length(json_output) > 0
      assert json_time < 50, "JSON serialization should be <50ms for LLM access, took #{json_time}ms"
      
      # Verify JSON validity
      {:ok, decoded} = Jason.decode(json_output)
      assert length(decoded) == 50
    end

    test "error storage and retrieval workflow" do
      # Step 1: Parse errors (automatically stored)
      test_errors = """
      test/sample_errors/TypeNotFound.hx:5: characters 22-33 : Type not found : UnknownType
      test/sample_errors/SyntaxError.hx:7: characters 9-12 : Missing ;
      """
      
      parsed_errors = HaxeCompiler.parse_haxe_errors(test_errors)
      assert length(parsed_errors) == 2
      
      # Step 2: Retrieve as maps
      stored_errors = HaxeCompiler.get_compilation_errors(:map)
      assert length(stored_errors) == 2
      assert hd(stored_errors).error_id == hd(parsed_errors).error_id
      
      # Step 3: Retrieve as JSON
      json_errors = HaxeCompiler.get_compilation_errors(:json)
      {:ok, json_data} = Jason.decode(json_errors)
      assert length(json_data) == 2
      
      # Step 4: Clear errors
      HaxeCompiler.clear_compilation_errors()
      assert HaxeCompiler.get_compilation_errors(:map) == []
    end
  end

  describe "LLM debugging workflow simulation" do
    test "complete workflow from compilation error to structured debugging data" do
      # Simulate real compilation failure
      compilation_failure_output = """
      test/sample_errors/UserLive.hx:45: characters 12-20 : test.sample_errors.User has no field badField
          at UserLive.handle_event (test/sample_errors/UserLive.hx line 45)
      Warning : Unused variable 'socket' in test/sample_errors/UserLive.hx line 50
      """
      
      # Step 1: Parse and store errors (as happens during compilation)
      parsed_errors = HaxeCompiler.parse_haxe_errors(compilation_failure_output)
      
      # Should parse: 1 error + 1 stacktrace + 1 warning = 3 items
      assert length(parsed_errors) == 3
      
      # Step 2: LLM gets structured error list in JSON
      json_errors = HaxeCompiler.get_compilation_errors(:json)
      {:ok, errors} = Jason.decode(json_errors)
      
      # Step 3: LLM identifies the compilation error for debugging
      compilation_errors = Enum.filter(errors, fn e -> e["type"] == "compilation_error" end)
      assert length(compilation_errors) == 1
      
      error = hd(compilation_errors)
      
      # Step 4: LLM gets complete debugging context
      assert error["level"] == "haxe"  # Debug at Haxe source level
      assert String.contains?(error["file"], "UserLive.hx")
      assert error["line"] == 45
      assert error["column_start"] == 12
      assert error["column_end"] == 20
      assert error["error_type"] == "Field not found"
      assert String.contains?(error["message"], "has no field badField")
      
      # Step 5: LLM can identify abstraction level and debugging strategy
      # - error["level"] == "haxe" means debug at source level
      # - error["file"] points to Haxe source file to fix
      # - error["line"] and column information for precise location
      # - error["error_type"] indicates what kind of fix is needed
      
      # Stacktrace information is also available
      stacktraces = Enum.filter(errors, fn e -> e["type"] == "stacktrace" end)
      assert length(stacktraces) == 1
      
      stacktrace = hd(stacktraces)
      assert stacktrace["level"] == "haxe"
      assert stacktrace["function_call"] == "UserLive.handle_event"
      assert String.contains?(stacktrace["file"], "UserLive.hx")
      assert stacktrace["line"] == 45
    end
  end

  describe "edge cases and robustness" do
    test "handles malformed and mixed output gracefully" do
      mixed_output = """
      This is not an error line
      Some random compiler output
      test/sample_errors/Valid.hx:10: characters 1-5 : Type not found : ValidError
      Another random line
      Warning : This warning has no file info
      More random text
      """
      
      errors = HaxeCompiler.parse_haxe_errors(mixed_output)
      
      # Should parse only the valid error lines
      assert length(errors) == 2
      
      compilation_errors = Enum.filter(errors, & &1.type == :compilation_error)
      assert length(compilation_errors) == 1
      
      warnings = Enum.filter(errors, & &1.type == :warning)
      assert length(warnings) == 1
      
      # Warning without file info should still be parsed
      warning = hd(warnings)
      assert warning.file == nil
      assert warning.message == "This warning has no file info"
    end

    test "handles unicode and special characters" do
      unicode_error = "test/sample_errors/用户.hx:10: characters 1-5 : Type not found : 类型未找到"
      
      errors = HaxeCompiler.parse_haxe_errors(unicode_error)
      
      assert length(errors) == 1
      error = hd(errors)
      assert String.contains?(error.file, "用户.hx")
      assert error.message == "类型未找到"
    end

    test "handles very long error messages without performance issues" do
      long_message = String.duplicate("Very detailed error explanation ", 200)  # ~6000 chars
      long_error = "test/sample_errors/Long.hx:1: characters 1-5 : Compilation Error : #{long_message}"
      
      start_time = System.monotonic_time(:millisecond)
      errors = HaxeCompiler.parse_haxe_errors(long_error)
      parse_time = System.monotonic_time(:millisecond) - start_time
      
      assert length(errors) == 1
      assert parse_time < 50, "Should handle long messages quickly (<50ms), took #{parse_time}ms"
      
      error = hd(errors)
      assert String.length(error.message) > 5000
      assert error.error_type == "Compilation Error"
    end
  end
end