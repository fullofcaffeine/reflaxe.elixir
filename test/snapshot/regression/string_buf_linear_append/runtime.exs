# The inputs are built here, in Elixir, so the Haxe compiler cannot change them.
accent = <<0x301::utf8>>
flag = <<0x1F1E7::utf8, 0x1F1F7::utf8>>
family = <<0x1F468::utf8, 0x200D::utf8, 0x1F469::utf8, 0x200D::utf8, 0x1F467::utf8>>

texts = [
  {"crlf", "a\r\nb\r\n"},
  {"combining", "e" <> accent <> "xe" <> accent},
  {"flag", flag <> "x" <> flag},
  {"family", "k" <> family <> "z" <> <<0x1F600::utf8>>},
  {"plain", "abcd"}
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
    last = text |> String.to_charlist() |> List.last()

    [
      "#{label} subs #{plain.(Main.subs(text))}",
      "#{label} copy #{plain.(Main.copy(text))}",
      "#{label} kinds #{plain.(Main.kinds(text, last))}"
    ]
  end) ++
    [
      "crlf afterSearch #{plain.(Main.after_search("a\r\nbc", "b"))}",
      "flag afterSearch #{plain.(Main.after_search(flag <> "bc", "b"))}",
      "empty empty #{plain.(Main.empty())}",
      "small build #{plain.(Main.build(3))}"
    ]

# `interpreter.txt` holds the output of the same program on the Haxe interpreter.
expected = __DIR__ |> Path.join("interpreter.txt") |> File.read!() |> String.split("\n", trim: true)

unless length(actual) == length(expected), do: raise("expected #{length(expected)} results, got #{length(actual)}")

failures = for {want, got} <- Enum.zip(expected, actual), want != got, do: "  interpreter: #{want}\n  BEAM:        #{got}"

unless failures == [], do: raise("StringBuf results differ from the Haxe interpreter:\n" <> Enum.join(failures, "\n"))

IO.puts("PASS: StringBuf results equal the Haxe interpreter")

# 400,000 `addChar` plus 400,000 `add` calls build 800 KB. The expected text is
# built natively. `copy` reads 200 KB with one `addSub` for each character.
count = 400_000
built = for index <- 0..(count - 1), into: "", do: <<?a + rem(index, 26), ?->>
source = String.duplicate("abcdefghij", 20_000)
budget_ms = 3_000

run = fn name, call, expected ->
  {micros, actual} = :timer.tc(call)
  unless actual == expected, do: raise("#{name}: wrong result (#{byte_size(actual)} bytes)")
  IO.puts("#{name}: #{div(micros, 1000)} ms")
  div(micros, 1000)
end

total_ms =
  run.("build 800 KB", fn -> Main.build(count) end, built) +
    run.("copy 200 KB with addSub", fn -> Main.copy(source) end, source)

# Before the fix each append copied the whole buffer: 40 KB took 3.9 s.
unless total_ms < budget_ms, do: raise("StringBuf loops took #{total_ms} ms, budget is #{budget_ms} ms")

IO.puts("PASS: StringBuf built 1 MB in #{total_ms} ms (budget #{budget_ms} ms)")
