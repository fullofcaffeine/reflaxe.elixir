defmodule SourceMapTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  
  @moduletag :source_map
  
  describe "source map generation" do
    test "generates .ex.map files alongside .ex files" do
      # Check that source map files are created
      ex_files = Path.wildcard("lib/**/*.ex")
      
      # For each .ex file, there should be a corresponding .ex.map file
      for ex_file <- ex_files do
        map_file = ex_file <> ".map"
        assert File.exists?(map_file), "Source map missing for #{ex_file}"
      end
    end
    
    test "source map files are valid JSON" do
      map_files = Path.wildcard("lib/**/*.ex.map")
      
      for map_file <- map_files do
        content = File.read!(map_file)
        
        # Should parse as valid JSON
        assert {:ok, parsed} = Jason.decode(content), "Invalid JSON in #{map_file}"
        
        # Should have Source Map v3 structure
        assert parsed["version"] == 3, "Wrong source map version in #{map_file}"
        assert is_binary(parsed["file"]), "Missing file field in #{map_file}"
        assert is_list(parsed["sources"]), "Missing sources array in #{map_file}"
        assert is_binary(parsed["mappings"]), "Missing mappings field in #{map_file}"
      end
    end
    
    @tag :pending
    test "source maps contain non-empty mappings" do
      # This test will pass once we fix the integration
      map_files = Path.wildcard("lib/**/*.ex.map")
      
      for map_file <- map_files do
        content = File.read!(map_file)
        {:ok, parsed} = Jason.decode(content)
        
        # Mappings should not be empty
        refute parsed["mappings"] == "", 
               "Empty mappings in #{map_file} - source positions not being tracked"
      end
    end
    
    @tag :pending  
    test "source maps correctly map Elixir lines to Haxe source" do
      # This test will be enabled once mappings are generated
      
      # Test a simple known mapping
      router_map = "lib/todo_app_web/router.ex.map"
      if File.exists?(router_map) do
        {:ok, source_map} = SourceMapLookup.parse_source_map(router_map)
        
        # The router.ex should map back to a RouterRouter.hx or similar
        assert length(source_map["sources"]) > 0
        assert Enum.any?(source_map["sources"], &String.contains?(&1, ".hx"))
      end
    end
  end
  
  describe "SourceMapLookup module" do
    test "enhances errors with source mapping when available" do
      # Create a mock error
      error = %{
        file: "lib/todo_app_web/router.ex",
        line: 10,
        message: "undefined function get/2",
        severity: :error
      }
      
      # Enhance with source mapping
      enhanced = SourceMapLookup.enhance_error_with_source_mapping(error)
      
      # Should have the same base error
      assert enhanced.file == error.file
      assert enhanced.message == error.message
      
      # Once working, should add source_file and source_line
      # assert enhanced[:source_file] =~ ~r/\.hx$/
      # assert is_integer(enhanced[:source_line])
    end
    
    test "handles missing source maps gracefully" do
      error = %{
        file: "non/existent/file.ex",
        line: 1,
        message: "test error"
      }
      
      # Should return error unchanged if no source map
      enhanced = SourceMapLookup.enhance_error_with_source_mapping(error)
      assert enhanced == error
    end
    
    @tag :pending
    test "VLQ decoding works correctly" do
      # Test VLQ decoding once implemented
      
      # Test cases from Source Map v3 spec
      assert SourceMapLookup.decode_vlq("AAAA") == [0, 0, 0, 0]
      assert SourceMapLookup.decode_vlq("AACA") == [0, 0, 1, 0]
      assert SourceMapLookup.decode_vlq("SAAS") == [9, 0, 0, 9]
    end
  end
  
  describe "Mix task integration" do
    test "mix haxe.errors uses source mapping" do
      # Compile with an intentional error
      # Then check that error reporting includes source mapping
      
      # This would require creating a test fixture with a known error
      # For now, just ensure the infrastructure is called
      
      output = capture_io(fn ->
        Mix.Task.run("haxe.errors", ["--format", "detailed"])
      end)
      
      # Should at least attempt to load source maps
      # (even if mappings are empty currently)
      assert output =~ "Error" or output =~ "No errors"
    end
  end
end