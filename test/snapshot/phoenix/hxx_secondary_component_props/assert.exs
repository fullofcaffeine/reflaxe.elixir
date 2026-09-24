# Pass dependency-only ebin directories. Do not load another app's generated modules.
Enum.each(System.argv(), &Code.prepend_path/1)

generated = Path.join(__DIR__, "out")

case Kernel.ParallelCompiler.compile(Path.wildcard(Path.join(generated, "**/*.ex"))) do
  {:ok, _modules, []} -> :ok
  other -> raise "Expected warning-free component compilation: #{inspect(other)}"
end

rendered =
  MyAppWeb.Main.render(%{__changed__: nil, js: struct(Phoenix.LiveView.JS)})
  |> Phoenix.HTML.Safe.to_iodata()
  |> IO.iodata_to_binary()

unless String.trim(rendered) == "<div><p>Hello</p></div>" do
  raise "Unexpected rendered component: #{inspect(rendered)}"
end

IO.puts("Secondary component rendered expected HTML")
