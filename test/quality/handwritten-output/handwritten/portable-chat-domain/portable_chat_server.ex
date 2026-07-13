defmodule HandwrittenCorpus.PortableChatDomain.PortableChatServer do
  alias HandwrittenCorpus.PortableChatDomain.Transcript

  def sample_lines do
    Transcript.empty()
    |> Transcript.add("Ada", " Hello from the BEAM side. ")
    |> Transcript.add("Grace", "The same Haxe rules compiled to Elixir.")
    |> Transcript.add("", "This message is rejected.")
    |> Transcript.render()
  end

  def sample_summary, do: Enum.join(sample_lines(), " | ")
end
