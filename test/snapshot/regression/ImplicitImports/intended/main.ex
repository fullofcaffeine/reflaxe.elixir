defmodule Main do
  def main() do
    BitwiseOperations.test_bitwise()
    BitwiseOperations.complex_bitwise()
    assigns = %{:class_name => "container", :title => "Test Title", :content => "Test content", :type => "button", :disabled => false, :label => "Click me"}
    TestAppWeb.TestComponent.render(assigns)
    TestAppWeb.TestComponent.button(assigns)
    Log.trace("Implicit imports test compiled successfully", %{:file_name => "Main.hx", :line_number => 119, :class_name => "Main", :method_name => "main"})
  end
end

Code.require_file("bitwise_operations.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("std.ex", __DIR__)
Code.require_file("test_app_web.test_component.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()