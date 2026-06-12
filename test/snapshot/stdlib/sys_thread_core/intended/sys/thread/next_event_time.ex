defmodule Sys.Thread.NextEventTime do
  def now() do
    {0}
  end
  def never() do
    {1}
  end
  def any_time(arg0) do
    {2, arg0}
  end
  def at(arg0) do
    {3, arg0}
  end
end
