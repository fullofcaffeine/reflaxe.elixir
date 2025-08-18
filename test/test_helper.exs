# Test environment setup
# Set up paths for Haxe compiler
System.put_env("HAXE_PATH", System.find_executable("haxe") || "haxe")
System.put_env("NPX_PATH", System.find_executable("npx") || "npx")

# Set HAXELIB_PATH to project's haxe_libraries for test environments
project_root = Path.expand(Path.join([__DIR__, ".."]))
haxe_libraries_path = Path.join(project_root, "haxe_libraries")
System.put_env("HAXELIB_PATH", haxe_libraries_path)

# Ensure test fixtures directory exists
File.mkdir_p!("test/fixtures")

# Compile test support modules
Code.compile_file("test/support/haxe_test_helper.ex")

# Configure ExUnit for parallel execution (default: 2x CPU cores)
# Tests with async: false will still run sequentially as needed
# Remove max_cases limitation to enable default parallel execution

# Start ExUnit
ExUnit.start()