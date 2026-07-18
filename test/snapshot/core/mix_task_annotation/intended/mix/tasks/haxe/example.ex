defmodule Mix.Tasks.Haxe.Example do
  @moduledoc """
  Reports compiler status from a Haxe-authored Mix task.
  """

  use Mix.Task

  @shortdoc "Reports compiler status"
  @requirements ["app.config"]

  @impl Mix.Task
  def run(args) do
    Mix.shell().info("Running Haxe-authored Mix task")
    length(args)
  end
  def enabled(value) do
    value == true
  end
  def greeting(name \\ "world") do
    name
  end
  defp local_greeting(name) do
    name
  end
  def default_greeting() do
    "#{greeting("world")}#{local_greeting("world")}"
  end
end
