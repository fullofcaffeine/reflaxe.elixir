defmodule Haxe.Io.Encoding do
  def utf8() do
    {0}
  end
  def utf16_le() do
    {1}
  end
  def utf16_be() do
    {2}
  end
  def utf32_le() do
    {3}
  end
  def utf32_be() do
    {4}
  end
  def raw_native() do
    {5}
  end
end