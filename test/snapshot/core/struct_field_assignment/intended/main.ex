defmodule Main do
  def main() do
    test = TestStruct.new()
    _ = TestStruct.write(test, nil)
  end
end
