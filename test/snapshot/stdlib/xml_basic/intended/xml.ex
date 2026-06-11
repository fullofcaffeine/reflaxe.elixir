defmodule Xml do
  import Kernel, except: [to_string: 1], warn: false
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, Xml, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, Xml, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def element() do
    __haxe_static_get__(:element, 0)
  end
  def element(value) do
    __haxe_static_put__(:element, value)
  end
  def pc_data() do
    __haxe_static_get__(:pc_data, 1)
  end
  def pc_data(value) do
    __haxe_static_put__(:pc_data, value)
  end
  def c_data() do
    __haxe_static_get__(:c_data, 2)
  end
  def c_data(value) do
    __haxe_static_put__(:c_data, value)
  end
  def comment() do
    __haxe_static_get__(:comment, 3)
  end
  def comment(value) do
    __haxe_static_put__(:comment, value)
  end
  def doc_type() do
    __haxe_static_get__(:doc_type, 4)
  end
  def doc_type(value) do
    __haxe_static_put__(:doc_type, value)
  end
  def processing_instruction() do
    __haxe_static_get__(:processing_instruction, 5)
  end
  def processing_instruction(value) do
    __haxe_static_put__(:processing_instruction, value)
  end
  def document() do
    __haxe_static_get__(:document, 6)
  end
  def document(value) do
    __haxe_static_put__(:document, value)
  end
  def get_parent(struct) do
    Map.fetch!(Process.get({:reflaxe_xml_node, struct.xml_ref}, struct), :parent)
  end
  def get_node_name(struct) do
    _ = ensure_element(struct)
    Map.fetch!(Process.get({:reflaxe_xml_node, struct.xml_ref}, struct), :node_name)
  end
  def set_node_name(struct, value) do
    _ = ensure_element(struct)
    node = Process.get({:reflaxe_xml_node, struct.xml_ref}, struct)
			Process.put({:reflaxe_xml_node, struct.xml_ref}, %{node | node_name: value})
    value
  end
  def get_node_value(struct) do
    _ = ensure_value(struct)
    Map.fetch!(Process.get({:reflaxe_xml_node, struct.xml_ref}, struct), :node_value)
  end
  def set_node_value(struct, value) do
    _ = ensure_value(struct)
    node = Process.get({:reflaxe_xml_node, struct.xml_ref}, struct)
			Process.put({:reflaxe_xml_node, struct.xml_ref}, %{node | node_value: value})
    value
  end
  def get(struct, att) do
    _ = ensure_element(struct)
    Map.get(Map.fetch!(Process.get({:reflaxe_xml_node, struct.xml_ref}, struct), :attribute_map), att)
  end
  def set(struct, att, value) do
    _ = ensure_element(struct)
    node = Process.get({:reflaxe_xml_node, struct.xml_ref}, struct)
			attrs = Map.put(Map.fetch!(node, :attribute_map), att, value)
			Process.put({:reflaxe_xml_node, struct.xml_ref}, %{node | attribute_map: attrs})
  end
  def remove(struct, att) do
    _ = ensure_element(struct)
    node = Process.get({:reflaxe_xml_node, struct.xml_ref}, struct)
			attrs = Map.delete(Map.fetch!(node, :attribute_map), att)
			Process.put({:reflaxe_xml_node, struct.xml_ref}, %{node | attribute_map: attrs})
  end
  def exists(struct, att) do
    _ = ensure_element(struct)
    Map.has_key?(Map.fetch!(Process.get({:reflaxe_xml_node, struct.xml_ref}, struct), :attribute_map), att)
  end
  def attributes(struct) do
    _ = ensure_element(struct)
    keys = Map.keys(Map.fetch!(Process.get({:reflaxe_xml_node, struct.xml_ref}, struct), :attribute_map))
    _ = native_iterator(keys)
  end
  def iterator(struct) do
    _ = ensure_element_type(struct)
    nodes = Map.fetch!(Process.get({:reflaxe_xml_node, struct.xml_ref}, struct), :children)
    _ = native_iterator(nodes)
  end
  def elements(struct) do
    _ = ensure_element_type(struct)
    nodes = Enum.filter(Map.fetch!(Process.get({:reflaxe_xml_node, struct.xml_ref}, struct), :children), fn child -> child.node_type == 0 end)
    _ = native_iterator(nodes)
  end
  def elements_named(struct, name) do
    _ = ensure_element_type(struct)
    nodes = Enum.filter(Map.fetch!(Process.get({:reflaxe_xml_node, struct.xml_ref}, struct), :children), fn child -> child.node_type == 0 and child.node_name == name end)
    _ = native_iterator(nodes)
  end
  def first_child(struct) do
    _ = ensure_element_type(struct)
    List.first(Map.fetch!(Process.get({:reflaxe_xml_node, struct.xml_ref}, struct), :children))
  end
  def first_element(struct) do
    _ = ensure_element_type(struct)
    Enum.find(Map.fetch!(Process.get({:reflaxe_xml_node, struct.xml_ref}, struct), :children), fn child -> child.node_type == 0 end)
  end
  def add_child(struct, child) do
    _ = ensure_element_type(struct)
    parent = Process.get({:reflaxe_xml_node, struct.xml_ref}, struct)
			stored_child = Process.get({:reflaxe_xml_node, child.xml_ref}, child)
			child = %{stored_child | parent: parent}
			Process.put({:reflaxe_xml_node, child.xml_ref}, child)
			Process.put({:reflaxe_xml_node, struct.xml_ref}, %{parent | children: Map.fetch!(parent, :children) ++ [child]})
  end
  def remove_child(struct, child) do
    _ = ensure_element_type(struct)
    (fn ->
				parent = Process.get({:reflaxe_xml_node, struct.xml_ref}, struct)
				children = Map.fetch!(parent, :children)
				existed = Enum.any?(children, fn existing -> existing.xml_ref == child.xml_ref end)
				next_children = Enum.reject(children, fn existing -> existing.xml_ref == child.xml_ref end)
				Process.put({:reflaxe_xml_node, struct.xml_ref}, %{parent | children: next_children})
				if existed do
					stored_child = Process.get({:reflaxe_xml_node, child.xml_ref}, child)
					Process.put({:reflaxe_xml_node, child.xml_ref}, %{stored_child | parent: nil})
				end
				existed
			end).()
  end
  def insert_child(struct, child, pos) do
    _ = ensure_element_type(struct)
    parent = Process.get({:reflaxe_xml_node, struct.xml_ref}, struct)
			stored_child = Process.get({:reflaxe_xml_node, child.xml_ref}, child)
			child = %{stored_child | parent: parent}
			Process.put({:reflaxe_xml_node, child.xml_ref}, child)
			children = Map.fetch!(parent, :children)
			next_children = List.insert_at(children, pos, child)
			Process.put({:reflaxe_xml_node, struct.xml_ref}, %{parent | children: next_children})
  end
  def to_string(struct) do
    (fn ->
				escape_text = fn value ->
					value
					|> Kernel.to_string()
					|> String.replace("&", "&amp;")
					|> String.replace("<", "&lt;")
					|> String.replace(">", "&gt;")
				end
				escape_attr = fn value ->
					escape_text.(value)
					|> String.replace(<<34>>, "&quot;")
				end
				render = fn render, node ->
					node = Process.get({:reflaxe_xml_node, node.xml_ref}, node)
					case node.node_type do
						6 ->
							Enum.map_join(node.children, "", fn child -> render.(render, child) end)
						0 ->
							attrs =
								node.attribute_map
								|> Enum.map(fn {key, value} -> " " <> Kernel.to_string(key) <> "=" <> <<34>> <> escape_attr.(value) <> <<34>> end)
								|> Enum.join("")
							if Enum.empty?(node.children) do
								"<" <> node.node_name <> attrs <> "/>"
							else
								inner = Enum.map_join(node.children, "", fn child -> render.(render, child) end)
								"<" <> node.node_name <> attrs <> ">" <> inner <> "</" <> node.node_name <> ">"
							end
						1 ->
							escape_text.(node.node_value || "")
						2 ->
							"<![CDATA[" <> Kernel.to_string(node.node_value || "") <> "]]>"
						3 ->
							"<!--" <> Kernel.to_string(node.node_value || "") <> "-->"
						4 ->
							"<!DOCTYPE " <> Kernel.to_string(node.node_value || "") <> ">"
						5 ->
							"<?" <> Kernel.to_string(node.node_value || "") <> "?>"
					end
				end
				render.(render, struct)
			end).()
  end
  defp ensure_element(struct) do
    if struct.node_type != Xml.element(), do: raise("Bad node type, expected Element")
  end
  defp ensure_value(struct) do
    if struct.node_type == Xml.document() or struct.node_type == Xml.element(), do: raise("Bad node type, expected value node")
  end
  defp ensure_element_type(struct) do
    if struct.node_type != Xml.document() and struct.node_type != Xml.element(), do: raise("Bad node type, expected Element or Document")
  end
  def parse(str) do
    (fn ->
				make_node = fn node_type, node_name, node_value, attributes, children ->
					ref = :erlang.unique_integer([:positive])
					node = %{
						__struct__: Xml,
						__reflaxe_class__: Xml,
						node_type: node_type,
						node_name: node_name,
						node_value: node_value,
						parent: nil,
						children: children,
						attribute_map: attributes,
						xml_ref: ref
					}
					children_with_parent =
						Enum.map(children, fn child ->
							stored_child = Process.get({:reflaxe_xml_node, child.xml_ref}, child)
							updated_child = %{stored_child | parent: node}
							Process.put({:reflaxe_xml_node, child.xml_ref}, updated_child)
							updated_child
						end)
					node = %{node | children: children_with_parent}
					Process.put({:reflaxe_xml_node, ref}, node)
					node
				end
				build = fn build, xmerl_node ->
					case xmerl_node do
						{:xmlElement, name, _, _, _, _, _, attrs, content, _, _, _} ->
							attributes =
								Enum.reduce(attrs, %{}, fn
									{:xmlAttribute, attr_name, _, _, _, _, _, _, value, _}, acc ->
										Map.put(acc, Atom.to_string(attr_name), List.to_string(value))
									_, acc ->
										acc
								end)
							children =
								content
								|> Enum.map(&build.(build, &1))
								|> Enum.reject(&is_nil/1)
							make_node.(0, Atom.to_string(name), nil, attributes, children)
						{:xmlText, _, _, _, value, :text} ->
							text = List.to_string(value)
							if text == "", do: nil, else: make_node.(1, nil, text, %{}, [])
						{:xmlText, _, _, _, value, :cdata} ->
							make_node.(2, nil, List.to_string(value), %{}, [])
						{:xmlComment, _, _, _, value} ->
							make_node.(3, nil, List.to_string(value), %{}, [])
						_ ->
							nil
					end
				end
				{root, _} = :xmerl_scan.string(String.to_charlist(str), quiet: true)
				root_node = build.(build, root)
				make_node.(6, nil, nil, %{}, [root_node])
			end).()
  end
  def create_element(name) do
    new_native(Xml.element(), name, nil)
  end
  def create_pc_data(data) do
    new_native(Xml.pc_data(), nil, data)
  end
  def create_c_data(data) do
    new_native(Xml.c_data(), nil, data)
  end
  def create_comment(data) do
    new_native(Xml.comment(), nil, data)
  end
  def create_doc_type(data) do
    new_native(Xml.doc_type(), nil, data)
  end
  def create_processing_instruction(data) do
    new_native(Xml.processing_instruction(), nil, data)
  end
  def create_document() do
    new_native(Xml.document(), nil, nil)
  end
  defp new_native(node_type_param, node_name_param, node_value_param) do
    (fn ->
				ref = :erlang.unique_integer([:positive])
				node = %{
					__struct__: Xml,
					__reflaxe_class__: Xml,
					node_type: node_type_param,
					node_name: node_name_param,
					node_value: node_value_param,
					parent: nil,
					children: [],
					attribute_map: %{},
					xml_ref: ref
				}
				Process.put({:reflaxe_xml_node, ref}, node)
				node
			end).()
  end
  defp native_iterator(items) do
    (fn ->
				ref = make_ref()
				state_key = {Xml, :iterator, ref}
				Process.put(state_key, 0)
				%{
					__reflaxe_class__: ArrayIterator,
					array: items,
					ref: ref,
					current: 0,
					has_next: fn ->
						Process.get(state_key, 0) < length(items)
					end,
					next: fn ->
						index = Process.get(state_key, 0)
						Process.put(state_key, index + 1)
						Enum.at(items, index)
					end
				}
			end).()
  end
end
