defmodule Phoenix.Test.ConnState do
  def unset() do
    {:unset}
  end
  def sent() do
    {:sent}
  end
  def halted() do
    {:halted}
  end
end
