defmodule ArrayIterator do
  defstruct array: [], current: 0, ref: nil
  def new(array), do: %__MODULE__{array: array, current: 0, ref: make_ref()}
  defp state_key(ref), do: {__MODULE__, ref}
  defp current_index(struct) do
    if Kernel.is_nil(struct.ref), do: struct.current, else: Process.get(state_key(struct.ref), struct.current)
  end
  def has_next(struct), do: current_index(struct) < length(struct.array)
  def next(struct) do
    i = current_index(struct)
    if not Kernel.is_nil(struct.ref), do: Process.put(state_key(struct.ref), i + 1)
    Enum.at(struct.array, i)
  end
end
