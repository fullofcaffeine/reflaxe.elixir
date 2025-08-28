/**
 * Test case specifically for TypeSafeChildSpecBuilder pattern
 */
class TestBuilder {
    public static function pubsub(appName: String): String {
        return appName + ".PubSub";
    }
    
    public static function endpoint(appName: String, ?port: Int): String {
        var actualPort = port != null ? port : 4000;
        return appName + ".Endpoint on port " + actualPort;
    }
}