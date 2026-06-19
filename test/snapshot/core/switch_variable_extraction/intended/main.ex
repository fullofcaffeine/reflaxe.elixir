defmodule Main do
  def process_enum(msg) do
    (case msg do
      {:created, content} -> "Created: #{content}"
      {:updated, content, ts} -> "Updated at #{Reflaxe.Elixir.HaxeFloat.to_string(ts)}: #{content}"
      {:deleted} -> "Deleted"
    end)
  end
  def process_with_variable(msg) do
    (case msg do
      {:created, content} -> "Created: #{content}"
      {:updated, content, ts} -> "Updated at #{Reflaxe.Elixir.HaxeFloat.to_string(ts)}: #{content}"
      {:deleted} -> "Deleted"
    end)
  end
  def main() do
    nil
  end
end
