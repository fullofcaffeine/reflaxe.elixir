defmodule CaseResultAssignmentMergeTest do
  def choose_border(priority) do
    (case priority do
      "high" -> "border-red-500"
      "low" -> "border-green-500"
      "medium" -> "border-yellow-500"
      _ -> "border-gray-300"
    end)
  end
end
