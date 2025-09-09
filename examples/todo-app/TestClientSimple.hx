class TestClientSimple {
    static function main() {
        trace("Hello from JavaScript!");
        
        // Test Reflect.isFunction
        var f = function() { return "test"; };
        if (Reflect.isFunction(f)) {
            trace("Function check works!");
        }
        
        // Test basic DOM manipulation
        #if js
        var doc = js.Browser.document;
        trace("Document title: " + doc.title);
        #end
    }
}