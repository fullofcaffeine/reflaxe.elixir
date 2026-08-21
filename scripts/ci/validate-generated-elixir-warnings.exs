case System.argv() do
  [beam_dir | generated_files] when generated_files != [] ->
    case Kernel.ParallelCompiler.compile_to_path(generated_files, beam_dir) do
      {:ok, _modules, []} ->
        :ok

      {:ok, _modules, warnings} ->
        Enum.each(warnings, &Kernel.ParallelCompiler.print_warning/1)
        IO.puts(:stderr, "generated warning validation failed: #{length(warnings)} warning(s)")
        System.halt(1)

      {:error, errors, warnings} ->
        Enum.each(warnings, &Kernel.ParallelCompiler.print_warning/1)

        IO.puts(
          :stderr,
          "generated warning validation failed: #{length(errors)} error(s), #{length(warnings)} warning(s)"
        )

        System.halt(1)
    end

  _ ->
    IO.puts(
      :stderr,
      "Usage: validate-generated-elixir-warnings.exs <beam-dir> <generated-files...>"
    )

    System.halt(2)
end
