# Independent native expectations for authored Haxe catch behavior.
checks = [
  {Main.catches_string(), true},
  {Main.message(false), "expected"},
  {Main.message(true), "object"},
  {Main.ordered(false), "string:expected"},
  {Main.ordered(true), "base:object"},
  {Main.derived_message(), "derived"}
]
for {actual, expected} <- checks do
  unless actual == expected, do: raise("Expected #{inspect(expected)}, got #{inspect(actual)}")
end
Main.main()

original = %Reflaxe.Exception{
  message: "existing",
  previous: %Reflaxe.Exception{message: "cause"},
  native: {:original, 7},
  stack: [{:FilePos, nil, "source.hx", 12, nil}]
}
preserved = Main.caught_object(fn -> raise Reflaxe.Elixir.HaxeThrow, value: original end)
unless preserved === original, do: raise("Base catch changed the existing exception object")
normalized = Main.caught_object(fn -> raise Reflaxe.Elixir.HaxeThrow, value: "text" end)
unless normalized.message == "text" and normalized.native == "text" and is_list(normalized.stack),
  do: raise("Base catch lost the thrown value or stack representation")

for foreign <- [%{message: "looks like an exception", stack: []}, %ArgumentError{message: "native"}] do
  wrapped = Main.caught_object(fn -> raise Reflaxe.Elixir.HaxeThrow, value: foreign end)
  unless is_struct(wrapped, Reflaxe.Exception) and wrapped.native === foreign,
    do: raise("A foreign value bypassed Haxe exception normalization")
end

for value <- ["text", %Reflaxe.Exception{message: "existing"}] do
  action = fn -> raise Reflaxe.Elixir.HaxeThrow, value: value end
  expected = if is_binary(value), do: value, else: "existing"
  unless Main.aliased(action) == expected, do: raise("Alias changed exception normalization")
end
unless Main.number_only(fn -> raise Reflaxe.Elixir.HaxeThrow, value: 42 end) == 42,
  do: raise("Typed number catch changed")
unmatched = try do
  Main.number_only(fn -> raise Reflaxe.Elixir.HaxeThrow, value: "unmatched" end)
  :not_rethrown
rescue
  error in Reflaxe.Elixir.HaxeThrow -> error.value
end
unless unmatched == "unmatched", do: raise("Unmatched thrown value was changed or swallowed")
