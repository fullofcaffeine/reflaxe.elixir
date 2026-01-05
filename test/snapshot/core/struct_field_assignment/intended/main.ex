defmodule Main do
  def main() do
    test = %TestStruct{}
    _ = TestStruct.write(test, nil)
  end
end
