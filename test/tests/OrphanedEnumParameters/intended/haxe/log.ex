defmodule Log do
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
    (
          str = Std.string(v)
          if ((infos == nil)) do
          str
        end
          pstr = infos.file_name <> ":" <> to_string(infos.line_number)
          if ((infos.custom_params != nil)) do
          (
          g_counter = 0
          g_array = infos.custom_params
          Enum.each(, fn v2 -> 
      str = str <> ", " <> Std.string(v)
    end)
        )
        end
          pstr <> ": " <> str
        )
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
    (
          str = Log.format_output(v, infos)
          Sys.println(str)
        )
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
