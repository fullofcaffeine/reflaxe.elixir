using ArrayTools;
import elixir.Process;
import elixir.Registry;
import elixir.Agent;
import elixir.IO;
import elixir.File;
import elixir.Path;
import elixir.ElixirEnum;
import elixir.ElixirString;
import elixir.GenServer;
import elixir.types.RegistryOptions.RegistryOptionsBuilder;
import elixir.types.GenServerRef;

/**
 * Test suite for essential standard library extern definitions
 * Tests that all extern definitions compile correctly and generate proper Elixir code
 */
class Main {
    public static function main() {
        testProcessExterns();
        testRegistryExterns();
        testAgentExterns();
        testIOExterns();
        testFileExterns();
        testPathExterns();
        testEnumExterns();
        testStringExterns();
        testGenServerExterns();
    }
    
    static function testProcessExterns() {
        // Test Process module operations
        var pid = Process.self();
        Process.send(pid, "hello");
        Process.exit(pid, "normal");
        
        // Test process spawning
        var newPid = Process.spawn(() -> {
            IO.puts("Hello from spawned process");
        });
        
        // Test process monitoring
        Process.monitor(newPid);
        Process.link(newPid);
        
        // Test process information
        var alive = Process.alive(pid);
        var info = Process.info(pid);
    }
    
    static function testRegistryExterns() {
        // Test Registry startup and registration
        var registrySpec = Registry.startLink(RegistryOptionsBuilder.unique("MyRegistry"));
        
        // Test process registration
        var registerResult = Registry.register("MyRegistry", "user:123", "user_data");
        
        // Test process lookup
        var lookupResult = Registry.lookup("MyRegistry", "user:123");
        
        // Test registry information
        var count = Registry.count("MyRegistry");
        var keys = Registry.keys("MyRegistry", Process.self());
    }
    
    static function testAgentExterns() {
        // Test Agent creation
        var agentResult = Agent.startLink(() -> 0);
        
        // Test Agent state operations
        var state = Agent.get(null, (count) -> count);
        Agent.update(null, (count) -> (count : Int) + 1);
        Agent.sendCast(null, (count) -> (count : Int) + 1);
        
        // Test Agent helpers
        var counterAgent = Agent.counterAgent(10);
        Agent.increment(null, 5);
        var currentCount = Agent.getCount(null);
        
        // Test map agent with specific type
        // Note: Map operations removed as Agent helpers for Map types
        // would need special handling in compiler
    }
    
    static function testIOExterns() {
        // Test basic IO operations
        IO.puts("Hello, World!");
        IO.write("Hello ");
        IO.inspect([1, 2, 3]);
        
        // Test input operations
        var input = IO.gets("Enter something: ");
        var char = IO.read(1);
        
        // Test IO helpers
        IO.println("Using helper function");
        IO.error("This is an error message");
        IO.debug("Debug value", "label");
        
        // Test colored output
        IO.redText("Error text");
        IO.greenText("Success text");
        IO.blueText("Info text");
        
        // Test format helpers
        var formatted = IO.formatInspect([1, 2, 3], "Array");
    }
    
    static function testFileExterns() {
        // Test file reading operations
        var readResult = File.read("test.txt");
        var content = File.readBang("test.txt");
        
        // Test file writing operations
        var writeResult = File.write("output.txt", "Hello, File!");
        File.writeBang("output2.txt", "Hello again!");
        
        // Test file information
        var statResult = File.stat("test.txt");
        var exists = File.exists("test.txt");
        var isFile = File.regular("test.txt");
        var isDir = File.dir("directory");
        
        // Test directory operations
        var mkdirResult = File.mkdir("new_directory");
        var lsResult = File.ls(".");
        
        // Test file operations
        var copyResult = File.copy("source.txt", "dest.txt");
        var renameResult = File.rename("old.txt", "new.txt");
        
        // Test helper functions
        var textContent = File.readText("text_file.txt");
        var writeSuccess = File.writeText("output.txt", "content");
        var lines = File.readLines("multi_line.txt");
        var dirCreated = File.createDir("new_dir", true);
    }
    
    static function testPathExterns() {
        // Test path joining operations
        var joined = Path.join(["home", "user", "documents"]);
        var joinedTwo = Path.joinTwo("/home", "user");
        
        // Test path information
        var basename = Path.basename("/home/user/file.txt");
        var dirname = Path.dirname("/home/user/file.txt");
        var extension = Path.extname("/home/user/file.txt");
        var rootname = Path.rootname("/home/user/file.txt");
        
        // Test path type checking
        var isAbsolute = Path.isAbsolute("/home/user");
        var pathType = Path.type("/home/user");
        
        // Test path normalization
        var expanded = Path.expand("~/documents");
        var relative = Path.relativeToCwd("/home/user/documents");
        
        // Test wildcard matching
        var matches = Path.wildcard("*.txt");
        
        // Test helper functions
        var filename = Path.getFilename("/home/user/file.txt");
        var filenameNoExt = Path.getFilenameWithoutExtension("/home/user/file.txt");
        var ext = Path.getExtension("/home/user/file.txt");
        var combined = Path.combinePaths(["home", "user", "file.txt"]);
    }
    
    static function testEnumExterns() {
        var testArray = [1, 2, 3, 4, 5];
        
        // Test basic enumeration
        var count = ElixirEnum.count(testArray);
        var isEmpty = ElixirEnum.empty(testArray);
        var contains = ElixirEnum.member(testArray, 3);
        
        // Test element access
        var first = ElixirEnum.at(testArray, 0);
        var found = ElixirEnum.find(testArray, (x) -> x > 3);
        
        // Test transformation
        var doubled = ElixirEnum.map(testArray, (x) -> x * 2);
        var filtered = ElixirEnum.filter(testArray, (x) -> x % 2 == 0);
        var reduced = ElixirEnum.reduce(testArray, 0, (acc, x) -> acc + x);
        
        // Test aggregation
        var sum = ElixirEnum.sum(testArray);
        var max = ElixirEnum.max(testArray);
        var min = ElixirEnum.min(testArray);
        
        // Test list operations
        var taken = ElixirEnum.take(testArray, 3);
        var dropped = ElixirEnum.drop(testArray, 2);
        var reversed = ElixirEnum.reverse(testArray);
        var sorted = ElixirEnum.sort(testArray);
        
        // Test helpers
        var size = ElixirEnum.size(testArray);
        var head = ElixirEnum.head(testArray);
        var tail = ElixirEnum.tail(testArray);
        var collected = ElixirEnum.collect(testArray, (x) -> Std.string(x));
    }
    
    static function testStringExterns() {
        var testString = "  Hello, World!  ";
        
        // Test string information
        var length = ElixirString.length(testString);
        var byteSize = ElixirString.byteSize(testString);
        var isValid = ElixirString.valid(testString);
        
        // Test case conversion
        var lower = ElixirString.downcase(testString);
        var upper = ElixirString.upcase(testString);
        var capitalized = ElixirString.capitalize(testString);
        
        // Test trimming and padding
        var trimmed = ElixirString.trim(testString);
        var leftTrimmed = ElixirString.trimLeading(testString);
        var padded = ElixirString.padLeading("hello", 10);
        
        // Test slicing
        var slice = ElixirString.slice(testString, 2, 5);
        var charAt = ElixirString.at(testString, 0);
        var first = ElixirString.first(testString);
        var last = ElixirString.last(testString);
        
        // Test searching
        var contains = ElixirString.contains(testString, "Hello");
        var startsWith = ElixirString.startsWith(testString, "  Hello");
        var endsWith = ElixirString.endsWith(testString, "!  ");
        
        // Test replacement
        var replaced = ElixirString.replace(testString, "World", "Elixir");
        var prefixReplaced = ElixirString.replacePrefix(testString, "  ", "");
        
        // Test splitting
        var split = ElixirString.split("a,b,c");
        var splitOn = ElixirString.splitOn("a,b,c", ",");
        var splitAt = ElixirString.splitAt(testString, 5);
        
        // Test conversion
        var toIntResult = ElixirString.toInteger("123");
        var toFloatResult = ElixirString.toFloat("123.45");
        
        // Test helpers
        var isEmpty = ElixirString.isEmpty("");
        var isBlank = ElixirString.isBlank("   ");
        var leftPadded = ElixirString.leftPad("test", 10, "0");
        var repeated = ElixirString.repeat("ha", 3);
    }
    
    static function testGenServerExterns() {
        // Test GenServer startup
        var startResult = GenServer.startLink("MyGenServer", "init_arg");
        
        // Test GenServer communication
        var serverRef: elixir.types.GenServerRef = null;
        var callResult = GenServer.call(serverRef, "get_state");
        GenServer.sendCast(serverRef, "update_state");
        
        // Test GenServer lifecycle
        GenServer.stop(serverRef);
        
        // Test process discovery  
        var pid = GenServer.whereis(serverRef);
        
        // Test GenServer helper constants
        var infinity = GenServer.infinity();
        var normal = GenServer.normal();
        var shutdown = GenServer.shutdown();
    }
}