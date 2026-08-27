defmodule Main do
  defp assert_true(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  defp test_encoding() do
    assert_true(
      (fn ->
         (case {:utf8} do
           {:utf8} -> true
           _ -> false
         end)
       end).(),
      "Encoding.UTF8 changed constructor"
    )
    assert_true(
      (fn ->
         (case {:raw_native} do
           {:raw_native} -> true
           _ -> false
         end)
       end).(),
      "Encoding.RawNative changed constructor"
    )
  end
  defp test_eof() do
    eof = Eof.new()
    assert_true(apply(Map.get(eof, :__reflaxe_class__) || Map.get(eof, :__struct__), :to_string, [eof]) == "Eof", "Eof.toString() changed")
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: eof]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} when is_struct(error, Eof) or is_map(error) and is_map_key(error, :__reflaxe_class__) and :erlang.map_get(:__reflaxe_class__, error) == Eof ->
            assert_true(apply(Map.get(error, :__reflaxe_class__) || Map.get(error, :__struct__), :to_string, [error]) == "Eof", "Eof catch changed value")
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp test_error() do
    simple_errors = [{:blocked}, {:overflow}, {:outside_bounds}]
    matched = 0
    _g = 0
    matched = Enum.reduce(simple_errors, matched, fn error, matched_acc ->
      (case error do
        {:blocked} ->
          matched_acc = matched_acc + 1
          matched_acc
        {:overflow} ->
          matched_acc = matched_acc + 1
          matched_acc
        {:outside_bounds} ->
          matched_acc = matched_acc + 1
          matched_acc
        {:custom, _e} -> matched_acc
      end)
    end)
    assert_true(matched == 3, "Error constructors changed")
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: {:custom, "io failure"}]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} when is_tuple(error) and elem(error, 0) in [:overflow, :outside_bounds, :custom, :blocked] ->
            (case error do
              {:custom, message} ->
                assert_true(Reflaxe.Elixir.HaxeFloat.eq(message, "io failure"), "Error.Custom payload changed")
              _ ->
                assert_true(false, "Error.Custom changed constructor")
            end)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  defp test_mime_and_scheme() do
    mime = "application/json"
    custom_mime = "application/vnd.example+json"
    custom_mime_text = custom_mime
    scheme = "https"
    custom_scheme = "web+demo"
    custom_scheme_text = custom_scheme
    assert_true(mime == "application/json", "Mime.ApplicationJson changed")
    assert_true(custom_mime_text == "application/vnd.example+json", "Custom Mime conversion changed")
    assert_true(scheme == "https", "Scheme.Https changed")
    assert_true(custom_scheme_text == "web+demo", "Custom Scheme conversion changed")
  end
  def main() do
    test_encoding()
    test_eof()
    test_error()
    test_mime_and_scheme()
  end
end
