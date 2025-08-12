defmodule TestRunnerUpdateIntendedTest do
  @moduledoc """
  Test suite for TestRunner's update-intended functionality
  
  Validates the fix for the broken update-intended mechanism that was
  previously compiling directly to intended/ instead of copying from out/.
  """
  use ExUnit.Case

  @test_dir "test/tests/test_update_intended"
  @hxml_content """
  # Test compile.hxml for update-intended testing
  -cp ../../../std
  -cp ../../../src
  -cp .
  -lib reflaxe
  --macro reflaxe.elixir.CompilerInit.Start()
  -D elixir_output=out
  Main
  """

  @haxe_content """
  class Main {
    public static function main() {
      trace("update-intended test");
    }
  }
  """

  setup do
    # Clean up any existing test directory
    if File.exists?(@test_dir), do: File.rm_rf!(@test_dir)
    
    # Create test directory structure
    File.mkdir_p!(@test_dir)
    File.write!("#{@test_dir}/compile.hxml", @hxml_content)
    File.write!("#{@test_dir}/Main.hx", @haxe_content)
    
    # Ensure we clean up after test
    on_exit(fn ->
      if File.exists?(@test_dir), do: File.rm_rf!(@test_dir)
    end)
    
    :ok
  end

  test "update-intended copies files from out/ to intended/ directory" do
    # First, run update-intended to generate both out/ and intended/ directories
    {output, 0} = System.cmd("haxe", ["test/Test.hxml", "test=test_update_intended", "update-intended"], 
                              stderr_to_stdout: true)
    
    assert String.contains?(output, "Updated intended output"), 
           "Should show success message for update-intended"
    
    # Verify both directories exist
    out_dir = "#{@test_dir}/out"
    intended_dir = "#{@test_dir}/intended"
    
    assert File.exists?(out_dir), "out/ directory should exist after compilation"
    assert File.exists?(intended_dir), "intended/ directory should exist after update-intended"
    
    # Verify files were generated and copied
    out_files = File.ls!(out_dir)
    intended_files = File.ls!(intended_dir)
    
    assert length(out_files) > 0, "out/ directory should contain compiled files"
    assert length(intended_files) > 0, "intended/ directory should contain copied files"
    assert Enum.sort(out_files) == Enum.sort(intended_files), "File lists should match"
    
    # Compare file contents to ensure proper copying
    for file <- out_files do
      out_file = "#{out_dir}/#{file}"
      intended_file = "#{intended_dir}/#{file}"
      
      assert File.exists?(intended_file), "File #{file} should be copied to intended/"
      
      out_content = File.read!(out_file)
      intended_content = File.read!(intended_file)
      assert out_content == intended_content, "File contents should match between out/ and intended/"
    end
    
    # Final verification: run test again to ensure it passes with intended output
    {final_output, 0} = System.cmd("haxe", ["test/Test.hxml", "test=test_update_intended"], 
                              stderr_to_stdout: true)
    
    assert String.contains?(final_output, "Output matches intended"), 
           "Test should pass after update-intended creates proper baseline"
  end

  test "update-intended handles multiple files correctly" do
    # Create additional Haxe file 
    File.write!("#{@test_dir}/Utils.hx", "class Utils { public static function helper() {} }")
    
    # Update compile.hxml to include both files
    hxml_with_multiple = """
    # Test compile.hxml for update-intended testing
    -cp ../../../std
    -cp ../../../src
    -cp .
    -lib reflaxe
    --macro reflaxe.elixir.CompilerInit.Start()
    -D elixir_output=out
    Main
    Utils
    """
    File.write!("#{@test_dir}/compile.hxml", hxml_with_multiple)
    
    # Run update-intended with multiple files
    {output, 0} = System.cmd("haxe", ["test/Test.hxml", "test=test_update_intended", "update-intended"],
                             stderr_to_stdout: true)
    
    assert String.contains?(output, "Updated intended output")
    
    # Verify both directories exist and have multiple files
    intended_dir = "#{@test_dir}/intended"
    out_dir = "#{@test_dir}/out"
    
    out_files = File.ls!(out_dir)
    intended_files = File.ls!(intended_dir)
    
    assert length(out_files) >= 2, "Should have at least Main.ex and Utils.ex files"
    assert length(intended_files) >= 2, "intended/ should have same files as out/"
    assert Enum.sort(out_files) == Enum.sort(intended_files), "File lists should match"
    
    # Verify content matches
    verify_directory_structure_match(out_dir, intended_dir)
  end

  defp verify_directory_structure_match(source_dir, dest_dir) do
    source_files = get_all_files(source_dir)
    dest_files = get_all_files(dest_dir)
    
    assert Enum.sort(source_files) == Enum.sort(dest_files), 
           "Directory structures should match between #{source_dir} and #{dest_dir}"
  end

  defp get_all_files(dir) do
    case File.ls(dir) do
      {:ok, files} ->
        Enum.flat_map(files, fn file ->
          path = "#{dir}/#{file}"
          if File.dir?(path) do
            get_all_files(path) |> Enum.map(&("#{file}/#{&1}"))
          else
            [file]
          end
        end)
      {:error, _} -> []
    end
  end
end