package;

class Main {
	static function main() {
		testParse();
		testBuildAndMutate();
	}

	static function testParse() {
		var doc = Xml.parse('<root id="42"><item>A</item><item>B</item><!--ok--></root>');
		var root = doc.firstElement();
		expect("root name", root.nodeName == "root");
		expect("root id", root.get("id") == "42");
		expect("has id", root.exists("id"));
		expect("root parent", root.parent.nodeType == Xml.Document);

		var attrs = root.attributes();
		expect("attr has first", attrs.hasNext());
		expect("attr name", attrs.next() == "id");
		expect("attr exhausted", !attrs.hasNext());

		var count = 0;
		for (item in root.elementsNamed("item")) {
			count++;
			expect("item text", item.firstChild().nodeValue == (count == 1 ? "A" : "B"));
		}
		expect("item count", count == 2);
	}

	static function testBuildAndMutate() {
		var root = Xml.createElement("root");
		root.set("lang", "en");
		root.addChild(Xml.createPCData("hello"));

		var child = Xml.createElement("child");
		child.set("name", "one");
		root.addChild(child);
		expect("child parent after add", child.parent.nodeName == "root");
		root.insertChild(Xml.createComment("marker"), 1);

		expect("built xml", root.toString() == '<root lang="en">hello<!--marker--><child name="one"/></root>');
		expect("first element", root.firstElement().nodeName == "child");
		expect("removed child", root.removeChild(child));
		expect("child parent after remove", child.parent == null);
		expect("after remove", root.toString() == '<root lang="en">hello<!--marker--></root>');
	}

	static function expect(label:String, condition:Bool):Void {
		untyped __elixir__('if not ({1}), do: raise("Xml assertion failed: " <> {0})', label, condition);
	}
}
