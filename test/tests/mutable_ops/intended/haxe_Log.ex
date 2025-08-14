defmodule Log do
  use Bitwise
  @moduledoc """
  Log module generated from Haxe
  
  
	Log primarily provides the `trace()` method, which is invoked upon a call to
	`trace()` in Haxe code.

  """

  # Static functions
  @doc "
		Format the output of `trace` before printing it.
	"
  @spec format_output(term(), PosInfos.t()) :: String.t()
  def format_output(arg0, arg1) do
    str = Std.string(arg0)
if (arg1 == nil), do: str, else: nil
pstr = arg1.file_name <> ":" <> Integer.to_string(arg1.line_number)
if (arg1.custom_params != nil) do
  _g = 0
  _g1 = arg1.custom_params
  Enum.map(_g1, fn str -> str end)
end
pstr <> ": " <> str
  end

  @doc "
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
	"
  @spec trace(term(), Null.t()) :: nil
  def trace(arg0, arg1) do
    str = Log.formatOutput(arg0, arg1)
Sys.println(str)
  end

end
