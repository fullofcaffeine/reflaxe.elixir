defmodule Main do
  def main() do
    test = %PropertySetterTest{}
    _ = PropertySetterTest.set_value(test, 42)
    _ = PropertySetterTest.set_name(test, "Test")
    if (test.value == 42 and test.name == "Test"), do: nil
    _ = PropertySetterTest.set_value(test, 100)
    _ = PropertySetterTest.set_name(test, "Updated")
    if (test.value == 100 and test.name == "Updated"), do: nil
  end
end
