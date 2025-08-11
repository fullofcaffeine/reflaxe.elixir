defmodule StacktraceIntegrationTest do
  @moduledoc """
  Comprehensive integration tests for Haxe stacktrace and error parsing functionality.
  
  Tests both the structured error parsing system and the Mix tasks that provide
  LLM agents with programmatic access to debugging information.
  """
  
  use ExUnit.Case, async: false

  alias HaxeCompiler
  alias Mix.Tasks.Haxe.Errors, as: ErrorTask
  alias Mix.Tasks.Haxe.Stacktrace, as: StacktraceTask

  setup do
    # Clear any existing errors before each test
    HaxeCompiler.clear_compilation_errors()
    
    # Create sample error outputs for testing
    sample_errors = create_sample_error_outputs()
    
    {:ok, sample_errors: sample_errors}
  end

  describe "Haxe error parsing" do
    test "parses standard compilation error format", %{sample_errors: samples} do
      error_output = samples.standard_error
      
      parsed_errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      assert length(parsed_errors) == 1
      
      error = hd(parsed_errors)
      assert error.type == :compilation_error
      assert error.level == :haxe
      assert error.file == "src_haxe/User.hx"
      assert error.line == 23
      assert error.column_start == 5
      assert error.column_end == 12
      assert error.error_type == "Type not found"
      assert error.message == "UnknownType"
      assert String.contains?(error.error_id, "haxe_error_")
    end

    test "parses multiple error types from mixed output", %{sample_errors: samples} do
      mixed_output = samples.mixed_errors
      
      parsed_errors = HaxeCompiler.parse_haxe_errors(mixed_output)
      
      assert length(parsed_errors) == 3
      
      # Check we got different types
      types = Enum.map(parsed_errors, & &1.type)
      assert :compilation_error in types
      assert :warning in types
      assert :stacktrace in types
    end

    test "handles malformed error lines gracefully" do
      malformed_output = """
      This is not an error line
      Another random line
      src_haxe/Test.hx:15: characters 1-5 : Type not found : BadType
      More random text
      """
      
      parsed_errors = HaxeCompiler.parse_haxe_errors(malformed_output)
      
      # Should only parse the valid error line
      assert length(parsed_errors) == 1
      assert hd(parsed_errors).file == "src_haxe/Test.hx"
    end

    test "generates unique error IDs for each error" do
      error_output = """
      src_haxe/User.hx:10: characters 1-5 : Type not found : BadType1
      src_haxe/Post.hx:20: characters 1-5 : Type not found : BadType2
      """
      
      parsed_errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      assert length(parsed_errors) == 2
      
      ids = Enum.map(parsed_errors, & &1.error_id)
      assert Enum.uniq(ids) == ids  # All IDs should be unique
      assert Enum.all?(ids, &String.contains?(&1, "haxe_error_"))
    end
  end

  describe "error storage and retrieval" do
    test "stores and retrieves errors correctly", %{sample_errors: samples} do
      # Parse and store errors
      parsed_errors = HaxeCompiler.parse_haxe_errors(samples.standard_error)
      
      # Should be able to retrieve them
      retrieved_errors = HaxeCompiler.get_compilation_errors(:map)
      
      assert length(retrieved_errors) == length(parsed_errors)
      assert hd(retrieved_errors).error_id == hd(parsed_errors).error_id
    end

    test "retrieves errors in JSON format" do
      parsed_errors = HaxeCompiler.parse_haxe_errors("src_haxe/Test.hx:1: Type not found : BadType")
      
      json_errors = HaxeCompiler.get_compilation_errors(:json)
      
      assert is_binary(json_errors)
      {:ok, decoded} = Jason.decode(json_errors)
      assert is_list(decoded)
      assert length(decoded) == 1
    end

    test "clears stored errors" do
      # Store some errors
      HaxeCompiler.parse_haxe_errors("src_haxe/Test.hx:1: Type not found : BadType")
      
      # Verify they're stored
      assert length(HaxeCompiler.get_compilation_errors(:map)) == 1
      
      # Clear them
      HaxeCompiler.clear_compilation_errors()
      
      # Verify they're gone
      assert HaxeCompiler.get_compilation_errors(:map) == []
    end
  end

  describe "Mix.Tasks.Haxe.Errors functionality" do
    setup do
      # Store some test errors
      test_output = """
      src_haxe/User.hx:10: characters 5-12 : Type not found : UnknownType
      Warning : Unused import in src_haxe/Post.hx
      src_haxe/UserLive.hx:25: characters 1-8 : Field not found : badField
      """
      
      HaxeCompiler.parse_haxe_errors(test_output)
      
      :ok
    end

    test "displays errors in table format" do
      # Capture output
      output = capture_mix_task(fn ->
        ErrorTask.run(["--format", "table"])
      end)
      
      assert String.contains?(output, "Compilation Errors")
      assert String.contains?(output, "User.hx:10")
      assert String.contains?(output, "Type not found")
    end

    test "outputs errors in JSON format" do
      # Capture output
      output = capture_mix_task(fn ->
        ErrorTask.run(["--format", "json"])
      end)
      
      # Should be valid JSON
      {:ok, parsed} = Jason.decode(output)
      assert is_list(parsed)
      assert length(parsed) > 0
      
      # Check structure
      error = hd(parsed)
      assert Map.has_key?(error, "type")
      assert Map.has_key?(error, "file")
      assert Map.has_key?(error, "line")
      assert Map.has_key?(error, "error_id")
    end

    test "filters errors by file" do
      output = capture_mix_task(fn ->
        ErrorTask.run(["--format", "json", "--file", "User.hx"])
      end)
      
      {:ok, parsed} = Jason.decode(output)
      assert length(parsed) == 1
      assert String.contains?(hd(parsed)["file"], "User.hx")
    end

    test "limits recent errors" do
      output = capture_mix_task(fn ->
        ErrorTask.run(["--format", "json", "--recent", "1"])
      end)
      
      {:ok, parsed} = Jason.decode(output)
      assert length(parsed) == 1
    end

    test "provides debugging suggestions in detailed format" do
      output = capture_mix_task(fn ->
        ErrorTask.run(["--format", "detailed"])
      end)
      
      assert String.contains?(output, "LLM Debugging Guidance")
      assert String.contains?(output, "Debug at HAXE level")
      assert String.contains?(output, "fix source")
    end
  end

  describe "Mix.Tasks.Haxe.Stacktrace functionality" do
    setup do
      # Create error with stacktrace
      error_output = """
      src_haxe/Main.hx:15: characters 5-12 : Type not found : UnknownType
          at Main.main (src_haxe/Main.hx line 15)
          at Init.start (src_haxe/Init.hx line 5)
      """
      
      errors = HaxeCompiler.parse_haxe_errors(error_output)
      error_id = hd(errors).error_id
      
      {:ok, error_id: error_id}
    end

    test "displays stacktrace in detailed format", %{error_id: error_id} do
      output = capture_mix_task(fn ->
        StacktraceTask.run([error_id, "--format", "detailed"])
      end)
      
      assert String.contains?(output, "Detailed Stacktrace Analysis")
      assert String.contains?(output, "Error Summary")
      assert String.contains?(output, "LLM Agent Debugging Recommendations")
      assert String.contains?(output, "Primary Action")
    end

    test "outputs stacktrace in JSON format", %{error_id: error_id} do
      output = capture_mix_task(fn ->
        StacktraceTask.run([error_id, "--format", "json"])
      end)
      
      {:ok, parsed} = Jason.decode(output)
      
      assert Map.has_key?(parsed, "error_id")
      assert Map.has_key?(parsed, "stacktrace")
      assert Map.has_key?(parsed, "debugging_guidance")
      assert parsed["error_id"] == error_id
    end

    test "shows cross-reference information", %{error_id: error_id} do
      output = capture_mix_task(fn ->
        StacktraceTask.run([error_id, "--cross-reference"])
      end)
      
      assert String.contains?(output, "Cross-Level Reference")
      assert String.contains?(output, "Haxe Source")
      assert String.contains?(output, "Generated Target")
      assert String.contains?(output, "mix haxe.inspect")
    end

    test "shows generation trace", %{error_id: error_id} do
      output = capture_mix_task(fn ->
        StacktraceTask.run([error_id, "--trace-generation"])
      end)
      
      assert String.contains?(output, "Code Generation Trace")
      assert String.contains?(output, "Haxe Compilation")
      assert String.contains?(output, "Reflaxe Transform")
      assert String.contains?(output, "Elixir Generation")
    end

    test "handles invalid error ID gracefully" do
      output = capture_mix_task(fn ->
        StacktraceTask.run(["invalid_error_id"])
      end)
      
      assert String.contains?(output, "Error ID not found")
      assert String.contains?(output, "mix haxe.errors")
    end
  end

  describe "LLM debugging workflow integration" do
    test "complete LLM debugging workflow simulation" do
      # Simulate compilation error
      error_output = """
      src_haxe/UserLive.hx:45: characters 12-20 : Field not found : badField on type User
          at UserLive.handle_event (src_haxe/UserLive.hx line 45)
          at LiveView.process_event (lib/LiveView.ex line 128)
      Warning : Unused variable 'socket' in src_haxe/UserLive.hx line 50
      """
      
      # Step 1: Parse and store errors (happens during compilation)
      parsed_errors = HaxeCompiler.parse_haxe_errors(error_output)
      assert length(parsed_errors) == 3  # Error + stacktrace + warning
      
      # Step 2: LLM gets structured error list
      json_errors = HaxeCompiler.get_compilation_errors(:json)
      {:ok, errors} = Jason.decode(json_errors)
      
      compilation_errors = Enum.filter(errors, fn e -> e["type"] == "compilation_error" end)
      assert length(compilation_errors) == 1
      
      error = hd(compilation_errors)
      error_id = error["error_id"]
      
      # Step 3: LLM analyzes specific stacktrace
      stacktrace_output = capture_mix_task(fn ->
        StacktraceTask.run([error_id, "--format", "json"])
      end)
      
      {:ok, stacktrace_data} = Jason.decode(stacktrace_output)
      
      # Step 4: Verify LLM gets complete debugging context
      assert Map.has_key?(stacktrace_data, "debugging_guidance")
      guidance = stacktrace_data["debugging_guidance"]
      assert guidance["debug_level"] == "HAXE (source level)"
      assert String.contains?(guidance["primary_action"], "Fix source code")
      
      # Step 5: Verify LLM can identify the abstraction level to debug
      assert stacktrace_data["level"] == "haxe"
      assert stacktrace_data["file"] == "src_haxe/UserLive.hx"
      assert stacktrace_data["line"] == 45
    end

    test "performance requirements for LLM iteration cycles" do
      # Test parsing performance with large error output
      large_error_output = Enum.map(1..100, fn i ->
        "src_haxe/Module#{i}.hx:#{i}: characters 1-5 : Type not found : BadType#{i}"
      end) |> Enum.join("\n")
      
      start_time = System.monotonic_time(:millisecond)
      parsed_errors = HaxeCompiler.parse_haxe_errors(large_error_output)
      parse_time = System.monotonic_time(:millisecond) - start_time
      
      # Should parse 100 errors quickly (under 100ms for LLM compatibility)
      assert length(parsed_errors) == 100
      assert parse_time < 100, "Error parsing should be fast for LLM iteration (<100ms), took #{parse_time}ms"
      
      # Test JSON serialization performance  
      start_time = System.monotonic_time(:millisecond)
      json_output = HaxeCompiler.get_compilation_errors(:json)
      json_time = System.monotonic_time(:millisecond) - start_time
      
      assert String.length(json_output) > 0
      assert json_time < 50, "JSON serialization should be fast (<50ms), took #{json_time}ms"
    end
  end

  describe "error parsing edge cases" do
    test "handles empty output" do
      assert HaxeCompiler.parse_haxe_errors("") == []
    end

    test "handles output with only whitespace" do
      assert HaxeCompiler.parse_haxe_errors("   \n\t  \n  ") == []
    end

    test "handles very long error messages" do
      long_message = String.duplicate("Very long error message ", 100)
      error_output = "src_haxe/Test.hx:1: Type error : #{long_message}"
      
      parsed_errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      assert length(parsed_errors) == 1
      error = hd(parsed_errors)
      assert String.length(error.message) > 1000
      assert error.message == long_message
    end

    test "handles unicode characters in file paths and messages" do
      error_output = "src_haxe/用户.hx:10: Type not found : 类型未找到"
      
      parsed_errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      assert length(parsed_errors) == 1
      error = hd(parsed_errors)
      assert error.file == "src_haxe/用户.hx"
      assert error.message == "类型未找到"
    end

    test "handles errors without column information" do
      error_output = "src_haxe/Simple.hx:5: Type not found : BadType"
      
      parsed_errors = HaxeCompiler.parse_haxe_errors(error_output)
      
      assert length(parsed_errors) == 1
      error = hd(parsed_errors)
      assert is_nil(error.column_start)
      assert is_nil(error.column_end)
    end
  end

  # Helper functions for testing

  defp create_sample_error_outputs do
    %{
      standard_error: "src_haxe/User.hx:23: characters 5-12 : Type not found : UnknownType",
      
      mixed_errors: """
      src_haxe/User.hx:10: characters 5-12 : Type not found : UnknownType
      Warning : Unused import in src_haxe/Post.hx
          at Main.process (src_haxe/Main.hx line 45)
      """,
      
      stacktrace_error: """
      src_haxe/Main.hx:15: characters 5-12 : Type not found : UnknownType
          at Main.main (src_haxe/Main.hx line 15)
          at Init.start (src_haxe/Init.hx line 5)
      """
    }
  end

  defp capture_mix_task(task_fun) do
    # Capture IO output from Mix task
    try do
      ExUnit.CaptureIO.capture_io(task_fun)
    catch
      # Some Mix tasks might throw, capture the error
      kind, error -> 
        "Error: #{kind} - #{inspect(error)}"
    end
  end
end