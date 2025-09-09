defmodule Main do
  def main() do
    test = TestStruct.new()
    test.write(nil)
  end
end

Code.require_file("main.ex", __DIR__)
Main.main()