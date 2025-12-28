defmodule Lambda do
  def array(it) do
    arr = []
    v = it.iterator.()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {arr}, fn _, {acc_arr} ->
      try do
        if (v.has_next.()) do
          v = v.next.()
          acc_arr = acc_arr ++ [v]
          {:cont, {acc_arr}}
        else
          {:halt, {acc_arr}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_arr}}
        :throw, :continue ->
          {:cont, {acc_arr}}
      end
    end)
    arr
  end
  def list(it) do
    arr = []
    v = it.iterator.()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {arr}, fn _, {acc_arr} ->
      try do
        if (v.has_next.()) do
          v = v.next.()
          acc_arr = acc_arr ++ [v]
          {:cont, {acc_arr}}
        else
          {:halt, {acc_arr}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_arr}}
        :throw, :continue ->
          {:cont, {acc_arr}}
      end
    end)
    arr
  end
  def concat(a, b) do
    arr = []
    v = a.iterator.()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {arr}, fn _, {acc_arr} ->
      try do
        if (v.has_next.()) do
          v = v.next.()
          acc_arr = acc_arr ++ [v]
          {:cont, {acc_arr}}
        else
          {:halt, {acc_arr}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_arr}}
        :throw, :continue ->
          {:cont, {acc_arr}}
      end
    end)
    v = b.iterator.()
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {arr}, fn _, {acc_arr} ->
      try do
        if (v.has_next.()) do
          v = v.next.()
          acc_arr = acc_arr ++ [v]
          {:cont, {acc_arr}}
        else
          {:halt, {acc_arr}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_arr}}
        :throw, :continue ->
          {:cont, {acc_arr}}
      end
    end)
    arr
  end
  def map(it, f) do
    Enum.map(it, f)
  end
  def filter(it, f) do
    Enum.filter(it, f)
  end
  def fold(it, f, first) do
    Enum.reduce(it, first, f)
  end
  def count(it, pred) do
    if (Kernel.is_nil(pred)) do
      Enum.count(it)
    else
      Enum.count(it, pred)
    end
  end
  def exists(it, f) do
    Enum.any?(it, f)
  end
  def foreach(it, f) do
    Enum.all?(it, f)
  end
  def find(it, f) do
    Enum.find(it, f)
  end
  def empty(it) do
    Enum.empty?(it)
  end
  def index_of(it, v) do
    result = Enum.find_index(it, fn x -> x == v end)
    if (Kernel.is_nil(result)), do: -1, else: result
  end
  def has(it, v) do
    Enum.member?(it, v)
  end
  def iter(it, f) do
    Enum.each(it, f)
  end
end
