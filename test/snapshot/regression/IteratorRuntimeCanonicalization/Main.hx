import haxe.ds.BalancedTree;
import haxe.iterators.MapKeyValueIterator;

class Main {
    static function main() {
        var arrayIterator = [1, 2, 3].iterator();
        var arrayValues: Array<Int> = [];
        while (arrayIterator.hasNext()) {
            arrayValues.push(arrayIterator.next());
        }

        var wrappedMap: Map<String, Int> = [
            "alpha" => 1,
            "beta" => 2
        ];
        var wrappedPairs: Array<String> = [];
        var wrappedIterator = wrappedMap.keyValueIterator();
        while (wrappedIterator.hasNext()) {
            var pair = wrappedIterator.next();
            wrappedPairs.push(pair.key + ":" + pair.value);
        }

        var balancedTree = new BalancedTree<String, Int>();
        balancedTree.set("left", 10);
        balancedTree.set("right", 20);
        var treePairs: Array<String> = [];
        var treeIterator = balancedTree.keyValueIterator();
        while (treeIterator.hasNext()) {
            var treePair = treeIterator.next();
            treePairs.push(treePair.key + ":" + treePair.value);
        }

        var nativeMap: haxe.Constraints.IMap<String, Int> = cast untyped __elixir__('%{"native" => 99}');
        var nativeIterator = new MapKeyValueIterator<String, Int>(nativeMap);
        var nativePair = nativeIterator.next();

        trace(arrayValues.length + wrappedPairs.length + treePairs.length + nativePair.value);
    }
}
