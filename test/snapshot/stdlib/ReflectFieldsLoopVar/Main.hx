/**
 * Test for idiomatic translation of Reflect.fields loops
 * 
 * This test validates two critical aspects:
 * 1. Loops over Reflect.fields() should generate idiomatic Elixir for comprehensions
 *    instead of complex Enum.reduce_while patterns
 * 2. Variable declarations inside loop bodies must be properly preserved
 * 
 * The desired output is a clean Elixir for comprehension:
 * ```elixir
 * for user_id <- Map.keys(all_users) do
 *   entry = Map.get(all_users, String.to_atom(user_id))
 *   if length(entry.metas) > 0 do
 *     meta = hd(entry.metas)  # This variable declaration must be preserved!
 *     if meta.editing_todo_id == 42 do
 *       # Process the meta
 *     end
 *   end
 * end
 * ```
 * 
 * NOT the complex Enum.reduce_while pattern currently generated.
 */
class Main {
    static function main() {
        trace("Testing Reflect.fields loop variable declarations...");
        
        // Create a dynamic object similar to Presence data
        var allUsers: Dynamic = {
            "user_123": {
                metas: [
                    {
                        onlineAt: 1234567890,
                        userName: "Alice",
                        editingTodoId: 42
                    }
                ]
            },
            "user_456": {
                metas: [
                    {
                        onlineAt: 1234567891,
                        userName: "Bob", 
                        editingTodoId: null
                    }
                ]
            }
        };
        
        // Test case 1: Basic for loop over Reflect.fields with variable declarations
        // This should generate a simple Elixir for comprehension, NOT Enum.reduce_while
        var editingUsers = [];
        for (userId in Reflect.fields(allUsers)) {
            var entry = Reflect.field(allUsers, userId);
            if (entry.metas.length > 0) {
                var meta = entry.metas[0];  // Critical: This variable declaration must be preserved
                if (meta.editingTodoId == 42) {
                    editingUsers.push(meta);
                }
            }
        }
        
        trace("Found " + editingUsers.length + " users editing todo 42");
        
        // Test case 2: Multiple variable declarations
        var userNames = [];
        for (userId in Reflect.fields(allUsers)) {
            var entry = Reflect.field(allUsers, userId);
            var metaList = entry.metas;  // First variable
            if (metaList.length > 0) {
                var firstMeta = metaList[0];  // Second variable
                var name = firstMeta.userName;  // Third variable
                userNames.push(name);
            }
        }
        
        trace("User names: " + userNames.join(", "));
        
        // Test case 3: Nested loops with variables
        var allMetadata = [];
        for (userId in Reflect.fields(allUsers)) {
            var userEntry = Reflect.field(allUsers, userId);
            for (i in 0...userEntry.metas.length) {
                var metaItem = userEntry.metas[i];
                var processedMeta = {
                    id: userId,
                    index: i,
                    data: metaItem
                };
                allMetadata.push(processedMeta);
            }
        }
        
        trace("Total metadata entries: " + allMetadata.length);
        
        // Test case 4: Simple iteration without collecting results
        // This should generate Enum.each, not reduce_while
        trace("\nTest 4: Simple iteration");
        for (userId in Reflect.fields(allUsers)) {
            var entry = Reflect.field(allUsers, userId);
            trace("Processing user: " + userId);
        }
        
        // Test case 5: Building a new map from iteration
        // This should use for comprehension with :into option
        trace("\nTest 5: Building a map");
        var userNameMap: Dynamic = {};
        for (userId in Reflect.fields(allUsers)) {
            var entry = Reflect.field(allUsers, userId);
            if (entry.metas.length > 0) {
                var meta = entry.metas[0];
                Reflect.setField(userNameMap, userId, meta.userName);
            }
        }
        trace("User name map size: " + Reflect.fields(userNameMap).length);
        
        trace("\nAll tests completed!");
    }
}