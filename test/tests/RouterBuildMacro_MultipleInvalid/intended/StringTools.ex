defmodule StringTools do
  use Bitwise
  @moduledoc """
  StringTools module generated from Haxe
  
  
 * StringTools for Reflaxe.Elixir
 * 
 * Basic implementation that provides required methods for compilation.
 * The actual Elixir code generation is handled by the compiler.
 
  """

  # Static functions
  @doc "Function is_space"
  @spec is_space(String.t(), integer()) :: boolean()
  def is_space(arg0, arg1) do
    (
  if (arg1 < 0 || arg1 >= String.length(arg0)), do: false, else: nil
  c = case String.at(arg0, arg1) do nil -> nil; c -> :binary.first(c) end
  c > 8 && c < 14 || c == 32
)
  end

  @doc "Function ltrim"
  @spec ltrim(String.t()) :: String.t()
  def ltrim(arg0) do
    (
  l = String.length(arg0)
  r = 0
  (fn loop_fn ->
  if (r < l && StringTools.isSpace(arg0, r)) do
    r + 1
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
  if (r > 0), do: String.slice(arg0, r, l - r), else: arg0
)
  end

  @doc "Function rtrim"
  @spec rtrim(String.t()) :: String.t()
  def rtrim(arg0) do
    (
  l = String.length(arg0)
  r = 0
  (fn loop_fn ->
  if (r < l && StringTools.isSpace(arg0, l - r - 1)) do
    r + 1
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
  if (r > 0), do: String.slice(arg0, 0, l - r), else: arg0
)
  end

  @doc "Function trim"
  @spec trim(String.t()) :: String.t()
  def trim(arg0) do
    StringTools.ltrim(StringTools.rtrim(arg0))
  end

  @doc "Function url_encode"
  @spec url_encode(String.t()) :: String.t()
  def url_encode(arg0) do
    arg0
  end

  @doc "Function url_decode"
  @spec url_decode(String.t()) :: String.t()
  def url_decode(arg0) do
    arg0
  end

  @doc "Function html_escape"
  @spec html_escape(String.t(), Null.t()) :: String.t()
  def html_escape(arg0, arg1) do
    (
  arg0 = Enum.join(String.split(arg0, "&"), "&amp;")
  arg0 = Enum.join(String.split(arg0, "<"), "&lt;")
  arg0 = Enum.join(String.split(arg0, ">"), "&gt;")
  if ((arg1)), do: (
  arg0 = Enum.join(String.split(arg0, "\""), "&quot;")
  arg0 = Enum.join(String.split(arg0, "'"), "&#039;")
), else: nil
  arg0
)
  end

  @doc "Function html_unescape"
  @spec html_unescape(String.t()) :: String.t()
  def html_unescape(arg0) do
    Enum.join(String.split(Enum.join(String.split(Enum.join(String.split(Enum.join(String.split(Enum.join(String.split(arg0, "&gt;"), ">"), "&lt;"), "<"), "&quot;"), "\""), "&#039;"), "'"), "&amp;"), "&")
  end

  @doc "Function starts_with"
  @spec starts_with(String.t(), String.t()) :: boolean()
  def starts_with(arg0, arg1) do
    String.length(arg0) >= String.length(arg1) && String.slice(arg0, 0, String.length(arg1)) == arg1
  end

  @doc "Function ends_with"
  @spec ends_with(String.t(), String.t()) :: boolean()
  def ends_with(arg0, arg1) do
    (
  elen = String.length(arg1)
  slen = String.length(arg0)
  slen >= elen && String.slice(arg0, slen - elen, elen) == arg1
)
  end

  @doc "Function replace"
  @spec replace(String.t(), String.t(), String.t()) :: String.t()
  def replace(arg0, arg1, arg2) do
    Enum.join(String.split(arg0, arg1), arg2)
  end

  @doc "Function lpad"
  @spec lpad(String.t(), String.t(), integer()) :: String.t()
  def lpad(arg0, arg1, arg2) do
    (
  if (String.length(arg1) <= 0), do: arg0, else: nil
  buf = ""
  arg2 = arg2 - String.length(arg0)
  (fn loop_fn ->
  if (String.length(buf) < arg2) do
    buf = buf <> arg1
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
  buf <> arg0
)
  end

  @doc "Function rpad"
  @spec rpad(String.t(), String.t(), integer()) :: String.t()
  def rpad(arg0, arg1, arg2) do
    (
  if (String.length(arg1) <= 0), do: arg0, else: nil
  buf = arg0
  (fn loop_fn ->
  if (String.length(buf) < arg2) do
    buf = buf <> arg1
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
  buf
)
  end

  @doc "Function contains"
  @spec contains(String.t(), String.t()) :: boolean()
  def contains(arg0, arg1) do
    case :binary.match(arg0, arg1) do {pos, _} -> pos; :nomatch -> -1 end != -1
  end

  @doc "Function fast_code_at"
  @spec fast_code_at(String.t(), integer()) :: integer()
  def fast_code_at(arg0, arg1) do
    case String.at(arg0, arg1) do nil -> nil; c -> :binary.first(c) end
  end

  @doc "Function unsafe_code_at"
  @spec unsafe_code_at(String.t(), integer()) :: integer()
  def unsafe_code_at(arg0, arg1) do
    case String.at(arg0, arg1) do nil -> nil; c -> :binary.first(c) end
  end

  @doc "Function is_eof"
  @spec is_eof(integer()) :: boolean()
  def is_eof(arg0) do
    false
  end

  @doc "Function hex"
  @spec hex(integer(), Null.t()) :: String.t()
  def hex(arg0, arg1) do
    (
  s = ""
  hex_chars = "0123456789ABCDEF"
  if (arg0 < 0), do: (
  arg0 = -arg0
  s = "-"
), else: nil
  if (arg0 == 0), do: s = "0", else: (
  result = ""
  (fn loop_fn ->
  if (arg0 > 0) do
    (
  result = String.at(hex_chars, arg0 &&& 15) <> result
  arg0 = Bitwise.>>>(arg0, 4)
)
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
  s = s <> result
)
  if (arg1 != nil), do: (fn loop_fn ->
  if (String.length(s) < arg1) do
    s = "0" <> s
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end), else: nil
  s
)
  end

  @doc "Function iterator"
  @spec iterator(String.t()) :: StringIterator.t()
  def iterator(arg0) do
    Haxe.Iterators.StringIterator.new(arg0)
  end

  @doc "Function key_value_iterator"
  @spec key_value_iterator(String.t()) :: StringKeyValueIterator.t()
  def key_value_iterator(arg0) do
    Haxe.Iterators.StringKeyValueIterator.new(arg0)
  end

  @doc "Function quote_unix_arg"
  @spec quote_unix_arg(String.t()) :: String.t()
  def quote_unix_arg(arg0) do
    (
  if (arg0 == ""), do: "''", else: nil
  "'" <> StringTools.replace(arg0, "'", "'\"'\"'") <> "'"
)
  end

  @doc "Function quote_win_arg"
  @spec quote_win_arg(String.t(), boolean()) :: String.t()
  def quote_win_arg(arg0, arg1) do
    (
  if (case :binary.match(arg0, " ") do {pos, _} -> pos; :nomatch -> -1 end != -1 || arg0 == ""), do: arg0 = "\"" <> StringTools.replace(arg0, "\"", "\\\"") <> "\"", else: nil
  arg0
)
  end

  @doc "Function utf16_code_point_at"
  @spec utf16_code_point_at(String.t(), integer()) :: integer()
  def utf16_code_point_at(arg0, arg1) do
    (
  c = StringTools.fastCodeAt(arg0, arg1)
  if (c >= 55296 && c <= 56319), do: c = Bitwise.<<<(c - 55296, 10) ||| StringTools.fastCodeAt(arg0, arg1 + 1) &&& 1023 ||| 65536, else: nil
  c
)
  end

end
