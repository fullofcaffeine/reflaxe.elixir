defmodule FlashTypeTools do
  def toString(type) do
    fn type -> case (type.elem(0)) do
  0 ->
    "info"
  1 ->
    "success"
  2 ->
    "warning"
  3 ->
    "error"
end end
  end
  def fromString(str) do
    fn str -> g = str.toLowerCase()
case (g) do
  "error" ->
    :Error
  "info" ->
    :Info
  "success" ->
    :Success
  "warning" ->
    :Warning
  _ ->
    :Info
end end
  end
  def getCssClass(type) do
    fn type -> case (type.elem(0)) do
  0 ->
    "bg-blue-50 border-blue-200 text-blue-800"
  1 ->
    "bg-green-50 border-green-200 text-green-800"
  2 ->
    "bg-yellow-50 border-yellow-200 text-yellow-800"
  3 ->
    "bg-red-50 border-red-200 text-red-800"
end end
  end
  def getIconName(type) do
    fn type -> case (type.elem(0)) do
  0 ->
    "information-circle"
  1 ->
    "check-circle"
  2 ->
    "exclamation-triangle"
  3 ->
    "x-circle"
end end
  end
end