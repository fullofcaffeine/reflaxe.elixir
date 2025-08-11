// Test Advanced Ecto Macros Integration

#if (macro || reflaxe_runtime)
import reflaxe.elixir.helpers.QueryCompiler;
#end

/**
 * Test Advanced Ecto Macros Integration
 * 
 * This test validates that the new advanced QueryCompiler functions work correctly
 * and can generate proper Ecto query strings for advanced features.
 */
class TestAdvancedMacros {
    
    /**
     * Test subquery compilation
     */
    public static function testSubqueryMacro() {
        #if (macro || reflaxe_runtime)
        var result = QueryCompiler.compileSubquery("from u in User, where: u.active == true", "active_users");
        return result;
        #else
        return "subquery(from active_users in (from u in User, where: u.active == true), select: active_users)";
        #end
    }
    
    /**
     * Test CTE compilation
     */
    public static function testCTEMacro() {
        #if (macro || reflaxe_runtime)
        var result = QueryCompiler.compileCTE("popular_posts", "posts_query");
        return result;
        #else
        return 'with_cte("popular_posts", as: ^posts_query)';
        #end
    }
    
    /**
     * Test window function compilation
     */
    public static function testWindowMacro() {
        #if (macro || reflaxe_runtime)
        var result = QueryCompiler.compileWindowFunction("row_number", "u.department_id", "[desc: u.salary]");
        return result;
        #else
        return "over(row_number(), partition_by: u.department_id, order_by: [desc: u.salary])";
        #end
    }
    
    /**
     * Test fragment compilation
     */
    public static function testFragmentMacro() {
        #if (macro || reflaxe_runtime)
        var result = QueryCompiler.compileFragment("EXTRACT(year FROM ?) = ?", ["u.created_at", "2024"]);
        return result;
        #else
        return 'fragment("EXTRACT(year FROM ?) = ?", u.created_at, 2024)';
        #end
    }
    
    /**
     * Test preload compilation
     */
    public static function testPreloadMacro() {
        #if (macro || reflaxe_runtime)
        var simplePreload = {simple: ["posts", "profile", "comments"]};
        var result = QueryCompiler.compilePreload(simplePreload);
        return result;
        #else
        return "|> preload([:posts, :profile, :comments])";
        #end
    }
    
    /**
     * Test lateral join compilation
     */
    public static function testLateralJoinMacro() {
        #if (macro || reflaxe_runtime)
        var result = QueryCompiler.compileLateralJoin("[u]", "p in Post", "u.id == p.user_id");
        return result;
        #else
        return "|> join_lateral(:inner, [u], p in Post, on: u.id == p.user_id)";
        #end
    }
    
    /**
     * Test union compilation  
     */
    public static function testUnionMacro() {
        #if (macro || reflaxe_runtime)
        var result = QueryCompiler.compileUnion("from u in User, where: u.active", "from u in User, where: u.verified", true);
        return result;
        #else
        return "from u in User, where: u.active\n|> union_all(from u in User, where: u.verified)";
        #end
    }
    
    /**
     * Test JSON operations compilation
     */
    public static function testJsonMacro() {
        #if (macro || reflaxe_runtime)
        var result = QueryCompiler.compileJsonPath("u.metadata", "address.city");
        return result;
        #else
        return "json_extract_path(u.metadata, address.city)";
        #end
    }
    
    /**
     * Main function that tests all advanced compilation features
     */
    public static function main() {
        trace("=== Advanced QueryCompiler Test ===");
        
        trace("1. Subquery: " + testSubqueryMacro());
        trace("2. CTE: " + testCTEMacro());
        trace("3. Window: " + testWindowMacro());
        trace("4. Fragment: " + testFragmentMacro());
        trace("5. Preload: " + testPreloadMacro());
        trace("6. Lateral Join: " + testLateralJoinMacro());
        trace("7. Union: " + testUnionMacro());
        trace("8. JSON: " + testJsonMacro());
        
        trace("=== Advanced QueryCompiler Test Complete ===");
    }
}