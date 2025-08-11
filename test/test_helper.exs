# Test environment setup
# Set up paths for Haxe compiler
System.put_env("HAXE_PATH", System.find_executable("haxe") || "haxe")
System.put_env("NPX_PATH", System.find_executable("npx") || "npx")

# Ensure test fixtures directory exists
File.mkdir_p!("test/fixtures")

# Start ExUnit
ExUnit.start()