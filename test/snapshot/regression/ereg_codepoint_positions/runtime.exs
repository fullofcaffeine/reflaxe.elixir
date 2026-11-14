# The inputs are built here, in Elixir, so the Haxe compiler cannot change them.
accent = <<0x301::utf8>>
flag = <<0x1F1E7::utf8, 0x1F1F7::utf8>>

# {label, text, pattern, compare the matchSub range with the interpreter}
cases = [
  {"crlf", "a\r\nbc\r\nbd", "b", true},
  {"accent", "e" <> accent <> "xe" <> accent <> "xy", "x", false},
  {"flag", flag <> "b" <> flag <> "bc", "b", false},
  {"plain", "abcabc", "b", true},
  {"wide", "a\r\n" <> flag <> "c" <> flag, flag, false},
  {"missing", "a\r\nc", "b", true}
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
  Enum.flat_map(cases, fn {label, text, pattern, ranges} ->
    ["#{label} found #{plain.(Main.found(text, pattern))}"] ++
      if(ranges, do: ["#{label} foundIn #{plain.(Main.found_in(text, pattern, 2, 3))}"], else: []) ++
      [
        "#{label} replaced #{plain.(Main.replaced(text, pattern, "_"))}",
        "#{label} mapped #{plain.(Main.mapped(text, pattern))}",
        "#{label} pieces #{plain.(Main.pieces(text, pattern))}"
      ]
  end)

# `interpreter.txt` holds the output of the same program on the Haxe interpreter.
expected = __DIR__ |> Path.join("interpreter.txt") |> File.read!() |> String.split("\n", trim: true)

unless length(actual) == length(expected), do: raise("expected #{length(expected)} results, got #{length(actual)}")

failures = for {want, got} <- Enum.zip(expected, actual), want != got, do: "  interpreter: #{want}\n  BEAM:        #{got}"

unless failures == [], do: raise("EReg results differ from the Haxe interpreter:\n" <> Enum.join(failures, "\n"))

# Not compared with the interpreter, which reads this range in bytes: on BEAM
# the range is codepoints 2..4, like every other String position.
range_cases = [
  {"flag", flag <> "b" <> flag <> "bc", "b", "2,1|b"},
  {"wide", "a\r\n" <> flag <> "c" <> flag, flag, "3,2|" <> flag},
  {"accent", "e" <> accent <> "xe" <> accent <> "xy", "x", "2,1|x"}
]

for {label, text, pattern, want} <- range_cases do
  got = Main.found_in(text, pattern, 2, 3)
  unless got == want, do: raise("#{label} matchSub range: expected #{inspect(want)}, got #{inspect(got)}")
end

IO.puts("PASS: EReg positions count codepoints, as the Haxe interpreter does")
