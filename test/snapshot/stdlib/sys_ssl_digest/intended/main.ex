defmodule Main do
  defp assert_that(condition, message) do
    if (not condition) do
      raise Reflaxe.Elixir.HaxeThrow, [value: message]
    end
  end
  defp reject_unsupported_sign() do
    try do
      _ = Digest.sign(Bytes.of_string("abc", {:utf8}), nil, "SHA256")
      raise Reflaxe.Elixir.HaxeThrow, [value: "Digest.sign should fail explicitly on the Elixir target"]
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
                assert_that(Reflaxe.Elixir.HaxeFloat.neq(message, ""), "Digest.sign should explain unsupported status")
              _ -> raise Reflaxe.Elixir.HaxeThrow, [value: "Digest.sign should raise Error.Custom"]
            end)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def main() do
    digest = Digest.make(Bytes.of_string("abc", {:utf8}), "SHA256")
    _ = assert_that(apply(Map.get(digest, :__reflaxe_class__) || Map.get(digest, :__struct__), :to_hex, [digest]) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "SHA256 digest should match :crypto.hash output")
    _ = reject_unsupported_sign()
  end
end
