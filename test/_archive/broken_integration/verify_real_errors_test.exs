defmodule VerifyRealErrorsTest do
  @moduledoc """
  Test real Haxe compiler error parsing with actual error samples.
  
  This verifies our parsing works with real Haxe compiler output formats.
  """
  
  use ExUnit.Case, async: false

  alias HaxeCompiler

  setup do
    # Ensure clean state for each test
    HaxeCompiler.clear_compilation_errors()
    :ok
  end

  describe "real Haxe error format parsing" do
    test "parses real type not found error" do
      # Real error from npx haxe test/sample_errors/test_errors.hxml
      real_error = "test/sample_errors/TypeNotFound.hx:5: characters 22-33 : Type not found : UnknownType"
      
      errors = HaxeCompiler.parse_haxe_errors(real_error)
      
      assert length(errors) == 1
      
      error = hd(errors)
      assert error.type == :compilation_error
      assert error.level == :haxe
      assert String.ends_with?(error.file, "test/sample_errors/TypeNotFound.hx")
      assert error.line == 5
      assert error.column_start == 22
      assert error.column_end == 33
      assert error.error_type == "Type not found"
      assert error.message == "UnknownType"
      assert String.contains?(error.error_id, "haxe_error_")
    end

    test "parses real field not found error" do
      # Real error from field test
      real_error = "test/sample_errors/FieldNotFound.hx:12: characters 19-35 : test.sample_errors.FieldNotFound has no field nonExistentField"
      
      errors = HaxeCompiler.parse_haxe_errors(real_error)
      
      assert length(errors) == 1
      
      error = hd(errors)
      assert error.type == :compilation_error
      assert error.level == :haxe
      assert String.ends_with?(error.file, "test/sample_errors/FieldNotFound.hx")
      assert error.line == 12
      assert error.column_start == 19
      assert error.column_end == 35
      assert String.contains?(error.message, "has no field nonExistentField")
      assert String.contains?(error.error_id, "haxe_error_")
    end

    test "parses real syntax error" do
      # Real syntax error
      real_error = "test/sample_errors/SyntaxError.hx:7: characters 9-12 : Missing ;"
      
      errors = HaxeCompiler.parse_haxe_errors(real_error)
      
      assert length(errors) == 1
      
      error = hd(errors)
      assert error.type == :compilation_error
      assert error.level == :haxe
      assert String.ends_with?(error.file, "test/sample_errors/SyntaxError.hx")
      assert error.line == 7
      assert error.column_start == 9
      assert error.column_end == 12
      assert error.message == "Missing ;"
      assert String.contains?(error.error_id, "haxe_error_")
    end

    test "generates unique error IDs for real errors" do
      real_errors = """
      test/sample_errors/TypeNotFound.hx:5: characters 22-33 : Type not found : UnknownType
      test/sample_errors/FieldNotFound.hx:12: characters 19-35 : test.sample_errors.FieldNotFound has no field nonExistentField
      """
      
      errors = HaxeCompiler.parse_haxe_errors(real_errors)
      
      assert length(errors) == 2
      
      ids = Enum.map(errors, & &1.error_id)
      assert Enum.uniq(ids) == ids  # All IDs should be unique
      assert Enum.all?(ids, &String.contains?(&1, "haxe_error_"))
    end

    test "stores and retrieves real errors" do
      real_error = "test/sample_errors/TypeNotFound.hx:5: characters 22-33 : Type not found : UnknownType"
      
      # Parse errors (automatically stores them)
      parsed_errors = HaxeCompiler.parse_haxe_errors(real_error)
      
      # Retrieve stored errors
      stored_errors = HaxeCompiler.get_compilation_errors(:map)
      
      assert length(stored_errors) == length(parsed_errors)
      assert hd(stored_errors).error_id == hd(parsed_errors).error_id
      
      # Verify JSON format
      json_errors = HaxeCompiler.get_compilation_errors(:json)
      {:ok, decoded} = Jason.decode(json_errors)
      
      assert is_list(decoded)
      assert length(decoded) == 1
      assert hd(decoded)["error_type"] == "Type not found"
    end
  end

  describe "edge cases from real Haxe compiler" do
    test "handles commandline error format" do
      # Actual error from invalid class name
      real_error = "Invalid commandline class : TypeNotFound should be test.sample_errors.TypeNotFound"
      
      # This should not parse as a standard error since it doesn't match the .hx:line format
      errors = HaxeCompiler.parse_haxe_errors(real_error)
      assert length(errors) == 0
    end

    test "handles multi-line real error output" do
      real_output = """
      Invalid commandline class : TypeNotFound should be test.sample_errors.TypeNotFound
      test/sample_errors/TypeNotFound.hx:5: characters 22-33 : Type not found : UnknownType
      """
      
      errors = HaxeCompiler.parse_haxe_errors(real_output)
      
      # Should only parse the actual file error, ignore the commandline error
      assert length(errors) == 1
      assert hd(errors).file |> String.ends_with?("TypeNotFound.hx")
    end
  end
end