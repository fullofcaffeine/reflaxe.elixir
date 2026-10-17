defmodule Main do
  def main() do

  end
  def copy(envelope, observe) do
    pending = envelope.pending
    if (Kernel.is_nil(pending)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "missing"]
    end
    observe.(pending)
    %{identity: pending.identity, sequence: pending.sequence}
  end
end
