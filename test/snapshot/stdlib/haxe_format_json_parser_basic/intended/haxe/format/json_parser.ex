defmodule JsonParser do
  def parse(str) do
    Jason.decode!(str)
  end
end
