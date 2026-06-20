defmodule TestModuleTest do
  use ExUnit.Case

  test "generated module returns integration message" do
    assert TestModule.get_message() == "Mix integration successful!"
  end
end
