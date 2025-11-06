defmodule Elixir.Types.Result do
  def ok(arg0) do
    {:ok, arg0}
  end
  def error(arg0) do
    {:error, arg0}
  end
end
