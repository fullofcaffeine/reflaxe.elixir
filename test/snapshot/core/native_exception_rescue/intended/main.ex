defmodule Main do
  def safely(fun) do
    try do
      fun.()
      :ok
    rescue
      error ->
        {:error, Exception.message(error)}
    end
  end
  def fail() do
    safely(fn -> Kernel.raise("boom") end)
  end
end
