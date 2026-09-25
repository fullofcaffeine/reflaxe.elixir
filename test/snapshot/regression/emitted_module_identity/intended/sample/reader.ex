defmodule Sample.Reader do
  def new() do
    %{:__reflaxe_class__ => Sample.Reader}
  end
  def run(_struct, input) do
    (case (if (Kernel.is_binary(input)), do: {:ok, input}, else: {:error, {:expected_type, {:binary}, TermDecoder.kind(input)}}) do
      {:ok, _value} ->
        Shared_Fields_.value()
      {:error, _error} -> -1
    end)
  end
end
