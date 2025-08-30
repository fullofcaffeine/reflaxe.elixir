defmodule ApplicationArgs_Impl_ do
  def fromDynamic() do
    fn value -> value end
  end
  def toDynamic() do
    fn this_1 -> this_1 end
  end
end