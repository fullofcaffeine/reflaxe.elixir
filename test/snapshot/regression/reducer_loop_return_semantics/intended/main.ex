defmodule Main do
  def main() do
    ok = sum_until_negative([1, 2, 3])
    stopped = sum_until_negative([1, -2, 3])
    if (ok != 6 or stopped != -1) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "An array-loop return changed its result."]
    end
    if (return_from_catch() != 7) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "A catch return did not exit its enclosing function."]
    end
    if (try_and_catch(3, 1, 2) != 20 or try_and_catch(3, 2, 2) != 200 or try_and_catch(3, 1, 9) != -3 or try_and_catch(0, 1, 2) != 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Try/catch return or fallthrough lost its loop state."]
    end
    if (not exact_fields([], [], []) or not exact_fields(["id", "label"], ["id"], ["label"])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Valid fields were rejected."]
    end
    if (exact_fields([], ["id"], []) or exact_fields(["unknown", "id"], ["id"], []) or exact_fields(["id", "unknown", "label"], ["id"], ["label"]) or exact_fields(["id", "unknown"], ["id"], [])) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "A sequential validation loop lost its rejection return."]
    end
    if (not Kernel.is_nil(string_keys([{:other, "bad"}, {:text, "id"}])) or not Kernel.is_nil(string_keys([{:text, "id"}, {:other, "bad"}, {:text, "label"}])) or not Kernel.is_nil(string_keys([{:text, "id"}, {:other, "bad"}]))) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "An ignored enum payload lost its rejection return."]
    end
    empty = string_keys([])
    valid = string_keys([{:text, "id"}, {:text, "label"}])
    if (Kernel.is_nil(empty) or length(empty) != 0 or Kernel.is_nil(valid) or Enum.join(valid, ",") != "id,label") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Enum fallthrough lost its accumulated values."]
    end
    if (three_loops([1], [2], [3]) != 36 or three_loops([], [], []) != 30 or three_loops([-1], [2], [3]) != -100 or three_loops([1], [-2], [3]) != -211 or three_loops([1], [2], [-3]) != -333) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Sequential returns lost intervening effects or accumulator state."]
    end
  end
  def exact_fields(keys, required, optional) do
    (case Enum.reduce_while(required, :__reflaxe_no_return__, fn name, _ ->
      if (((case Enum.find_index(keys, fn item -> item == name end) do
        nil -> -1
        index -> index
      end) < 0)), do: {:halt, {:__reflaxe_return__, false}}, else: {:cont, :__reflaxe_no_return__}
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      _ ->
        (case Enum.reduce_while(keys, :__reflaxe_no_return__, fn name, _ ->
          if (((case Enum.find_index(required, fn item -> item == name end) do
            nil -> -1
            index -> index
          end) < 0 and (case Enum.find_index(optional, fn item -> item == name end) do
            nil -> -1
            index -> index
          end) < 0)), do: {:halt, {:__reflaxe_return__, false}}, else: {:cont, :__reflaxe_no_return__}
        end) do
          {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
          _ -> true
        end)
    end)
  end
  def string_keys(keys) do
    names = []
    (case Enum.reduce_while(keys, {:__reflaxe_continue__, names}, fn key, {:__reflaxe_continue__, names_acc} ->
      (case (case key do
        {:text, name} ->
          names_acc = names_acc ++ [name]
          {:cont, {:__reflaxe_continue__, names_acc}}
        {:other, _reason} -> {:halt, {:__reflaxe_return__, nil}}
      end) do
        {:halt, reflaxe_halt_payload} -> {:halt, reflaxe_halt_payload}
        {:cont, {:__reflaxe_continue__, names_acc}} -> {:cont, {:__reflaxe_continue__, names_acc}}
      end)
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, reflaxe_continue_names} ->
        names = reflaxe_continue_names
        names
    end)
  end
  def three_loops(first, second, third) do
    total = 0
    (case Enum.reduce_while(first, {:__reflaxe_continue__, total}, fn value, {:__reflaxe_continue__, total_acc} ->
      (case (if (value < 0), do: {:halt, {:__reflaxe_return__, (-100 - total_acc)}}, else: {:cont, {:__reflaxe_continue__, total_acc}}) do
        {:halt, reflaxe_halt_payload} -> {:halt, reflaxe_halt_payload}
        {:cont, {:__reflaxe_continue__, total_acc}} ->
          total_acc = total_acc + value
          {:cont, {:__reflaxe_continue__, total_acc}}
      end)
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, reflaxe_continue_total} ->
        total = reflaxe_continue_total
        total = total + 10
        (case Enum.reduce_while(second, {:__reflaxe_continue__, total}, fn value, {:__reflaxe_continue__, total_acc} ->
          (case (if (value < 0), do: {:halt, {:__reflaxe_return__, (-200 - total_acc)}}, else: {:cont, {:__reflaxe_continue__, total_acc}}) do
            {:halt, reflaxe_halt_payload} -> {:halt, reflaxe_halt_payload}
            {:cont, {:__reflaxe_continue__, total_acc}} ->
              total_acc = total_acc + value
              {:cont, {:__reflaxe_continue__, total_acc}}
          end)
        end) do
          {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
          {:__reflaxe_continue__, reflaxe_continue_total} ->
            total = reflaxe_continue_total
            total = total + 20
            (case Enum.reduce_while(third, {:__reflaxe_continue__, total}, fn value, {:__reflaxe_continue__, total_acc} ->
              (case (if (value < 0), do: {:halt, {:__reflaxe_return__, (-300 - total_acc)}}, else: {:cont, {:__reflaxe_continue__, total_acc}}) do
                {:halt, reflaxe_halt_payload} -> {:halt, reflaxe_halt_payload}
                {:cont, {:__reflaxe_continue__, total_acc}} ->
                  total_acc = total_acc + value
                  {:cont, {:__reflaxe_continue__, total_acc}}
              end)
            end) do
              {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
              {:__reflaxe_continue__, reflaxe_continue_total} ->
                total = reflaxe_continue_total
                total
            end)
        end)
    end)
  end
  def return_from_catch() do
    attempt = 0
    (case Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {:__reflaxe_continue__, {attempt}}, fn _, {:__reflaxe_continue__, {acc_attempt}} ->
      try do
        if (acc_attempt < 2) do
          _ = acc_attempt + 1
          try do
            raise Reflaxe.Elixir.HaxeThrow, [value: "stop"]
          rescue
            haxe_exception ->
              Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
              (case {(case haxe_exception do
                %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
                _ -> haxe_exception
              end), haxe_exception} do
                {haxe_catch_value, _} when is_binary(haxe_catch_value) -> {:halt, {:__reflaxe_return__, 7}}
                _ ->
                  reraise(haxe_exception, __STACKTRACE__)
              end)
          end
        else
          {:halt, {:__reflaxe_continue__, {acc_attempt}}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, {:__reflaxe_continue__, break_state}}
        :throw, {:continue, continue_state} ->
          {:cont, {:__reflaxe_continue__, continue_state}}
        :throw, :break ->
          {:halt, {:__reflaxe_continue__, {acc_attempt}}}
        :throw, :continue ->
          {:cont, {:__reflaxe_continue__, {acc_attempt}}}
      end
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {reflaxe_continue_attempt}} ->
        {_attempt} = {reflaxe_continue_attempt}
        -1
    end)
  end
  def try_and_catch(limit, fail_at, return_at) do
    attempt = 0
    (case Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {:__reflaxe_continue__, {attempt}}, fn _, {:__reflaxe_continue__, {acc_attempt}} ->
      try do
        if (acc_attempt < limit) do
          acc_attempt = acc_attempt + 1
          try do
            if (acc_attempt == fail_at) do
              raise Reflaxe.Elixir.HaxeThrow, [value: "stop"]
            end
            if (acc_attempt == return_at), do: {:halt, {:__reflaxe_return__, acc_attempt * 10}}, else: {:cont, {:__reflaxe_continue__, {acc_attempt}}}
          rescue
            haxe_exception ->
              Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
              (case {(case haxe_exception do
                %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
                _ -> haxe_exception
              end), haxe_exception} do
                {haxe_catch_value, _} when is_binary(haxe_catch_value) ->
                  if (acc_attempt == return_at), do: {:halt, {:__reflaxe_return__, acc_attempt * 100}}, else: {:cont, {:__reflaxe_continue__, {acc_attempt}}}
                _ ->
                  reraise(haxe_exception, __STACKTRACE__)
              end)
          end
        else
          {:halt, {:__reflaxe_continue__, {acc_attempt}}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, {:__reflaxe_continue__, break_state}}
        :throw, {:continue, continue_state} ->
          {:cont, {:__reflaxe_continue__, continue_state}}
        :throw, :break ->
          {:halt, {:__reflaxe_continue__, {acc_attempt}}}
        :throw, :continue ->
          {:cont, {:__reflaxe_continue__, {acc_attempt}}}
      end
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {reflaxe_continue_attempt}} ->
        {attempt} = {reflaxe_continue_attempt}
        -attempt
    end)
  end
  defp sum_until_negative(values) do
    total = 0
    (case Enum.reduce_while(values, {:__reflaxe_continue__, total}, fn value, {:__reflaxe_continue__, total_acc} ->
      (case (if (value < 0), do: {:halt, {:__reflaxe_return__, -1}}, else: {:cont, {:__reflaxe_continue__, total_acc}}) do
        {:halt, reflaxe_halt_payload} -> {:halt, reflaxe_halt_payload}
        {:cont, {:__reflaxe_continue__, total_acc}} ->
          total_acc = total_acc + value
          {:cont, {:__reflaxe_continue__, total_acc}}
      end)
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, reflaxe_continue_total} ->
        total = reflaxe_continue_total
        total
    end)
  end
end
