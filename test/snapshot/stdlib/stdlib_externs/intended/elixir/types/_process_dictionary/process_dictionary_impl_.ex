defmodule ProcessDictionary_Impl_ do
  def _new(dict) do
    this1 = nil
    this1 = dict
    this1
  end
  def keys(this1) do
    result = []
    key = Map.keys(this1)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {key, :ok}, fn _, {acc_key, acc_state} -> nil end)
    result
  end
  def iterator(this1) do
    iter = this1.key_value_iterator()
    %{:has_next => fn -> iter.has_next() end, :next => fn ->
  kv = iter.next()
  %{:key => kv.key, :value => kv.value}
end}
  end
end