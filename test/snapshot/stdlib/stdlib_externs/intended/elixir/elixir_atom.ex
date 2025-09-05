defmodule ElixirAtom do
  def ok() do
    {:OK}
  end
  def stop() do
    {:STOP}
  end
  def reply() do
    {:REPLY}
  end
  def noreply() do
    {:NOREPLY}
  end
  def continue() do
    {:CONTINUE}
  end
  def hibernate() do
    {:HIBERNATE}
  end
end