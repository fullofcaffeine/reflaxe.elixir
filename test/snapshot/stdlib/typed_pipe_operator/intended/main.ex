defmodule Main do
  def from_imperative(params) do
    raw = Map.get(params, "resource_id")
    text = PhoenixHx.Params.string_from_term(raw)
    _ = ResourceIds.from_param(text)
  end
  def from_nested(params) do
    ResourceIds.from_param(PhoenixHx.Params.string_from_term(Map.get(params, "resource_id")))
  end
  def from_explicit_pipe(params) do
    value = params
    value = Map.get(value, "resource_id")
    value = PhoenixHx.Params.string_from_term(value)
    value = ResourceIds.from_param(value)
    value = ResourceIds.to_display(value)
    value
  end
  def from_extension_pipe(params) do
    value = params
    value = Map.get(value, "resource_id")
    value = PhoenixHx.Params.string_from_term(value)
    value = ResourceIds.from_param(value)
    value
  end
  def main() do
    params = %{"resource_id" => "42"}
    summary = [ResourceIds.to_display(from_imperative(params)), ResourceIds.to_display(from_nested(params)), from_explicit_pipe(params), ResourceIds.to_display(from_extension_pipe(params))]
    IO.inspect(summary)
  end
end
