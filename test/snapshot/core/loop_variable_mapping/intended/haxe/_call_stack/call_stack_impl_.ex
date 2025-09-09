defmodule CallStack_Impl_ do
  @length nil
  defp get_length(this1) do
    length(this1)
  end
  def call_stack() do
    NativeStackTrace.to_haxe(NativeStackTrace.call_stack())
  end
  def exception_stack(full_stack) do
    e_stack = NativeStackTrace.to_haxe(NativeStackTrace.exception_stack())
    this1 = if full_stack, do: e_stack, else: subtract(e_stack, call_stack())
    this1
  end
  def to_string(stack) do
    b = StringBuf.new()
    g = 0
    g1 = stack
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < length(acc_g1)) do
    s = g1[g]
    acc_g = acc_g + 1
    b.add("\nCalled from ")
    item_to_string(b, s)
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    IO.iodata_to_binary(b)
  end
  def subtract(this1, stack) do
    start_index = -1
    i = -1
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {start_index, i, g, this1, :ok}, fn _, {acc_start_index, acc_i, acc_g, acc_this1, acc_state} -> nil end)
    if (start_index >= 0) do
      if (end_param == nil) do
        Enum.slice(this1, 0..-1//1)
      else
        Enum.slice(this1, 0..start_index//1)
      end
    else
      this1
    end
  end
  def copy(this1) do
    this1
  end
  def get(this1, index) do
    this1[index]
  end
  defp as_array(this1) do
    this1
  end
  defp equal_items(item1, item2) do
    if (item1 == nil) do
      if (item2 == nil), do: true, else: false
    else
      case (elem(item1, 0)) do
        0 ->
          if (item2 == nil) do
            false
          else
            if (elem(item2, 0) == 0), do: true, else: false
          end
        1 ->
          g = elem(item1, 1)
          if (item2 == nil) do
            false
          else
            if (elem(item2, 0) == 1) do
              g1 = elem(item2, 1)
              m2 = g1
              m1 = g
              m1 == m2
            else
              false
            end
          end
        2 ->
          g = elem(item1, 1)
          g1 = elem(item1, 2)
          g2 = elem(item1, 3)
          g3 = elem(item1, 4)
          if (item2 == nil) do
            false
          else
            if (elem(item2, 0) == 2) do
              g4 = elem(item2, 1)
              g5 = elem(item2, 2)
              g6 = elem(item2, 3)
              g7 = elem(item2, 4)
              item2 = g4
              file2 = g5
              line2 = g6
              col2 = g7
              col1 = g3
              line1 = g2
              file1 = g1
              item1 = g
              file1 == file2 && line1 == line2 && col1 == col2 && equal_items(item1, item2)
            else
              false
            end
          end
        3 ->
          g = elem(item1, 1)
          g1 = elem(item1, 2)
          if (item2 == nil) do
            false
          else
            if (elem(item2, 0) == 3) do
              g2 = elem(item2, 1)
              g3 = elem(item2, 2)
              class2 = g2
              method2 = g3
              method1 = g1
              class1 = g
              class1 == class2 && method1 == method2
            else
              false
            end
          end
        4 ->
          g = elem(item1, 1)
          if (item2 == nil) do
            false
          else
            if (elem(item2, 0) == 4) do
              g1 = elem(item2, 1)
              v2 = g1
              v1 = g
              v1 == v2
            else
              false
            end
          end
      end
    end
  end
  defp exception_to_string(e) do
    if (e.get_previous() == nil) do
      tmp = e.get_stack()
      "Exception: " <> e.to_string() <> (if tmp == nil, do: "null", else: to_string(tmp))
    end
    result = ""
    e = e
    prev = nil
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {result, prev, e, :ok}, fn _, {acc_result, acc_prev, acc_e, acc_state} -> nil end)
    result
  end
  defp item_to_string(b, _s) do
    case (elem(_s, 0)) do
      0 ->
        b.add("a C function")
      1 ->
        g = elem(_s, 1)
        m = g
        b.add("module ")
        b.add(m)
      2 ->
        g = elem(_s, 1)
        g1 = elem(_s, 2)
        g2 = elem(_s, 3)
        g3 = elem(_s, 4)
        s = g
        file = g1
        line = g2
        col = g3
        if (s != nil) do
          item_to_string(b, _s)
          b.add(" (")
        end
        b.add(file)
        b.add(" line ")
        b.add(line)
        if (col != nil) do
          b.add(" column ")
          b.add(col)
        end
        if (s != nil), do: b.add(")")
      3 ->
        g = elem(_s, 1)
        g1 = elem(_s, 2)
        cname = g
        meth = g1
        b.add((if (cname == nil), do: "<unknown>", else: cname))
        b.add(".")
        b.add(meth)
      4 ->
        g = elem(_s, 1)
        n = g
        b.add("local function #")
        b.add(n)
    end
  end
end