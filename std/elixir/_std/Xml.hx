/**
 * Elixir-target Xml implementation.
 *
 * WHAT: Provides the standard Haxe Xml API for the BEAM.
 * WHY: The upstream Xml parser mutates parent/child arrays in-place. Elixir data is
 * immutable, so compiling that implementation directly loses updates that Haxe code
 * expects from `set`, `addChild`, and parser construction.
 * HOW: Xml values are normal generated structs for field access, plus a process-local
 * reference used by Xml methods to observe Haxe-style mutations.
 */
enum abstract XmlType(Int) {
	var Element = 0;
	var PCData = 1;
	var CData = 2;
	var Comment = 3;
	var DocType = 4;
	var ProcessingInstruction = 5;
	var Document = 6;

	public function toString():String {
		return switch (cast this : XmlType) {
			case Element: "Element";
			case PCData: "PCData";
			case CData: "CData";
			case Comment: "Comment";
			case DocType: "DocType";
			case ProcessingInstruction: "ProcessingInstruction";
			case Document: "Document";
		};
	}
}

class Xml {
	static public var Element(default, never) = XmlType.Element;
	static public var PCData(default, never) = XmlType.PCData;
	static public var CData(default, never) = XmlType.CData;
	static public var Comment(default, never) = XmlType.Comment;
	static public var DocType(default, never) = XmlType.DocType;
	static public var ProcessingInstruction(default, never) = XmlType.ProcessingInstruction;
	static public var Document(default, never) = XmlType.Document;

	public var nodeType(default, null):XmlType;
	@:isVar public var nodeName(get, set):String;
	@:isVar public var nodeValue(get, set):String;
	@:isVar public var parent(get, null):Null<Xml>;

	var children:Array<Xml>;
	var attributeMap:Map<String, String>;
	var xmlRef:Int;

	static public function parse(str:String):Xml {
		return cast untyped __elixir__('(fn ->
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
				{root, _} = :xmerl_scan.string(String.to_charlist({0}), quiet: true)
				root_node = build.(build, root)
				make_node.(6, nil, nil, %{}, [root_node])
			end).()', str);
	}

	static public function createElement(name:String):Xml {
		return newNative(Element, name, null);
	}

	static public function createPCData(data:String):Xml {
		return newNative(PCData, null, data);
	}

	static public function createCData(data:String):Xml {
		return newNative(CData, null, data);
	}

	static public function createComment(data:String):Xml {
		return newNative(Comment, null, data);
	}

	static public function createDocType(data:String):Xml {
		return newNative(DocType, null, data);
	}

	static public function createProcessingInstruction(data:String):Xml {
		return newNative(ProcessingInstruction, null, data);
	}

	static public function createDocument():Xml {
		return newNative(Document, null, null);
	}

	static function newNative(nodeType:XmlType, nodeName:Null<String>, nodeValue:Null<String>):Xml {
		return cast untyped __elixir__('(fn ->
				ref = :erlang.unique_integer([:positive])
				node = %{
					__struct__: Xml,
					__reflaxe_class__: Xml,
					node_type: {0},
					node_name: {1},
					node_value: {2},
					parent: nil,
					children: [],
					attribute_map: %{},
					xml_ref: ref
				}
				Process.put({:reflaxe_xml_node, ref}, node)
				node
			end).()', nodeType, nodeName, nodeValue);
	}

	function get_parent():Null<Xml> {
		return cast untyped __elixir__('Map.fetch!(Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0}), :parent)', this);
	}

	function get_nodeName():String {
		ensureElement();
		return cast untyped __elixir__('Map.fetch!(Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0}), :node_name)', this);
	}

	function set_nodeName(value:String):String {
		ensureElement();
		untyped __elixir__('node = Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0})
			Process.put({:reflaxe_xml_node, {0}.xml_ref}, %{node | node_name: {1}})', this, value);
		return value;
	}

	function get_nodeValue():String {
		ensureValue();
		return cast untyped __elixir__('Map.fetch!(Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0}), :node_value)', this);
	}

	function set_nodeValue(value:String):String {
		ensureValue();
		untyped __elixir__('node = Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0})
			Process.put({:reflaxe_xml_node, {0}.xml_ref}, %{node | node_value: {1}})', this, value);
		return value;
	}

	public function get(att:String):String {
		ensureElement();
		return cast untyped __elixir__('Map.get(Map.fetch!(Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0}), :attribute_map), {1})', this, att);
	}

	public function set(att:String, value:String):Void {
		ensureElement();
		untyped __elixir__('node = Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0})
			attrs = Map.put(Map.fetch!(node, :attribute_map), {1}, {2})
			Process.put({:reflaxe_xml_node, {0}.xml_ref}, %{node | attribute_map: attrs})', this, att, value);
	}

	public function remove(att:String):Void {
		ensureElement();
		untyped __elixir__('node = Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0})
			attrs = Map.delete(Map.fetch!(node, :attribute_map), {1})
			Process.put({:reflaxe_xml_node, {0}.xml_ref}, %{node | attribute_map: attrs})', this, att);
	}

	public function exists(att:String):Bool {
		ensureElement();
		return untyped __elixir__('Map.has_key?(Map.fetch!(Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0}), :attribute_map), {1})', this, att);
	}

	public function attributes():Iterator<String> {
		ensureElement();
		var keys:Array<String> = cast untyped __elixir__('Map.keys(Map.fetch!(Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0}), :attribute_map))', this);
		return nativeIterator(keys);
	}

	public function iterator():Iterator<Xml> {
		ensureElementType();
		var nodes:Array<Xml> = cast untyped __elixir__('Map.fetch!(Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0}), :children)', this);
		return nativeIterator(nodes);
	}

	public function elements():Iterator<Xml> {
		ensureElementType();
		var nodes:Array<Xml> = cast untyped __elixir__('Enum.filter(Map.fetch!(Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0}), :children), fn child -> child.node_type == 0 end)',
			this);
		return nativeIterator(nodes);
	}

	public function elementsNamed(name:String):Iterator<Xml> {
		ensureElementType();
		var nodes:Array<Xml> = cast untyped __elixir__('Enum.filter(Map.fetch!(Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0}), :children), fn child -> child.node_type == 0 and child.node_name == {1} end)',
			this, name);
		return nativeIterator(nodes);
	}

	public function firstChild():Xml {
		ensureElementType();
		return cast untyped __elixir__('List.first(Map.fetch!(Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0}), :children))', this);
	}

	public function firstElement():Xml {
		ensureElementType();
		return
			cast untyped __elixir__('Enum.find(Map.fetch!(Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0}), :children), fn child -> child.node_type == 0 end)',
				this);
	}

	public function addChild(child:Xml):Void {
		ensureElementType();
		untyped __elixir__('parent = Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0})
			stored_child = Process.get({:reflaxe_xml_node, {1}.xml_ref}, {1})
			child = %{stored_child | parent: parent}
			Process.put({:reflaxe_xml_node, {1}.xml_ref}, child)
			Process.put({:reflaxe_xml_node, {0}.xml_ref}, %{parent | children: Map.fetch!(parent, :children) ++ [child]})', this, child);
	}

	public function removeChild(child:Xml):Bool {
		ensureElementType();
		return untyped __elixir__('(fn ->
				parent = Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0})
				children = Map.fetch!(parent, :children)
				existed = Enum.any?(children, fn existing -> existing.xml_ref == {1}.xml_ref end)
				next_children = Enum.reject(children, fn existing -> existing.xml_ref == {1}.xml_ref end)
				Process.put({:reflaxe_xml_node, {0}.xml_ref}, %{parent | children: next_children})
				if existed do
					stored_child = Process.get({:reflaxe_xml_node, {1}.xml_ref}, {1})
					Process.put({:reflaxe_xml_node, {1}.xml_ref}, %{stored_child | parent: nil})
				end
				existed
			end).()', this, child);
	}

	public function insertChild(child:Xml, pos:Int):Void {
		ensureElementType();
		untyped __elixir__('parent = Process.get({:reflaxe_xml_node, {0}.xml_ref}, {0})
			stored_child = Process.get({:reflaxe_xml_node, {1}.xml_ref}, {1})
			child = %{stored_child | parent: parent}
			Process.put({:reflaxe_xml_node, {1}.xml_ref}, child)
			children = Map.fetch!(parent, :children)
			next_children = List.insert_at(children, {2}, child)
			Process.put({:reflaxe_xml_node, {0}.xml_ref}, %{parent | children: next_children})', this, child, pos);
	}

	static function nativeIterator<T>(items:Array<T>):Iterator<T> {
		return cast untyped __elixir__('(fn ->
				ref = make_ref()
				state_key = {Xml, :iterator, ref}
				Process.put(state_key, 0)
				%{
					__reflaxe_class__: ArrayIterator,
					array: {0},
					ref: ref,
					current: 0,
					has_next: fn ->
						Process.get(state_key, 0) < length({0})
					end,
					next: fn ->
						index = Process.get(state_key, 0)
						Process.put(state_key, index + 1)
						Enum.at({0}, index)
					end
				}
			end).()', items);
	}

	public function toString():String {
		return cast untyped __elixir__('(fn ->
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
				render.(render, {0})
			end).()', this);
	}

	function ensureElement():Void {
		untyped __elixir__('if {0}.node_type != Xml.element(), do: raise("Bad node type, expected Element")', this);
	}

	function ensureValue():Void {
		untyped __elixir__('if {0}.node_type == Xml.document() or {0}.node_type == Xml.element(), do: raise("Bad node type, expected value node")', this);
	}

	function ensureElementType():Void {
		untyped __elixir__('if {0}.node_type != Xml.document() and {0}.node_type != Xml.element(), do: raise("Bad node type, expected Element or Document")',
			this);
	}
}
