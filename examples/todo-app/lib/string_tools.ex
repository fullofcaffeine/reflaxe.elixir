defmodule StringTools do
  def isSpace(s, pos) do
    c = s.charCodeAt(pos)
    c > 8 && c < 14 || c == 32
  end
  def ltrim(s) do
    l = s.length
    r = 0
    (fn ->
      loop_0 = fn loop_0 ->
        if (r < l && StringTools.is_space(s, r)) do
          r + 1
          loop_0.(loop_0)
        else
          :ok
        end
      end
      loop_0.(loop_0)
    end).()
    if (r > 0), do: s.substr(r, l - r), else: s
  end
  def rtrim(s) do
    l = s.length
    r = 0
    (fn ->
      loop_1 = fn loop_1 ->
        if (r < l && StringTools.is_space(s, l - r - 1)) do
          r + 1
          loop_1.(loop_1)
        else
          :ok
        end
      end
      loop_1.(loop_1)
    end).()
    if (r > 0), do: s.substr(0, l - r), else: s
  end
  def trim(s) do
    StringTools.ltrim(StringTools.rtrim(s))
  end
  def hex(n, digits) do
    s = ""
    hex_chars = "0123456789ABCDEF"
    (fn ->
      loop_2 = fn loop_2 ->
        if (n > 0) do
          s = hexChars.charAt(n &&& 15) + s
      n = n + 4
          loop_2.(loop_2)
        else
          :ok
        end
      end
      loop_2.(loop_2)
    end).()
    if (digits != nil), do: (fn ->
  loop_3 = fn loop_3 ->
    if (s.length < digits) do
      s = "0" + s
      loop_3.(loop_3)
    else
      :ok
    end
  end
  loop_3.(loop_3)
end).()
    s
  end
end