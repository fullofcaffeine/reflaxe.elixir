defmodule ApplicationResultTools do
  def ok(state) do
    {:ok, state}
  end
  def error(reason) do
    {:error, reason}
  end
  def ignore() do
    {:ignore}
  end
end