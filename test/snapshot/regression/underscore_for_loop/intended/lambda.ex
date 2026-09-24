defmodule Lambda do
  def array(it) do
    arr = []
    v = (case it do
      reflaxe_structural_receiver_node_0 ->
        (case Map.fetch(reflaxe_structural_receiver_node_0, :iterator) do
          {:ok, reflaxe_structural_callback_node_0} ->
            reflaxe_structural_callback_node_0.()
          :error ->
            apply(Map.get(reflaxe_structural_receiver_node_0, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_0, :__struct__), :iterator, [reflaxe_structural_receiver_node_0])
        end)
    end)
    {arr} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {arr}, fn _, {acc_arr} ->
      try do
        if ((case v do
        reflaxe_structural_receiver_node_1 ->
          (case Map.fetch(reflaxe_structural_receiver_node_1, :has_next) do
            {:ok, reflaxe_structural_callback_node_1} ->
              reflaxe_structural_callback_node_1.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_1, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_1, :__struct__), :has_next, [reflaxe_structural_receiver_node_1])
          end)
      end)) do
          v = (case v do
            reflaxe_structural_receiver_node_2 ->
              (case Map.fetch(reflaxe_structural_receiver_node_2, :next) do
                {:ok, reflaxe_structural_callback_node_2} ->
                  reflaxe_structural_callback_node_2.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_2, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_2, :__struct__), :next, [reflaxe_structural_receiver_node_2])
              end)
          end)
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
    v = (case it do
      reflaxe_structural_receiver_node_3 ->
        (case Map.fetch(reflaxe_structural_receiver_node_3, :iterator) do
          {:ok, reflaxe_structural_callback_node_3} ->
            reflaxe_structural_callback_node_3.()
          :error ->
            apply(Map.get(reflaxe_structural_receiver_node_3, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_3, :__struct__), :iterator, [reflaxe_structural_receiver_node_3])
        end)
    end)
    {arr} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {arr}, fn _, {acc_arr} ->
      try do
        if ((case v do
        reflaxe_structural_receiver_node_4 ->
          (case Map.fetch(reflaxe_structural_receiver_node_4, :has_next) do
            {:ok, reflaxe_structural_callback_node_4} ->
              reflaxe_structural_callback_node_4.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_4, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_4, :__struct__), :has_next, [reflaxe_structural_receiver_node_4])
          end)
      end)) do
          v = (case v do
            reflaxe_structural_receiver_node_5 ->
              (case Map.fetch(reflaxe_structural_receiver_node_5, :next) do
                {:ok, reflaxe_structural_callback_node_5} ->
                  reflaxe_structural_callback_node_5.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_5, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_5, :__struct__), :next, [reflaxe_structural_receiver_node_5])
              end)
          end)
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
    v = (case a do
      reflaxe_structural_receiver_node_6 ->
        (case Map.fetch(reflaxe_structural_receiver_node_6, :iterator) do
          {:ok, reflaxe_structural_callback_node_6} ->
            reflaxe_structural_callback_node_6.()
          :error ->
            apply(Map.get(reflaxe_structural_receiver_node_6, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_6, :__struct__), :iterator, [reflaxe_structural_receiver_node_6])
        end)
    end)
    {arr} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {arr}, fn _, {acc_arr} ->
      try do
        if ((case v do
        reflaxe_structural_receiver_node_7 ->
          (case Map.fetch(reflaxe_structural_receiver_node_7, :has_next) do
            {:ok, reflaxe_structural_callback_node_7} ->
              reflaxe_structural_callback_node_7.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_7, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_7, :__struct__), :has_next, [reflaxe_structural_receiver_node_7])
          end)
      end)) do
          v = (case v do
            reflaxe_structural_receiver_node_8 ->
              (case Map.fetch(reflaxe_structural_receiver_node_8, :next) do
                {:ok, reflaxe_structural_callback_node_8} ->
                  reflaxe_structural_callback_node_8.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_8, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_8, :__struct__), :next, [reflaxe_structural_receiver_node_8])
              end)
          end)
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
    v = (case b do
      reflaxe_structural_receiver_node_9 ->
        (case Map.fetch(reflaxe_structural_receiver_node_9, :iterator) do
          {:ok, reflaxe_structural_callback_node_9} ->
            reflaxe_structural_callback_node_9.()
          :error ->
            apply(Map.get(reflaxe_structural_receiver_node_9, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_9, :__struct__), :iterator, [reflaxe_structural_receiver_node_9])
        end)
    end)
    {arr} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {arr}, fn _, {acc_arr} ->
      try do
        if ((case v do
        reflaxe_structural_receiver_node_10 ->
          (case Map.fetch(reflaxe_structural_receiver_node_10, :has_next) do
            {:ok, reflaxe_structural_callback_node_10} ->
              reflaxe_structural_callback_node_10.()
            :error ->
              apply(Map.get(reflaxe_structural_receiver_node_10, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_10, :__struct__), :has_next, [reflaxe_structural_receiver_node_10])
          end)
      end)) do
          v = (case v do
            reflaxe_structural_receiver_node_11 ->
              (case Map.fetch(reflaxe_structural_receiver_node_11, :next) do
                {:ok, reflaxe_structural_callback_node_11} ->
                  reflaxe_structural_callback_node_11.()
                :error ->
                  apply(Map.get(reflaxe_structural_receiver_node_11, :__reflaxe_class__) || Map.get(reflaxe_structural_receiver_node_11, :__struct__), :next, [reflaxe_structural_receiver_node_11])
              end)
          end)
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
  def count(it, pred \\ nil) do
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
