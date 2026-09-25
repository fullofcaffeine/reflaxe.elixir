# Native bootstrap: @:controller emits the host's `use ProbeWeb, :controller`.
# Haxe cannot export an Elixir macro. This supplies only that macro, with no
# runtime behavior. Main's Haxe assertions test value preservation; they do not
# claim Phoenix integration. Remove this when the fixture uses a real host.
defmodule ProbeWeb do
  defmacro __using__(:controller), do: quote(do: nil)
end
