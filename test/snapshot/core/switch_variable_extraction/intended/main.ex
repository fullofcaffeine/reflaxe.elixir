defmodule Main do
  def process_enum(msg) do
    (case msg do
      {:created, content} -> "Created: #{content}"
      {:updated, content, ts} -> "Updated at #{Kernel.to_string(ts)}: #{content}"
      {:deleted} -> "Deleted"
    end)
  end
  def process_with_variable(msg) do
    (case msg do
      {:created, content} -> "Created: #{content}"
      {:updated, content, ts} -> "Updated at #{Kernel.to_string(ts)}: #{content}"
      {:deleted} -> "Deleted"
    end)
  end
  def main() do
    nil
  end
end
