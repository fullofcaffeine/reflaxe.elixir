defmodule EReg do
  defstruct regex: nil, global: false
  def new(pattern, options) do
    opts = if Kernel.is_nil(options), do: "", else: options
    global = String.contains?(opts, "g")
    compile_opts = String.replace(opts, "g", "")
    %__MODULE__{regex: Regex.compile!(pattern, compile_opts), global: global}
  end
  def match(struct, s), do: Regex.match?(struct.regex, s)
  def replace(struct, s, by), do: Regex.replace(struct.regex, s, by, global: struct.global)
end
