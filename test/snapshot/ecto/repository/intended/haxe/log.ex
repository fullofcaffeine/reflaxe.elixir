defmodule Log do
  def format_output(v, infos \\ nil) do
    str = Std.string(v)

    if infos == nil do
      str
    else
      pstr = "#{infos.file_name}:#{infos.line_number}"

      # Handle custom parameters if present
      pstr = if Map.get(infos, :custom_params) != nil do
        infos.custom_params
        |> Enum.reduce(pstr, fn param, acc ->
          "#{acc}:#{param}"
        end)
      else
        pstr
      end

      "#{pstr}: #{str}"
    end
  end

  def trace(v, infos \\ nil) do
    str = format_output(v, infos)
    IO.puts(str)
  end

  def clear() do
    # ANSI escape code to clear console
    IO.write("\e[2J\e[H")
  end
end