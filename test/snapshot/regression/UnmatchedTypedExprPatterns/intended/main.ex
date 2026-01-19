defmodule Main do
  def main() do
    x = 1
    _y = (x + 1) * 2
    z = 42
    _num = z
    _type_name = List.last(Module.split(Main))
    nil
  end
end
