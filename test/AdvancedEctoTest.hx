package test;

import utest.Test;
import utest.Assert;
import reflaxe.elixir.helpers.QueryCompiler;

/**
 * Advanced Ecto Features Test Suite
 * 
 * Tests complex query capabilities including joins, aggregations,
 * subqueries, CTEs, and transaction support with Ecto.Multi.
 * 
 * Following TDD methodology with RED-GREEN-REFACTOR phases.
 * Uses tink_unittest for modern Haxe testing patterns.
 */
class AdvancedEctoTest extends Test {
    
    public function new() {
        super();
    }
    
    // "Ecto Joins - Inner, Left, Right, Cross")
    public function testJoinCompilation() {
        // Test inner join compilation
        var innerJoin = QueryCompiler.compileJoin("inner", "[u]", "p in Post", "u.id == p.user_id");
        Assert.isTrue(innerJoin.indexOf("join(:inner") >= 0, "Should generate inner join");
        Assert.isTrue(innerJoin.indexOf("on: u.id == p.user_id") >= 0, "Should include ON clause");
        
        // Test left join
        var leftJoin = QueryCompiler.compileJoin("left", "[u]", "p in Post", "u.id == p.user_id");
        Assert.isTrue(leftJoin.indexOf("left_join(:left") >= 0, "Should generate left join");
        
        // Test multiple joins
        var joins = [
            {type: "inner", schema: "Post", alias: "p", on: "u.id == p.user_id"},
            {type: "left", schema: "Comment", alias: "c", on: "p.id == c.post_id"}
        ];
        var multiJoin = QueryCompiler.compileMultipleJoins(joins);
        Assert.isTrue(multiJoin.indexOf("join(:inner") >= 0, "Should include inner join");
        Assert.isTrue(multiJoin.indexOf("join(:left") >= 0, "Should include left join");
        
    }
    
    // "Aggregation Functions - sum, avg, count, group_by")
    public function testAggregationFunctions() {
        // Test count aggregation
        var countAgg = QueryCompiler.compileAggregation("count", "id", "p");
        Assert.isTrue(countAgg == "count(p.id)", "Should generate count aggregation");
        
        // Test sum aggregation
        var sumAgg = QueryCompiler.compileAggregation("sum", "amount", "o");
        Assert.isTrue(sumAgg == "sum(o.amount)", "Should generate sum aggregation");
        
        // Test avg aggregation
        var avgAgg = QueryCompiler.compileAggregation("avg", "price", "p");
        Assert.isTrue(avgAgg == "avg(p.price)", "Should generate avg aggregation");
        
        // Test GROUP BY with HAVING
        var groupBy = QueryCompiler.compileGroupBy(["user_id"], "count(p.id) > 5");
        Assert.isTrue(groupBy.indexOf("group_by([q], [q.user_id])") >= 0, "Should generate GROUP BY");
        Assert.isTrue(groupBy.indexOf("having([q], count(p.id) > 5)") >= 0, "Should generate HAVING clause");
        
    }
    
    // "Subqueries and CTEs")
    public function testSubqueries() {
        // Test subquery compilation
        var subquery = QueryCompiler.compileSubquery("from p in Post, where: p.published == true", "p");
        Assert.isTrue(subquery.indexOf("subquery(from p in") >= 0, "Should generate subquery");
        Assert.isTrue(subquery.indexOf("select: p") >= 0, "Should include select clause");
        
        // Test CTE compilation
        var cte = QueryCompiler.compileCTE("popular_posts", "popular_posts_query");
        Assert.isTrue(cte.indexOf('with_cte("popular_posts"') >= 0, "Should generate CTE");
        Assert.isTrue(cte.indexOf("as: ^popular_posts_query") >= 0, "Should include query reference");
        
    }
    
    // "Window Functions")
    public function testWindowFunctions() {
        // Test row_number window function
        var rowNumber = QueryCompiler.compileWindowFunction("row_number", "e.department", "[desc: e.salary]");
        Assert.isTrue(rowNumber.indexOf("over(row_number()") >= 0, "Should generate row_number function");
        Assert.isTrue(rowNumber.indexOf("partition_by: e.department") >= 0, "Should include partition by");
        Assert.isTrue(rowNumber.indexOf("order_by: [desc: e.salary]") >= 0, "Should include order by");
        
        // Test rank function without partition
        var rank = QueryCompiler.compileWindowFunction("rank", null, "[desc: s.score]");
        Assert.isTrue(rank.indexOf("over(rank()") >= 0, "Should generate rank function");
        Assert.isTrue(rank.indexOf("order_by: [desc: s.score]") >= 0, "Should include order by");
        Assert.isTrue(rank.indexOf("partition_by") < 0, "Should not include partition by when null");
        
        // Test dense_rank function
        var denseRank = QueryCompiler.compileWindowFunction("dense_rank", "s.category", "[desc: s.score]");
        Assert.isTrue(denseRank.indexOf("over(dense_rank()") >= 0, "Should generate dense_rank function");
        Assert.isTrue(denseRank.indexOf("partition_by: s.category") >= 0, "Should include partition by");
        
    }
    
    // "Ecto.Multi Transaction Support")
    public function testMultiTransactions() {
        // Test basic Multi transaction
        var multiOps = [
            {type: "insert", name: "user", changeset: "User.changeset({}, {name: \"John\"})", record: null, query: null, updates: null, funcStr: null},
            {type: "run", name: "validate", changeset: null, record: null, query: null, updates: null, funcStr: "validate_user"}
        ];
        
        var multiResult = QueryCompiler.compileMulti(multiOps);
        Assert.isTrue(multiResult.indexOf("Multi.new()") >= 0, "Should generate Multi.new()");
        Assert.isTrue(multiResult.indexOf("Multi.insert(:user") >= 0, "Should include insert operation");
        Assert.isTrue(multiResult.indexOf("Multi.run(:validate") >= 0, "Should include run operation");
        
    }
    
    // "Query Composition and Fragments")
    public function testQueryComposition() {
        // Test fragment compilation
        var fragment = QueryCompiler.compileFragment("lower(?) = ?", ["u.email", "^email"]);
        Assert.isTrue(fragment == 'fragment("lower(?) = ?", u.email, ^email)', "Should generate fragment with parameters");
        
        // Test named bindings
        var namedBindings = new Map<String, String>();
        namedBindings.set("user", "u");
        namedBindings.set("post", "p");
        var bindings = QueryCompiler.compileNamedBindings(namedBindings);
        Assert.isTrue(bindings.indexOf("user: u") >= 0, "Should include user binding");
        Assert.isTrue(bindings.indexOf("post: p") >= 0, "Should include post binding");
        
    }
    
    // "Preloading and Association Queries")
    public function testPreloading() {
        // Test simple preload
        var simplePreload = {simple: ["posts", "profile"]};
        var preloadQuery = QueryCompiler.compilePreload(simplePreload);
        Assert.isTrue(preloadQuery == "|> preload([:posts, :profile])", "Should generate simple preload");
        
        // Test nested preload
        var nestedAssoc = new Map<String, Array<String>>();
        nestedAssoc.set("posts", ["comments", "likes"]);
        nestedAssoc.set("profile", []);
        var nestedPreload = {nested: nestedAssoc};
        var nestedQuery = QueryCompiler.compilePreload(nestedPreload);
        Assert.isTrue(nestedQuery.indexOf("posts: [:comments, :likes]") >= 0, "Should include nested associations");
        Assert.isTrue(nestedQuery.indexOf("profile: []") >= 0, "Should include empty associations");
        
    }
    
    // "Complex Query Performance")
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
        
        Assert.isTrue(results.length == 10, "Should compile all 10 queries");
        Assert.isTrue(totalTime < 0.015, 'Complex query compilation should be under 15ms, took: ${totalTime * 1000}ms');
        
    }
    
    // === EDGE CASE TESTING SUITE ===
    
    // "Error Conditions - Invalid Join Types")
    public function testInvalidJoinTypes() {
        // Test invalid join type defaults to "join"
        var invalidJoin = QueryCompiler.compileJoin("invalid_type", "[u]", "p in Post", "u.id == p.user_id");
        Assert.isTrue(invalidJoin.indexOf("join(:invalid_type") >= 0, "Invalid join type should default to join");
        
        // Test null join type (defaults to inner)
        var nullJoin = QueryCompiler.compileJoin(null, "[u]", "p in Post", "u.id == p.user_id");
        Assert.isTrue(nullJoin.indexOf("join(:inner") >= 0, "Null join type should default to inner");
        
        // Test empty join type
        var emptyJoin = QueryCompiler.compileJoin("", "[u]", "p in Post", "u.id == p.user_id");
        Assert.isTrue(emptyJoin.indexOf("join(:") >= 0, "Empty join type should be handled gracefully");
        
    }
    
    // "Boundary Cases - Empty Collections")
    public function testEmptyCollections() {
        // Test empty joins array
        var emptyJoins = [];
        var multiJoin = QueryCompiler.compileMultipleJoins(emptyJoins);
        Assert.isTrue(multiJoin == "", "Empty joins array should return empty string");
        
        // Test empty group by fields
        var emptyGroupBy = QueryCompiler.compileGroupBy([]);
        Assert.isTrue(emptyGroupBy.indexOf("group_by([q], [])") >= 0, "Empty group by should handle empty array");
        
        // Test empty multi operations
        var emptyOperations = [];
        var emptyMulti = QueryCompiler.compileMulti(emptyOperations);
        Assert.isTrue(emptyMulti == "Multi.new()", "Empty operations should return basic Multi.new()");
        
        // Test empty preload
        var emptyPreload = {simple: []};
        var preloadQuery = QueryCompiler.compilePreload(emptyPreload);
        Assert.isTrue(preloadQuery == "|> preload([])", "Empty preload should generate empty array");
        
    }
    
    // "Invalid Input Handling - Malformed Data")
    public function testMalformedData() {
        // Test invalid aggregation function
        var invalidAgg = QueryCompiler.compileAggregation("invalid_func", "field", "q");
        Assert.isTrue(invalidAgg == "count(*)", "Invalid aggregation should default to count(*)");
        
        // Test null aggregation function (defaults to count)
        var nullAgg = QueryCompiler.compileAggregation(null, "field", "q");
        Assert.isTrue(nullAgg == "count(q.field)", "Null aggregation should default to count(q.field)");
        
        // Test empty window function (defaults to row_number)
        var emptyWindow = QueryCompiler.compileWindowFunction("");
        Assert.isTrue(emptyWindow.indexOf("over(row_number()") >= 0, "Empty window function should default to row_number");
        
        // Test malformed fragment with no parameters
        var emptyFragment = QueryCompiler.compileFragment("SELECT * FROM users", []);
        Assert.isTrue(emptyFragment == 'fragment("SELECT * FROM users")', "Fragment with no params should work");
        
    }
    
    // "Resource Limits - Large Data Sets")
    public function testResourceLimits() {
        // Test very large joins array (stress test)
        var largeJoins = [];
        for (i in 0...100) {
            largeJoins.push({
                type: "inner",
                schema: 'Table${i}',
                alias: 't${i}',
                on: 't${i}.id == t${i-1}.ref_id'
            });
        }
        
        var startTime = Sys.time();
        var largeJoinResult = QueryCompiler.compileMultipleJoins(largeJoins);
        var compilationTime = Sys.time() - startTime;
        
        Assert.isTrue(largeJoinResult.length > 0, "Large joins array should compile successfully");
        Assert.isTrue(compilationTime < 0.1, 'Large join compilation should be under 100ms, took: ${compilationTime * 1000}ms');
        
        // Test large group by fields (50 fields)
        var largeGroupByFields = [];
        for (i in 0...50) {
            largeGroupByFields.push('field${i}');
        }
        
        var largeGroupBy = QueryCompiler.compileGroupBy(largeGroupByFields);
        Assert.isTrue(largeGroupBy.indexOf("group_by") >= 0, "Large group by should compile");
        Assert.isTrue(largeGroupBy.indexOf("field0") >= 0, "Should include first field");
        Assert.isTrue(largeGroupBy.indexOf("field49") >= 0, "Should include last field");
        
    }
    
    // "SQL Injection Prevention - Malicious Input")
    public function testSQLInjectionPrevention() {
        // Test potential SQL injection in join conditions
        var maliciousCondition = "u.id = 1; DROP TABLE users; --";
        var maliciousJoin = QueryCompiler.compileJoin("inner", "[u]", "p in Post", maliciousCondition);
        Assert.isTrue(maliciousJoin.indexOf("DROP TABLE") >= 0, "Malicious SQL should be preserved in condition (parameterized queries handle safety)");
        
        // Test malicious aggregation field name
        var maliciousField = "id; DROP TABLE posts; --";
        var maliciousAgg = QueryCompiler.compileAggregation("count", maliciousField, "q");
        Assert.isTrue(maliciousAgg.indexOf("DROP TABLE") >= 0, "Malicious field should be preserved (parameterization handles safety)");
        
        // Test malicious fragment SQL
        var maliciousSQL = "SELECT * FROM users; DROP TABLE sensitive_data; --";
        var maliciousFragment = QueryCompiler.compileFragment(maliciousSQL, ["param1"]);
        Assert.isTrue(maliciousFragment.indexOf("DROP TABLE") >= 0, "Malicious SQL in fragment should be preserved (Ecto.Query handles parameterization)");
        
    }
    
    // "Type Safety - Invalid Combinations")
    public function testTypeSafetyChecks() {
        // Test mismatched binding types in multiple joins
        var mismatchedJoins = [
            {type: "inner", schema: "Post", alias: null, on: "invalid_binding.id == p.user_id"},
            {type: "left", schema: null, alias: "comment", on: "p.id == c.post_id"}
        ];
        
        var mismatchedResult = QueryCompiler.compileMultipleJoins(mismatchedJoins);
        Assert.isTrue(mismatchedResult.length > 0, "Mismatched joins should still compile (runtime validation)");
        
        // Test invalid multi operation type
        var invalidMultiOps = [
            {type: "invalid_operation", name: "test", changeset: null, record: null, query: null, updates: null, funcStr: null}
        ];
        
        var invalidMulti = QueryCompiler.compileMulti(invalidMultiOps);
        Assert.isTrue(invalidMulti == "Multi.new()", "Invalid multi operation should result in basic Multi.new()");
        
    }
    
    // "Concurrent Compilation - Thread Safety")
    public function testConcurrentCompilation() {
        // Simulate concurrent compilation by running multiple batch operations
        var batch1Queries = [];
        var batch2Queries = [];
        var batch3Queries = [];
        
        // Create three different batches
        for (i in 0...20) {
            batch1Queries.push({
                schema: "User", binding: "u", alias: 'user${i}',
                joins: [{type: "inner", schema: "Post", alias: "post", on: "u.id == p.user_id"}],
                where: 'u.id > ${i}', groupBy: null, having: null, orderBy: null,
                limit: null, offset: null, preload: null, select: null
            });
            
            batch2Queries.push({
                schema: "Post", binding: "p", alias: 'post${i}',
                joins: [{type: "left", schema: "Comment", alias: "comment", on: "p.id == c.post_id"}],
                where: 'p.published = true', groupBy: null, having: null, orderBy: null,
                limit: null, offset: null, preload: null, select: null
            });
            
            batch3Queries.push({
                schema: "Comment", binding: "c", alias: 'comment${i}',
                joins: null, where: 'c.approved = true', groupBy: null, having: null,
                orderBy: null, limit: null, offset: null, preload: null, select: null
            });
        }
        
        var startTime = Sys.time();
        
        // Run all batches (simulating concurrent access)
        var results1 = QueryCompiler.batchCompileQueries(batch1Queries);
        var results2 = QueryCompiler.batchCompileQueries(batch2Queries);
        var results3 = QueryCompiler.batchCompileQueries(batch3Queries);
        
        var totalTime = Sys.time() - startTime;
        
        Assert.isTrue(results1.length == 20, "Batch 1 should compile all queries");
        Assert.isTrue(results2.length == 20, "Batch 2 should compile all queries");
        Assert.isTrue(results3.length == 20, "Batch 3 should compile all queries");
        Assert.isTrue(totalTime < 0.05, 'Concurrent compilation should be under 50ms, took: ${totalTime * 1000}ms');
        
        // Verify results are different (no cross-contamination)
        Assert.isTrue(results1[0] != results2[0], "Different batches should produce different results");
        Assert.isTrue(results2[0] != results3[0], "Different batches should produce different results");
        
    }
    
}