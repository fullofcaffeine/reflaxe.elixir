defmodule Log do
  use Bitwise
  @moduledoc """
  Log module generated from Haxe
  
  
	Log primarily provides the `trace()` method, which is invoked upon a call to
	`trace()` in Haxe code.

  """

  # Static functions
  @doc """
    Format the output of `trace` before printing it.

  """
  @spec format_output(term(), PosInfos.t()) :: String.t()
  def format_output(v, infos) do
    str = Std.string(v)
    if (infos == nil), do: str, else: nil
    pstr = infos.file_name <> ":" <> Integer.to_string(infos.line_number)
    if (infos.custom_params != nil) do
      _g = 0
      _g = infos.custom_params
      Enum.map(_g, fn item -> item end)
    end
    pstr <> ": " <> str
  end

  @doc """
    Outputs `v` in a platform-dependent way.

    The second parameter `infos` is injected by the compiler and contains
    information about the position where the `trace()` call was made.

    This method can be rebound to a custom function:

    var oldTrace = haxe.Log.trace; // store old function
    haxe.Log.trace = function(v, ?infos) {
    // handle trace
    }
    ...
    haxe.Log.trace = oldTrace;

    If it is bound to null, subsequent calls to `trace()` will cause an
    exception.
  """
  @spec trace(term(), Null.t()) :: nil
  def trace(v, infos) do
    str = Log.formatOutput(v, infos)
    Sys.println(str)
  end

end
