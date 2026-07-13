defmodule Main do
  def main() do
    test = PropertySetterTest.new()
    PropertySetterTest.set_value(test, 42)
    PropertySetterTest.set_name(test, "Test")
    if (test.value == 42 and test.name == "Test"), do: nil
    PropertySetterTest.set_value(test, 100)
    PropertySetterTest.set_name(test, "Updated")
    if (test.value == 100 and test.name == "Updated"), do: nil
  end
end
