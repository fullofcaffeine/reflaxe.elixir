var map = new haxe.DynamicAccess();
map.exists("foo") == false;
map.get("foo") == null;
(map["foo"] = 1) == 1;
map.set("bar", 2);
map.set("baz", 3) == 3;
map.exists("foo") == true;
map.exists("bar") == true;
map.exists("baz") == true;
map.get("foo") == 1;
map.get("bar") == 2;
map.get("baz") == 3;
var values = [];
for (key in map.keys()) {
	values.push(map[key]);
}
values.length == 3;
t(values[0] == 1 || values[0] == 2 || values[0] == 3);
t(values[1] == 1 || values[1] == 2 || values[1] == 3);
t(values[2] == 1 || values[2] == 2 || values[2] == 3);
var keys = ["foo", "bar", "baz"];
for (key in map.keys()) {
	t(keys.remove(key));
}
keys == [];
map.remove("bar") == true;
map.remove("bar") == false;
map.exists("foo") == true;
map.exists("bar") == false;
map.exists("baz") == true;
map.get("bar") == null;
map["bar"] == null;
map = {test: 2};
map["test"] == 2;
var d:Dynamic<Int> = map;
d.test == 2;
var map = new haxe.DynamicAccess();
map["a"] = 1;
map["b"] = 2;
map["c"] = 3;
var values = [];
for (value in map) {
	values.push(value);
}
values.length == 3;
t(values[0] == 1 || values[0] == 2 || values[0] == 3);
t(values[1] == 1 || values[1] == 2 || values[1] == 3);
t(values[2] == 1 || values[2] == 2 || values[2] == 3);
var keys = [];
var values = [];
for (key => value in map) {
	keys.push(key);
	values.push(value);
}
keys.length == 3;
t(keys[0] == "a" || keys[0] == "b" || keys[0] == "c");
t(keys[1] == "a" || keys[1] == "b" || keys[1] == "c");
t(keys[2] == "a" || keys[2] == "b" || keys[2] == "c");
values.length == 3;
t(values[0] == 1 || values[0] == 2 || values[0] == 3);
t(values[1] == 1 || values[1] == 2 || values[1] == 3);
t(values[2] == 1 || values[2] == 2 || values[2] == 3);
