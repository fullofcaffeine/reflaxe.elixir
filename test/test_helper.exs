# Test environment setup
# Set up paths for Haxe compiler
System.put_env("HAXE_PATH", System.find_executable("haxe") || "haxe")
System.put_env("NPX_PATH", System.find_executable("npx") || "npx")

# Ensure test fixtures directory exists
File.mkdir_p!("test/fixtures")

# Compile test support modules
Code.compile_file("test/support/haxe_test_helper.ex")

# Configure ExUnit to run tests sequentially to avoid port conflicts
# This is especially important for HaxeServer tests that use port 6000
ExUnit.configure(max_cases: 1)

# Start ExUnit
ExUnit.start()