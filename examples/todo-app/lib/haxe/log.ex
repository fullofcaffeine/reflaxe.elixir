defmodule Log do
  @moduledoc """
    Log module generated from Haxe

      Log primarily provides the `trace()` method, which is invoked upon a call to
      `trace()` in Haxe code.
  """

  # Static functions
  @doc "Generated from Haxe formatOutput"
  def format_output(v, infos) do
    str = :Std.string(v)
    if (infos == nil) do
      str
    end
    pstr = infos.fileName + ":" + infos.lineNumber
    if (infos.customParams != nil) do
      _g = 0
      _g_1 = infos.customParams
      loop_1()
    end
    pstr + ": " + str
  end

  @doc "Generated from Haxe trace"
  def trace(v, infos \\ nil) do
    str = :Log.formatOutput(v, infos)
    :Sys.println(str)
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
