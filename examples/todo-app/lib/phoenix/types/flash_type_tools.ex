defmodule FlashTypeTools do
  def to_string(_type) do
    case (_type) do
      {:info} ->
        "info"
      {:success} ->
        "success"
      {:warning} ->
        "warning"
      {:error} ->
        "error"
    end
  end
  def from_string(_str) do
    g = _str.to_lower_case()
    case (g) do
      "error" ->
        {:error}
      "info" ->
        {:info}
      "success" ->
        {:success}
      "warning" ->
        {:warning}
      _ ->
        {:info}
    end
  end
  def get_css_class(_type) do
    case (_type) do
      {:info} ->
        "bg-blue-50 border-blue-200 text-blue-800"
      {:success} ->
        "bg-green-50 border-green-200 text-green-800"
      {:warning} ->
        "bg-yellow-50 border-yellow-200 text-yellow-800"
      {:error} ->
        "bg-red-50 border-red-200 text-red-800"
    end
  end
  def get_icon_name(_type) do
    case (_type) do
      {:info} ->
        "information-circle"
      {:success} ->
        "check-circle"
      {:warning} ->
        "exclamation-triangle"
      {:error} ->
        "x-circle"
    end
  end
end