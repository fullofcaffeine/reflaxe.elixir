defmodule FlashTypeTools do
  def to_string(type) do
    temp_result = nil
    case (type) do
      {:info} ->
        temp_result = "info"
      {:success} ->
        temp_result = "success"
      {:warning} ->
        temp_result = "warning"
      {:error} ->
        temp_result = "error"
    end
    temp_result
  end
  def from_string(str) do
    temp_result = nil
    g = str.to_lower_case()
    case (g) do
      "error" ->
        temp_result = {:error}
      "info" ->
        temp_result = {:info}
      "success" ->
        temp_result = {:success}
      "warning" ->
        temp_result = {:warning}
      _ ->
        temp_result = {:info}
    end
    temp_result
  end
  def get_css_class(type) do
    temp_result = nil
    case (type) do
      {:info} ->
        temp_result = "bg-blue-50 border-blue-200 text-blue-800"
      {:success} ->
        temp_result = "bg-green-50 border-green-200 text-green-800"
      {:warning} ->
        temp_result = "bg-yellow-50 border-yellow-200 text-yellow-800"
      {:error} ->
        temp_result = "bg-red-50 border-red-200 text-red-800"
    end
    temp_result
  end
  def get_icon_name(type) do
    temp_result = nil
    case (type) do
      {:info} ->
        temp_result = "information-circle"
      {:success} ->
        temp_result = "check-circle"
      {:warning} ->
        temp_result = "exclamation-triangle"
      {:error} ->
        temp_result = "x-circle"
    end
    temp_result
  end
end