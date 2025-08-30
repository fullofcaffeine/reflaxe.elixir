defmodule ApplicationArgs_Impl_ do
  def fromDynamic(value) do
    fn value -> value end
  end
  def toDynamic(this1) do
    fn this_1 -> this_1 end
  end
end