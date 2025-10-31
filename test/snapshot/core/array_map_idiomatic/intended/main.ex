defmodule Main do
  defp process_number(n) do
    "Processed: #{(fn -> n end).()}"
  end
  defp generate_id(name) do
    length(name) * 100
  end
  defp string_value(s) do
    %{:type => "StringValue", :value => s}
  end
  defp array_value(arr) do
    %{:type => "ArrayValue", :items => arr}
  end
end
