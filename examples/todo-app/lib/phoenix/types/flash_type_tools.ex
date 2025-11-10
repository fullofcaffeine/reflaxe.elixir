defmodule FlashTypeTools do
  def to_phoenix_key(type) do
    (case type do
      {:info} -> "info"
      {:error} -> "error"
    end)
  end
end
