# The inputs are built here, in Elixir, so the Haxe compiler cannot change them.
accent = <<0x301::utf8>>
flag = <<0x1F1E7::utf8, 0x1F1F7::utf8>>
family = <<0x1F468::utf8, 0x200D::utf8, 0x1F469::utf8, 0x200D::utf8, 0x1F467::utf8>>
jamo = <<0x1100::utf8, 0x1161::utf8>>

texts = [
  {"crlf-array", "[1,\r\n2]"},
  {"crlf-object", "{\r\n\"a\": 1\r\n}"},
  {"combining", "\"e" <> accent <> "\""},
  {"flag", "[\"" <> flag <> "\",true]"},
  {"family", "{\"k\":\"" <> family <> "\",\"z\":null}"},
  {"jamo", "[\"" <> jamo <> "\",1]"},
  {"plain", "[1, 2]"},
  {"empty", ""},
  {"bad", "[1,\r\n?]"}
]

searches = [
  {"crlf", "a\r\nb\r\nc", "\n"},
  {"flag", flag <> "x" <> flag <> "x", "x"},
  {"accent", "e" <> accent <> "e" <> accent, "e"},
  {"overlap", "aaa", "aa"},
  {"empty", "e" <> accent, ""},
  {"missing", flag, "x"}
]

# Same plain-text form as `Main.plain`, written natively.
plain = fn text ->
  for <<code::utf8 <- text>>, into: "" do
    if code < 32 or code > 126 or code == ?\\,
      do: "\\u{" <> Integer.to_string(code, 16) <> "}",
      else: <<code::utf8>>
  end
end

actual =
  Enum.flat_map(texts, fn {label, text} ->
    [
      "#{label} describe #{plain.(Main.describe(text))}",
      "#{label} slices #{plain.(Main.slices(text, 1, 2))}",
      "#{label} pieces #{plain.(Main.pieces(text))}",
      "#{label} outside #{plain.(Main.outside(text))}",
      "#{label} check #{plain.(Main.check(text))}"
    ]
  end) ++
    Enum.map(searches, fn {label, text, needle} -> "#{label} find #{plain.(Main.find(text, needle))}" end)

# `interpreter.txt` holds the output of the same program on the Haxe interpreter.
expected = __DIR__ |> Path.join("interpreter.txt") |> File.read!() |> String.split("\n", trim: true)

unless length(actual) == length(expected), do: raise("expected #{length(expected)} results, got #{length(actual)}")

failures = for {want, got} <- Enum.zip(expected, actual), want != got, do: "  interpreter: #{want}\n  BEAM:        #{got}"

unless failures == [], do: raise("String results differ from the Haxe interpreter:\n" <> Enum.join(failures, "\n"))

IO.puts("PASS: String operations count codepoints, as the Haxe interpreter does")
