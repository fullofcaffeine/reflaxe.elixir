defmodule CallStack_Impl_ do
  defp get_length(this1) do
    this1.length
  end
  def call_stack() do
    NativeStackTrace.to_haxe(NativeStackTrace.call_stack())
  end
  def exception_stack(full_stack) do
    e_stack = NativeStackTrace.to_haxe(NativeStackTrace.exception_stack())
    this_1 = if full_stack do
  e_stack
else
  CallStack_Impl_.subtract(e_stack, CallStack_Impl_.call_stack())
end
    this_1
  end
  def to_string(stack) do
    b = StringBuf.new()
    g = 0
    g1 = stack
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1.length) do
  s = g1[g]
  g + 1
  b = b.b + "\nCalled from "
  CallStack_Impl_.item_to_string(b, s)
  {:cont, acc}
else
  {:halt, acc}
end end)
    b.b
  end
  def subtract(this1, stack) do
    start_index = -1
    i = -1
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (i + 1 < this1.length) do
  g = 0
  g1 = stack.length
  Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  j = g + 1
  if (CallStack_Impl_.equal_items(this1[i], stack[j])) do
    if (start_index < 0) do
      start_index = i
    end
    i + 1
    if (i >= this1.length) do
      throw(:break)
    end
  else
    start_index = -1
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
  if (start_index >= 0) do
    throw(:break)
  end
  {:cont, acc}
else
  {:halt, acc}
end end)
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
              m_2 = g1
              m_1 = g
              m == m
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
              item_2 = g4
              file_2 = g5
              line_2 = g6
              col_2 = g7
              col_1 = g3
              line_1 = g2
              file_1 = g1
              item_1 = g
              file == file && line == line && col == col && CallStack_Impl_.equal_items(item, item)
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
              class_2 = g2
              method_2 = g3
              method_1 = g1
              class_1 = g
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
              v_2 = g1
              v_1 = g
              v == v
            else
              false
            end
          end
      end
    end
  end
  defp exception_to_string(e) do
    if (e.get_previous() == nil) do
      "Exception: " + e.toString() + tmp = e.get_stack()
if (tmp == nil) do
  "null"
else
  CallStack_Impl_.to_string(tmp)
end
    end
    result = ""
    e = e
    prev = nil
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (e != nil) do
  if (prev == nil) do
    result = "Exception: " + e.get_message() + tmp = e.get_stack()
if (tmp == nil) do
  "null"
else
  CallStack_Impl_.to_string(tmp)
end + result
  else
    prev_stack = CallStack_Impl_.subtract(e.get_stack(), prev.get_stack())
    result = "Exception: " + e.get_message() + (if (prev_stack == nil) do
  "null"
else
  CallStack_Impl_.to_string(prev_stack)
end) + "\n\nNext " + result
  end
  prev = e
  e = e.get_previous()
  {:cont, acc}
else
  {:halt, acc}
end end)
    result
  end
  defp item_to_string(b, s) do
    case (s.elem(0)) do
      0 ->
        b = b.b + "a C function"
      1 ->
        g = s.elem(1)
        m = g
        b = b.b + "module "
        b = b.b + Std.string(m)
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
          CallStack_Impl_.item_to_string(b, s)
          b = b.b + " ("
        end
        b = b.b + Std.string(file)
        b = b.b + " line "
        b = b.b + Std.string(line)
        if (col != nil) do
          b = b.b + " column "
          b = b.b + Std.string(col)
        end
        if (s != nil) do
          b = b.b + ")"
        end
      3 ->
        g = s.elem(1)
        g1 = s.elem(2)
        cname = g
        meth = g1
        b = b.b + Std.string((if (cname == nil), do: "<unknown>", else: cname))
        b = b.b + "."
        b = b.b + Std.string(meth)
      4 ->
        g = s.elem(1)
        n = g
        b = b.b + "local function #"
        b = b.b + Std.string(n)
    end
  end
end