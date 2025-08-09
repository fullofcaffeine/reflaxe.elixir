package test.integration;

class TestModule {
    public static function main() {
        trace("Hello from integrated Mix compilation\!");
    }
    
    public static function getMessage(): String {
        return "Mix integration successful\!";
    }
}
