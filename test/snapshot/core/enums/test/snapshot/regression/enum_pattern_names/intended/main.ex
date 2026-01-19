defmodule Main do
  def handle_status(status) do
    (case status do
      {:success, data} -> "Data: #{data}"
      {:error, message, code} -> "Error #{Kernel.to_string(code)}: #{message}"
      {:processing} -> "Still processing..."
    end)
  end
  def main() do
    nil
  end
end
