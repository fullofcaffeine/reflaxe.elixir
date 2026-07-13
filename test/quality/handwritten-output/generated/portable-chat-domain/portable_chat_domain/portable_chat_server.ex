defmodule PortableChatDomain.PortableChatServer do
  def sample_lines() do
    history = PortableChatDomain.Transcript.empty()

    history =
      history
      |> PortableChatDomain.Transcript.add("Ada", " Hello from the BEAM side. ")
      |> PortableChatDomain.Transcript.add("Grace", "The same Haxe rules compiled to Elixir.")
      |> PortableChatDomain.Transcript.add("", "This message is rejected.")

    PortableChatDomain.Transcript.render(history)
  end

  def sample_summary() do
    Enum.join((fn -> sample_lines() end).(), " | ")
  end
end
