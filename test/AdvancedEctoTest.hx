package;

import reflaxe.elixir.helpers.QueryCompiler;

/**
 * Advanced Ecto Features Test Suite
 * 
 * Tests complex query capabilities including joins, aggregations,
 * subqueries, CTEs, and transaction support with Ecto.Multi.
 * 
 * Following TDD methodology with RED-GREEN-REFACTOR phases.
 */
class AdvancedEctoTest {
    
    static var testsRun = 0;
    static var testsPassed = 0;
    static var testsFailed = 0;
    
    public function new() {}
    
    static function assert(condition: Bool, message: String): Void {
        testsRun++;
        if (condition) {
            testsPassed++;
            trace("  ✅ " + message);
        } else {
            testsFailed++;
            trace("  ❌ " + message);
        }
    }
    
    @:describe("Ecto Joins - Inner, Left, Right, Cross")
    public function testJoinCompilation() {
        // Test inner join compilation
        var innerJoin = QueryCompiler.compileJoin("inner", "[u]", "p in Post", "u.id == p.user_id");
        asserts.assert(innerJoin.indexOf("join(:inner") >= 0, "Should generate inner join");
        asserts.assert(innerJoin.indexOf("on: u.id == p.user_id") >= 0, "Should include ON clause");
        
        // Test left join
        var leftJoin = QueryCompiler.compileJoin("left", "[u]", "p in Post", "u.id == p.user_id");
        asserts.assert(leftJoin.indexOf("left_join(:left") >= 0, "Should generate left join");
        
        // Test multiple joins
        var joins = [
            {type: "inner", schema: "Post", alias: "p", on: "u.id == p.user_id"},
            {type: "left", schema: "Comment", alias: "c", on: "p.id == c.post_id"}
        ];
        var multiJoin = QueryCompiler.compileMultipleJoins(joins);
        asserts.assert(multiJoin.indexOf("join(:inner") >= 0, "Should include inner join");
        asserts.assert(multiJoin.indexOf("join(:left") >= 0, "Should include left join");
        
        return asserts.done();
    }
    
    @:describe("Aggregation Functions - sum, avg, count, group_by")
    public function testAggregationFunctions() {
        // Test count aggregation
        var countAgg = QueryCompiler.compileAggregation("count", "id", "p");
        asserts.assert(countAgg == "count(p.id)", "Should generate count aggregation");
        
        // Test sum aggregation
        var sumAgg = QueryCompiler.compileAggregation("sum", "amount", "o");
        asserts.assert(sumAgg == "sum(o.amount)", "Should generate sum aggregation");
        
        // Test avg aggregation
        var avgAgg = QueryCompiler.compileAggregation("avg", "price", "p");
        asserts.assert(avgAgg == "avg(p.price)", "Should generate avg aggregation");
        
        // Test GROUP BY with HAVING
        var groupBy = QueryCompiler.compileGroupBy(["user_id"], "count(p.id) > 5");
        asserts.assert(groupBy.indexOf("group_by([q], [q.user_id])") >= 0, "Should generate GROUP BY");
        asserts.assert(groupBy.indexOf("having([q], count(p.id) > 5)") >= 0, "Should generate HAVING clause");
        
        return asserts.done();
    }
    
    @:describe("Subqueries and CTEs")
    public function testSubqueries() {
        // Test subquery compilation
        var subquery = QueryCompiler.compileSubquery("from p in Post, where: p.published == true", "p");
        asserts.assert(subquery.indexOf("subquery(from p in") >= 0, "Should generate subquery");
        asserts.assert(subquery.indexOf("select: p") >= 0, "Should include select clause");
        
        // Test CTE compilation
        var cte = QueryCompiler.compileCTE("popular_posts", "popular_posts_query");
        asserts.assert(cte.indexOf('with_cte("popular_posts"') >= 0, "Should generate CTE");
        asserts.assert(cte.indexOf("as: ^popular_posts_query") >= 0, "Should include query reference");
        
        return asserts.done();
    }
    
    @:describe("Window Functions")
    public function testWindowFunctions() {
        // Test row_number window function
        var rowNumber = QueryCompiler.compileWindowFunction("row_number", "e.department", "[desc: e.salary]");
        asserts.assert(rowNumber.indexOf("over(row_number()") >= 0, "Should generate row_number function");
        asserts.assert(rowNumber.indexOf("partition_by: e.department") >= 0, "Should include partition by");
        asserts.assert(rowNumber.indexOf("order_by: [desc: e.salary]") >= 0, "Should include order by");
        
        // Test rank function without partition
        var rank = QueryCompiler.compileWindowFunction("rank", null, "[desc: s.score]");
        asserts.assert(rank.indexOf("over(rank()") >= 0, "Should generate rank function");
        asserts.assert(rank.indexOf("order_by: [desc: s.score]") >= 0, "Should include order by");
        asserts.assert(rank.indexOf("partition_by") < 0, "Should not include partition by when null");
        
        // Test dense_rank function
        var denseRank = QueryCompiler.compileWindowFunction("dense_rank", "s.category", "[desc: s.score]");
        asserts.assert(denseRank.indexOf("over(dense_rank()") >= 0, "Should generate dense_rank function");
        asserts.assert(denseRank.indexOf("partition_by: s.category") >= 0, "Should include partition by");
        
        return asserts.done();
    }
    
    @:describe("Ecto.Multi Transaction Support")
    public function testMultiTransactions() {
        // Test basic Multi transaction
        var multiOps = [
            {type: "insert", name: "user", changeset: "User.changeset({}, {name: \"John\"})"},
            {type: "run", name: "validate", funcStr: "validate_user"}
        ];
        
        var multiResult = QueryCompiler.compileMulti(multiOps);
        asserts.assert(multiResult.indexOf("Multi.new()") >= 0, "Should generate Multi.new()");
        asserts.assert(multiResult.indexOf("Multi.insert(:user") >= 0, "Should include insert operation");
        asserts.assert(multiResult.indexOf("Multi.run(:validate") >= 0, "Should include run operation");
        
        return asserts.done();
    }
    
    @:describe("Query Composition and Fragments")
    public function testQueryComposition() {
        // Test fragment compilation
        var fragment = QueryCompiler.compileFragment("lower(?) = ?", ["u.email", "^email"]);
        asserts.assert(fragment == 'fragment("lower(?) = ?", u.email, ^email)', "Should generate fragment with parameters");
        
        // Test named bindings
        var namedBindings = new Map<String, String>();
        namedBindings.set("user", "u");
        namedBindings.set("post", "p");
        var bindings = QueryCompiler.compileNamedBindings(namedBindings);
        asserts.assert(bindings.indexOf("user: u") >= 0, "Should include user binding");
        asserts.assert(bindings.indexOf("post: p") >= 0, "Should include post binding");
        
        return asserts.done();
    }
    
    @:describe("Preloading and Association Queries")
    public function testPreloading() {
        // Test simple preload
        var simplePreload = {simple: ["posts", "profile"]};
        var preloadQuery = QueryCompiler.compilePreload(simplePreload);
        asserts.assert(preloadQuery == "|> preload([:posts, :profile])", "Should generate simple preload");
        
        // Test nested preload
        var nestedAssoc = new Map<String, Array<String>>();
        nestedAssoc.set("posts", ["comments", "likes"]);
        nestedAssoc.set("profile", []);
        var nestedPreload = {nested: nestedAssoc};
        var nestedQuery = QueryCompiler.compilePreload(nestedPreload);
        asserts.assert(nestedQuery.indexOf("posts: [:comments, :likes]") >= 0, "Should include nested associations");
        asserts.assert(nestedQuery.indexOf("profile: []") >= 0, "Should include empty associations");
        
        return asserts.done();
    }
    
    @:describe("Complex Query Performance")
    public function testComplexQueryPerformance() {
        var startTime = Sys.time();
        
        // Create complex query definitions
        var queries = [];
        for (i in 0...10) {
            var complexQuery = {
                schema: "User",
                binding: "u",
                alias: "user",
                joins: [
                    {type: "inner", schema: "Post", alias: "post", on: "u.id == p.user_id"},
                    {type: "left", schema: "Comment", alias: "comment", on: "p.id == c.post_id"}
                ],
                where: "u.active == true",
                groupBy: ["id"],
                having: "count(p.id) > 5",
                orderBy: [{field: "created_at", direction: "desc"}],
                limit: 100,
                offset: i * 100,
                select: "{user_name: u.name, post_count: count(p.id)}"
            };
            queries.push(complexQuery);
        }
        
        // Batch compile all queries
        var results = QueryCompiler.batchCompileQueries(queries);
        var totalTime = Sys.time() - startTime;
        
        asserts.assert(results.length == 10, "Should compile all 10 queries");
        asserts.assert(totalTime < 0.015, 'Complex query compilation should be under 15ms, took: ${totalTime * 1000}ms');
        
        return asserts.done();
    }
    
    public static function main() {
        trace("🧪 Starting Advanced Ecto Features Tests...");
        
        var test = new AdvancedEctoTest();
        test.testJoinCompilation();
        test.testAggregationFunctions();
        test.testSubqueries();
        test.testWindowFunctions();
        test.testMultiTransactions();
        test.testQueryComposition();
        test.testPreloading();
        test.testComplexQueryPerformance();
        
        trace("🎉 All Advanced Ecto tests completed successfully!");
    }
}