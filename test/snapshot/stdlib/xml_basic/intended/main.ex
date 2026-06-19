defmodule Main do
  def main() do
    _ = test_parse()
    _ = test_build_and_mutate()
  end
  defp test_parse() do
    doc = Xml.parse("<root id=\"42\"><item>A</item><item>B</item><!--ok--></root>")
    root = apply(Map.get(doc, :__reflaxe_class__) || Map.get(doc, :__struct__), :first_element, [doc])
    _ = expect("root name", Xml.get_node_name(root) == "root")
    _ = expect("root id", apply(Map.get(root, :__reflaxe_class__) || Map.get(root, :__struct__), :get, [root, "id"]) == "42")
    _ = expect("has id", apply(Map.get(root, :__reflaxe_class__) || Map.get(root, :__struct__), :exists, [root, "id"]))
    _ = expect("root parent", Xml.get_parent(root).node_type == Xml.document())
    attrs = apply(Map.get(root, :__reflaxe_class__) || Map.get(root, :__struct__), :attributes, [root])
    _ = expect("attr has first", attrs.has_next.())
    _ = expect("attr name", attrs.next.() == "id")
    _ = expect("attr exhausted", not attrs.has_next.())
    count = 0
    item = apply(Map.get(root, :__reflaxe_class__) || Map.get(root, :__struct__), :elements_named, [root, "item"])
    {count} = Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {count}, fn _, {acc_count} ->
      try do
        if (item.has_next.()) do
          item = item.next.()
          _ = acc_count
          acc_count = acc_count + 1
          _ = expect("item text", Xml.get_node_value(apply(Map.get(item, :__reflaxe_class__) || Map.get(item, :__struct__), :first_child, [item])) == (if (acc_count == 1), do: "A", else: "B"))
          {:cont, {acc_count}}
        else
          {:halt, {acc_count}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_count}}
        :throw, :continue ->
          {:cont, {acc_count}}
      end
    end)
    _ = expect("item count", count == 2)
  end
  defp test_build_and_mutate() do
    root = Xml.create_element("root")
    _ = apply(Map.get(root, :__reflaxe_class__) || Map.get(root, :__struct__), :set, [root, "lang", "en"])
    _ = apply(Map.get(root, :__reflaxe_class__) || Map.get(root, :__struct__), :add_child, [root, Xml.create_pc_data("hello")])
    child = Xml.create_element("child")
    _ = apply(Map.get(child, :__reflaxe_class__) || Map.get(child, :__struct__), :set, [child, "name", "one"])
    _ = apply(Map.get(root, :__reflaxe_class__) || Map.get(root, :__struct__), :add_child, [root, child])
    _ = expect("child parent after add", Xml.get_node_name(Xml.get_parent(child)) == "root")
    _ = apply(Map.get(root, :__reflaxe_class__) || Map.get(root, :__struct__), :insert_child, [root, Xml.create_comment("marker"), 1])
    _ = expect("built xml", apply(Map.get(root, :__reflaxe_class__) || Map.get(root, :__struct__), :to_string, [root]) == "<root lang=\"en\">hello<!--marker--><child name=\"one\"/></root>")
    _ = expect("first element", Xml.get_node_name(apply(Map.get(root, :__reflaxe_class__) || Map.get(root, :__struct__), :first_element, [root])) == "child")
    _ = expect("removed child", apply(Map.get(root, :__reflaxe_class__) || Map.get(root, :__struct__), :remove_child, [root, child]))
    _ = expect("child parent after remove", Kernel.is_nil(Xml.get_parent(child)))
    _ = expect("after remove", apply(Map.get(root, :__reflaxe_class__) || Map.get(root, :__struct__), :to_string, [root]) == "<root lang=\"en\">hello<!--marker--></root>")
  end
  defp expect(label, condition) do
    if not (condition), do: raise("Xml assertion failed: " <> label)
  end
end
