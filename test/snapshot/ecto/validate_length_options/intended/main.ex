defmodule Main do
  def main() do
    title = "hello"
    cs = %{:title => title}
    opts = %{:min => 3, :max => nil, :is => nil}
    _ = Ecto.Changeset.validate_length(cs, String.to_atom(opts), Enum.filter([], fn {_, v} -> v != nil end))
  end
end
