defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    i = 0
    (
      try do
        loop_fn = fn {i} ->
          if (i < 5) do
            try do
              # i incremented
          loop_fn.({i + 1})
            catch
              :break -> {i}
              :continue -> loop_fn.({i})
            end
          else
            {i}
          end
        end
        loop_fn.({i})
      catch
        :break -> {i}
      end
    )
    j = 0
    (
      loop_fn = fn {j} ->
        # j incremented
        if (j < 3), do: loop_fn.({j + 1}), else: {j + 1}
      end
      {j} = loop_fn.({j})
    )
    counter = 10
    (
      try do
        loop_fn = fn {counter} ->
          if (counter > 0) do
            try do
              # counter updated with - 2
          if (counter == 4), do: throw(:break), else: nil
          loop_fn.({counter - 2})
            catch
              :break -> {counter}
              :continue -> loop_fn.({counter})
            end
          else
            {counter}
          end
        end
        loop_fn.({counter})
      catch
        :break -> {counter}
      end
    )
  end

end
