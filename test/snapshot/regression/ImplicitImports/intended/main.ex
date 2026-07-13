defmodule Main do
  def main() do
    BitwiseOperations.test_bitwise()
    BitwiseOperations.complex_bitwise()
    assigns = %{class_name: "container", title: "Test Title", content: "Test content", type: "button", disabled: false, label: "Click me"}
    TestAppWeb.TestComponent.template(assigns)
    TestAppWeb.TestComponent.button(assigns)
    nil
  end
end
