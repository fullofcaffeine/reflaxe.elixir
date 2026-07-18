defmodule Main do
  defp apply_to(input, callback) do
    callback.(input)
  end
  defp apply_result_to(input, callback) do
    callback.(input)
  end
  defp apply_string(callback) do
    callback.()
  end
  defp assert_equals(label, expected, actual) do
    if (expected != actual) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "" <> label <> ": expected " <> Reflaxe.Elixir.HaxeFloat.to_string(expected) <> ", got " <> Reflaxe.Elixir.HaxeFloat.to_string(actual)]
    end
  end
  defp verify(result) do
    (case result do
      {:ok, payload} ->
        assert_equals("identity callback", 7, apply_to(7, fn value -> value end))
        assert_equals("arithmetic callback", 12, apply_to(7, fn value -> value + 5 end))
        assert_equals("outer capture", 10, apply_to(7, fn _ignored -> payload end))
        assert_equals("mixed local and outer capture", 17, apply_to(7, fn value -> value + payload end))
        assert_equals("parameter shadows outer payload", 8, apply_to(7, fn payload -> payload + 1 end))
        assert_equals("nested parameter shadowing", 9, apply_to(7, fn value -> apply_to(value, fn value -> value + 2 end) end))
        (case apply_result_to(7, fn value -> {:ok, value} end) do
          {:ok, callback_value} ->
            assert_equals("tuple-returning callback", 7, callback_value)
          {:error, callback_error} -> raise Reflaxe.Elixir.HaxeThrow, [value: "unexpected callback error: " <> callback_error]
        end)
      {:error, message} -> raise Reflaxe.Elixir.HaxeThrow, [value: "unexpected error: " <> message]
    end)
  end
  defp verify_object_capture(result) do
    (case result do
      {:ok, payload} ->
        assert_equals("outer object capture", 10, apply_to(7, fn _ignored -> payload.amount end))
      {:error, message} -> raise Reflaxe.Elixir.HaxeThrow, [value: "unexpected object error: " <> message]
    end)
  end
  defp verify_suffix_parameter_does_not_capture_local(package_root) do
    root = "local-root"
    captured = apply_string(fn -> root end)
    if (captured != root) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "closure captured " <> captured <> " instead of " <> root <> " from " <> package_root]
    end
  end
  def main() do
    verify({:ok, 10})
    verify_object_capture({:ok, %{amount: 10}})
    verify_suffix_parameter_does_not_capture_local("package-root")
  end
end
