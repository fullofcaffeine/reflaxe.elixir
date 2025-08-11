defmodule HaxeErrorParsingTest do
  @moduledoc """
  Focused tests for Haxe error parsing functionality without Mix task dependencies.
  
  This test file focuses purely on the core error parsing and storage functionality
  to ensure the foundational stacktrace system works before testing Mix integration.
  """
  
  use ExUnit.Case, async: false

  alias HaxeCompiler

  setup do
    # Ensure clean state for each test
    HaxeCompiler.clear_compilation_errors()
    :ok
  end

  describe "basic error parsing" do
    test "parses simple error format" do
      error_output = "src_haxe/Test.hx:10: Type not found : BadType"
      
      errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      assert length(errors) == 1
      
      error = hd(errors)
      assert error.type == :compilation_error
      assert error.level == :haxe
      assert error.file == "src_haxe/Test.hx"
      assert error.line == 10
      assert String.contains?(error.error_id, "haxe_error_")
    end

    test "parses error with character positions" do
      error_output = "src_haxe/User.hx:23: characters 5-12 : Type not found : UnknownType"
      
      errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      assert length(errors) == 1
      
      error = hd(errors)
      assert error.file == "src_haxe/User.hx"
      assert error.line == 23
      assert error.column_start == 5
      assert error.column_end == 12
      assert error.error_type == "Type not found"
      assert error.message == "UnknownType"
    end

    test "parses warning format" do
      error_output = "Warning : Unused import in src_haxe/Test.hx"
      
      errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      assert length(errors) == 1
      
      error = hd(errors)
      assert error.type == :warning
      assert error.level == :haxe
      assert String.contains?(error.message, "Unused import")
    end

    test "parses stacktrace line" do
      error_output = "    at Main.main (src_haxe/Main.hx line 15)"
      
      errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      assert length(errors) == 1
      
      error = hd(errors)
      assert error.type == :stacktrace
      assert error.level == :haxe
      assert error.function_call == "Main.main"
      assert error.file == "src_haxe/Main.hx"
      assert error.line == 15
    end
  end

  describe "error storage and retrieval" do
    test "stores and retrieves errors" do
      error_output = "src_haxe/Test.hx:5: Type not found : BadType"
      
      # Parse and automatically store errors
      errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      # Retrieve stored errors
      stored_errors = HaxeCompiler.get_compilation_errors(:map)
      
      assert length(stored_errors) == length(errors)
      assert hd(stored_errors).error_id == hd(errors).error_id
    end

    test "retrieves errors in JSON format" do
      error_output = "src_haxe/Test.hx:1: Type not found : BadType"
      
      _errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      json_errors = HaxeCompiler.get_compilation_errors(:json)
      
      assert is_binary(json_errors)
      {:ok, decoded} = Jason.decode(json_errors)
      assert is_list(decoded)
      assert length(decoded) == 1
    end

    test "clears stored errors" do
      error_output = "src_haxe/Test.hx:1: Type not found : BadType"
      
      # Store errors
      _errors = HaxeCompiler.parse_haxe_errors(error_output)
      assert length(HaxeCompiler.get_compilation_errors(:map)) == 1
      
      # Clear errors
      HaxeCompiler.clear_compilation_errors()
      assert HaxeCompiler.get_compilation_errors(:map) == []
    end
  end

  describe "complex error scenarios" do
    test "parses mixed error types" do
      mixed_output = """
      src_haxe/User.hx:10: characters 5-12 : Type not found : UnknownType
      Warning : Unused import in src_haxe/Post.hx
          at Main.process (src_haxe/Main.hx line 45)
      """
      
      errors = HaxeCompiler.parse_haxe_errors(mixed_output)
      
      assert length(errors) == 3
      
      types = Enum.map(errors, & &1.type)
      assert :compilation_error in types
      assert :warning in types
      assert :stacktrace in types
    end

    test "handles empty input gracefully" do
      assert HaxeCompiler.parse_haxe_errors("") == []
    end

    test "ignores non-error lines" do
      mixed_output = """
      This is not an error line
      Another random line
      src_haxe/Test.hx:15: Type not found : BadType
      More random text
      """
      
      errors = HaxeCompiler.parse_haxe_errors(mixed_output)
      
      assert length(errors) == 1
      assert hd(errors).file == "src_haxe/Test.hx"
      assert hd(errors).line == 15
    end
  end

  describe "error ID generation" do
    test "generates unique error IDs" do
      error_output = """
      src_haxe/User.hx:10: Type not found : BadType1
      src_haxe/Post.hx:20: Type not found : BadType2
      """
      
      errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      assert length(errors) == 2
      
      ids = Enum.map(errors, & &1.error_id)
      assert Enum.uniq(ids) == ids  # All IDs should be unique
      assert Enum.all?(ids, &String.contains?(&1, "haxe_error_"))
    end

    test "includes timestamp in error data" do
      error_output = "src_haxe/Test.hx:5: Type not found : BadType"
      
      errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      assert length(errors) == 1
      
      error = hd(errors)
      assert %DateTime{} = error.timestamp
      
      # Timestamp should be recent (within last few seconds)
      now = DateTime.utc_now()
      diff = DateTime.diff(now, error.timestamp)
      assert diff < 5, "Error timestamp should be recent"
    end
  end

  describe "performance requirements" do
    test "parses large error output efficiently" do
      # Create large error output (100 errors)
      large_error_output = 
        1..100
        |> Enum.map(fn i -> "src_haxe/Module#{i}.hx:#{i}: Type not found : BadType#{i}" end)
        |> Enum.join("\n")
      
      start_time = System.monotonic_time(:millisecond)
      errors = HaxeCompiler.parse_haxe_errors(large_error_output)
      parse_time = System.monotonic_time(:millisecond) - start_time
      
      assert length(errors) == 100
      assert parse_time < 100, "Should parse 100 errors quickly (<100ms), took #{parse_time}ms"
      
      # Verify all errors are properly structured
      Enum.each(errors, fn error ->
        assert error.type == :compilation_error
        assert error.level == :haxe
        assert String.starts_with?(error.file, "src_haxe/Module")
        assert is_binary(error.error_id)
      end)
    end

    test "JSON serialization is fast" do
      error_output = """
      src_haxe/User.hx:10: Type not found : UnknownType
      src_haxe/Post.hx:20: Field not found : badField
      """
      
      _errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      start_time = System.monotonic_time(:millisecond)
      json_output = HaxeCompiler.get_compilation_errors(:json)
      json_time = System.monotonic_time(:millisecond) - start_time
      
      assert String.length(json_output) > 0
      assert json_time < 50, "JSON serialization should be fast (<50ms), took #{json_time}ms"
      
      # Verify JSON is valid
      {:ok, decoded} = Jason.decode(json_output)
      assert is_list(decoded)
      assert length(decoded) == 2
    end
  end

  describe "LLM debugging workflow integration" do
    test "provides complete error context for LLM agents" do
      error_output = "src_haxe/UserLive.hx:45: characters 12-20 : Field not found : badField on type User"
      
      errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      assert length(errors) == 1
      
      error = hd(errors)
      
      # Verify all required fields for LLM debugging
      assert error.type == :compilation_error
      assert error.level == :haxe  # LLM knows to debug at Haxe level
      assert error.file == "src_haxe/UserLive.hx"
      assert error.line == 45
      assert error.column_start == 12
      assert error.column_end == 20
      assert error.error_type == "Field not found"
      assert error.message == "badField on type User"
      assert is_binary(error.error_id)
      assert %DateTime{} = error.timestamp
      
      # Verify JSON format for programmatic access
      json_errors = HaxeCompiler.get_compilation_errors(:json)
      {:ok, json_data} = Jason.decode(json_errors)
      
      json_error = hd(json_data)
      assert json_error["type"] == "compilation_error"
      assert json_error["level"] == "haxe"
      assert json_error["file"] == "src_haxe/UserLive.hx"
      assert json_error["line"] == 45
      assert json_error["error_id"] == error.error_id
    end
  end
end