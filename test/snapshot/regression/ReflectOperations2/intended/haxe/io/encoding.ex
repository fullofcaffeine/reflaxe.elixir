defmodule Haxe.Io.Encoding do
  def utf8() do
    {:UTF8}
  end
  def utf16_le() do
    {:UTF16LE}
  end
  def utf16_be() do
    {:UTF16BE}
  end
  def utf32_le() do
    {:UTF32LE}
  end
  def utf32_be() do
    {:UTF32BE}
  end
  def raw_native() do
    {:RawNative}
  end
end