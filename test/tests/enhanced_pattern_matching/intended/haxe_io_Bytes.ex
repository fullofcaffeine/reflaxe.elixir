defmodule Bytes do
  @moduledoc "Bytes module generated from Haxe"

  # Static functions
  @doc """
    Returns the `Bytes` representation of the given `String`, using the
    specified encoding (UTF-8 by default).
  """
  @spec of_string(String.t(), Null.t()) :: Bytes.t()
  def of_string(s, encoding) do
    a = Array.new()
    i = 0
    (
      try do
        loop_fn = fn {c} ->
          if (i < String.length(s)) do
            try do
              c = StringTools.fastCodeAt(s, i = i + 1)
          if (55296 <= c && c <= 56319), do: c = Bitwise.<<<(c - 55232, 10) ||| StringTools.fastCodeAt(s, i = i + 1) &&& 1023, else: nil
          if (c <= 127) do
      a ++ [c]
    else
      if (c <= 2047) do
        a ++ [192 ||| Bitwise.>>>(c, 6)]
        a ++ [128 ||| c &&& 63]
      else
        if (c <= 65535) do
          a ++ [224 ||| Bitwise.>>>(c, 12)]
          a ++ [128 ||| Bitwise.>>>(c, 6) &&& 63]
          a ++ [128 ||| c &&& 63]
        else
          a ++ [240 ||| Bitwise.>>>(c, 18)]
          a ++ [128 ||| Bitwise.>>>(c, 12) &&& 63]
          a ++ [128 ||| Bitwise.>>>(c, 6) &&& 63]
          a ++ [128 ||| c &&& 63]
        end
      end
    end
          loop_fn.({c})
            catch
              :break -> {c}
              :continue -> loop_fn.({c})
            end
          else
            {c}
          end
        end
        loop_fn.({c})
      catch
        :break -> {c}
      end
    )
    Haxe.Io.Bytes.new(length(a), a)
  end

end
