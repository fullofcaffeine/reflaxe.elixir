defmodule Mix.Tasks.Markers.Count do
  @moduledoc """
  Counts its arguments.

  Usage: mix markers.count \#{name}

  This comment becomes an Elixir heredoc string, where `\#{name}` would run as
  code. It is documentation text, so the compiler must escape it.
  """

  use Mix.Task

  @shortdoc "Counts \#{name} arguments"

  @impl Mix.Task
  def run(args) do
    length(args)
  end
end
