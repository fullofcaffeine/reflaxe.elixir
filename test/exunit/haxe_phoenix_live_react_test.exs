# HOST BOOTSTRAP BOUNDARY: Mix discovers this file before the Haxe-authored ExUnit
# modules can be loaded as tests. Test behavior lives in test/haxe_exunit/live_react;
# this file only loads the compiler output produced by test_helper.exs.
generated_dir = Path.expand("../fixtures/_generated_haxe_exunit", __DIR__)

HaxeExUnitBootstrap.format_and_require_generated!(generated_dir, [
  "haxe_phoenix_live_react_test/support.ex",
  "haxe_phoenix_live_react_test.ex",
  "mix/tasks/haxe/phoenix/live_react_test.ex"
])
