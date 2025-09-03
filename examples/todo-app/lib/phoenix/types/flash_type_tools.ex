defmodule FlashTypeTools do
  def to_string(_type) do
    case (type.elem(0)) do
      0 ->
        "info"
      1 ->
        "success"
      2 ->
        "warning"
      3 ->
        "error"
    end
  end
  def from_string(str) do
    g = str.toLowerCase()
    case (g) do
      "error" ->
        :error
      "info" ->
        :info
      "success" ->
        :success
      "warning" ->
        :warning
      _ ->
        :info
    end
  end
  def get_css_class(_type) do
    case (type.elem(0)) do
      0 ->
        "bg-blue-50 border-blue-200 text-blue-800"
      1 ->
        "bg-green-50 border-green-200 text-green-800"
      2 ->
        "bg-yellow-50 border-yellow-200 text-yellow-800"
      3 ->
        "bg-red-50 border-red-200 text-red-800"
    end
  end
  def get_icon_name(_type) do
    case (type.elem(0)) do
      0 ->
        "information-circle"
      1 ->
        "check-circle"
      2 ->
        "exclamation-triangle"
      3 ->
        "x-circle"
    end
  end
end