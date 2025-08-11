defmodule Log do
  @moduledoc """
  Log module generated from Haxe
  
  
	Log primarily provides the `trace()` method, which is invoked upon a call to
	`trace()` in Haxe code.

  """

  # Static functions
  @doc "
		Format the output of `trace` before printing it.
	"
  @spec format_output(TDynamic(null).t(), TType(haxe.PosInfos,[]).t()) :: TInst(String,[]).t()
  def format_output(arg0, arg1) do
    # TODO: Implement function body
    nil
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
  @spec trace(TDynamic(null).t(), TAbstract(Null,[TType(haxe.PosInfos,[])]).t()) :: TAbstract(Void,[]).t()
  def trace(arg0, arg1) do
    # TODO: Implement function body
    nil
  end

end
