defmodule CallStack_Impl_ do
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
  if (acc_g < acc_g1.length) do
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
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {this1, g, start_index, i, :ok}, fn _, {acc_this1, acc_g, acc_start_index, acc_i, acc_state} ->
  if (acc_i = acc_i + 1 < acc_this1.length) do
    acc_g = 0
    g1 = stack.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {acc_g, g1, acc_start_index, acc_i, :ok}, fn _, {acc_g, acc_g1, acc_start_index, acc_i, acc_state} ->
  if (acc_g < acc_g1) do
    j = acc_g = acc_g + 1
    if (equal_items(this1[i], stack[j])) do
      if (acc_start_index < 0) do
        acc_start_index = acc_i
      end
      acc_i = acc_i + 1
      if (acc_i >= this1.length) do
        throw(:break)
      end
    else
      acc_start_index = -1
    end
    {:cont, {acc_g, acc_g1, acc_start_index, acc_i, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_start_index, acc_i, acc_state}}
  end
end)
    if (acc_start_index >= 0) do
      throw(:break)
    end
    {:cont, {acc_this1, acc_g, acc_start_index, acc_i, acc_state}}
  else
    {:halt, {acc_this1, acc_g, acc_start_index, acc_i, acc_state}}
  end
end)
    if (start_index >= 0) do
      if (end == nil) do
        Enum.slice(this1, 0..-1)
      else
        Enum.slice(this1, 0..start_index)
      end
    else
      this1
    end
  end
  defp equal_items(item1, item2) do
    if (item1 == nil) do
      if (item2 == nil), do: true, else: false
    else
      case (item1.elem(0)) do
        0 ->
          if (item2 == nil) do
            false
          else
            if (item2.elem(0) == 0), do: true, else: false
          end
        1 ->
          g = item1.elem(1)
          if (item2 == nil) do
            false
          else
            if (item2.elem(0) == 1) do
              g1 = item2.elem(1)
              m2 = g1
              m1 = g
              m1 == m2
            else
              false
            end
          end
        2 ->
          g = item1.elem(1)
          g1 = item1.elem(2)
          g2 = item1.elem(3)
          g3 = item1.elem(4)
          if (item2 == nil) do
            false
          else
            if (item2.elem(0) == 2) do
              g4 = item2.elem(1)
              g5 = item2.elem(2)
              g6 = item2.elem(3)
              g7 = item2.elem(4)
              item2 = g4
              file2 = g5
              line2 = g6
              col2 = g7
              col1 = g3
              line1 = g2
              file1 = g1
              item1 = g
              file == file && line == line && col == col && equal_items(item, item)
            else
              false
            end
          end
        3 ->
          g = item1.elem(1)
          g1 = item1.elem(2)
          if (item2 == nil) do
            false
          else
            if (item2.elem(0) == 3) do
              g2 = item2.elem(1)
              g3 = item2.elem(2)
              class2 = g2
              method2 = g3
              method1 = g1
              class1 = g
              class == class && method == method
            else
              false
            end
          end
        4 ->
          g = item1.elem(1)
          if (item2 == nil) do
            false
          else
            if (item2.elem(0) == 4) do
              g1 = item2.elem(1)
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
      "Exception: " <> e.toString() <> (if tmp == nil, do: "null", else: to_string(tmp))
    end
    result = ""
    e = e
    prev = nil
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {prev, result, e, :ok}, fn _, {acc_prev, acc_result, acc_e, acc_state} ->
  if (acc_e != nil) do
    if (acc_prev == nil) do
      tmp = acc_e.get_stack()
      acc_result = "Exception: " <> acc_e.get_message() <> (if tmp == nil, do: "null", else: to_string(tmp)) <> acc_result
    else
      prev_stack = subtract(acc_e.get_stack(), acc_prev.get_stack())
      acc_result = "Exception: " <> acc_e.get_message() <> (if (prev_stack == nil), do: "null", else: to_string(prev_stack)) <> "\n\nNext " <> acc_result
    end
    acc_prev = acc_e
    acc_e = acc_e.get_previous()
    {:cont, {acc_prev, acc_result, acc_e, acc_state}}
  else
    {:halt, {acc_prev, acc_result, acc_e, acc_state}}
  end
end)
    result
  end
  defp item_to_string(b, s) do
    case (s.elem(0)) do
      0 ->
        b.add("a C function")
      1 ->
        g = s.elem(1)
        m = g
        b.add("module ")
        b.add(m)
      2 ->
        g = s.elem(1)
        g1 = s.elem(2)
        g2 = s.elem(3)
        g3 = s.elem(4)
        s = g
        file = g1
        line = g2
        col = g3
        if (s != nil) do
          item_to_string(b, s)
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
        g = s.elem(1)
        g1 = s.elem(2)
        cname = g
        meth = g1
        b.add((if (cname == nil), do: "<unknown>", else: cname))
        b.add(".")
        b.add(meth)
      4 ->
        g = s.elem(1)
        n = g
        b.add("local function #")
        b.add(n)
    end
  end
end