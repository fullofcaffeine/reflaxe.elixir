defmodule PlainValues do
  def nested_ignored(input, outcome) do
    (case input do
      {:accepted, request} ->
        (case outcome do
          {:accepted, _} -> request
          {:denied} -> -2
        end)
      {:denied} -> -1
    end)
  end
end
