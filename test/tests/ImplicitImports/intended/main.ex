defmodule Main do
  defp main() do
    BitwiseOperations.test_bitwise()
    BitwiseOperations.complex_bitwise()
    assigns = %{:className => "container", :title => "Test Title", :content => "Test content", :type => "button", :disabled => false, :label => "Click me"}
    TestComponent.render(assigns)
    TestComponent.button(assigns)
    Log.trace("Implicit imports test compiled successfully", %{:fileName => "Main.hx", :lineNumber => 119, :className => "Main", :methodName => "main"})
  end
end