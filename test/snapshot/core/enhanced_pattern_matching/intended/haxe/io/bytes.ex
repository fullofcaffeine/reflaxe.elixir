defmodule Bytes do
  import Bitwise
  defp new(length, b) do
    %{:length => length, :b => b}
  end
  def of_string(s, encoding) do
    a = Array.new()
    i = 0
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (i < s.length) do
  c = index = i + 1
s.cca(index)
  if (55296 <= c && c <= 56319) do
    c = c - 55232 <<< 10 ||| index = i + 1
s.cca(index) &&& 1023
  end
  if (c <= 127) do
    a.push(c)
  else
    if (c <= 2047) do
      a.push(192 ||| c >>> 6)
      a.push(128 ||| c &&& 63)
    else
      if (c <= 65535) do
        a.push(224 ||| c >>> 12)
        a.push(128 ||| c >>> 6 &&& 63)
        a.push(128 ||| c &&& 63)
      else
        a.push(240 ||| c >>> 18)
        a.push(128 ||| c >>> 12 &&& 63)
        a.push(128 ||| c >>> 6 &&& 63)
        a.push(128 ||| c &&& 63)
      end
    end
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
    Bytes.new(a.length, a)
  end
end