defmodule Main do
  def main() do
    _ = BitwiseOperations.test_bitwise()
    _ = BitwiseOperations.complex_bitwise()
    assigns = %{:class_name => "container", :title => "Test Title", :content => "Test content", :type => "button", :disabled => false, :label => "Click me"}
    _ = TestAppWeb.TestComponent.template(assigns)
    _ = TestAppWeb.TestComponent.button(assigns)
    nil
  end
end
