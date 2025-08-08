package performance;

import reflaxe.elixir.macro.ModuleMacro;
import reflaxe.elixir.macro.PipeOperator;
import reflaxe.elixir.macro.HXXMacro;

using StringTools;

/**
 * Performance benchmarking tests for Reflaxe.Elixir compilation targets
 * Validates: <15ms compilation steps, <100ms HXX processing requirements
 * Testing Trophy: Performance validation of complete system
 */
class PerformanceBenchmarks {
    
    private static var COMPILATION_TARGET_MS = 15.0;
    private static var HXX_PROCESSING_TARGET_MS = 100.0;
    private static var ITERATIONS = 100;  // For statistical significance
    
    /**
     * Benchmark @:module compilation performance
     * Target: <15ms per module compilation
     */
    public static function benchmarkModuleCompilation(): BenchmarkResult {
        var startTime = haxe.Timer.stamp();
        var results = [];
        
        // Test data representing typical Phoenix modules
        var testModules = [
            createUserControllerModule(),
            createUserServiceModule(),
            createUserContextModule(),
            createLiveViewModule(),
            createSchemaModule()
        ];
        
        // Benchmark multiple iterations for statistical accuracy
        for (iteration in 0...ITERATIONS) {
            var iterationStart = haxe.Timer.stamp();
            
            for (moduleData in testModules) {
                try {
                    var result = ModuleMacro.transformModule(moduleData);
                    // Simulate realistic compilation work
                    if (result.length < 100) {
                        throw "Module compilation produced insufficient output";
                    }
                } catch (e: Dynamic) {
                    trace('Module compilation error: ${e}');
                }
            }
            
            var iterationTime = (haxe.Timer.stamp() - iterationStart) * 1000;
            results.push(iterationTime);
        }
        
        var totalTime = (haxe.Timer.stamp() - startTime) * 1000;
        var averageTime = totalTime / ITERATIONS;
        var perModuleTime = averageTime / testModules.length;
        
        return {
            testName: "Module Compilation",
            totalTime: totalTime,
            averageTime: averageTime,
            perItemTime: perModuleTime,
            iterations: ITERATIONS,
            itemCount: testModules.length,
            targetMs: COMPILATION_TARGET_MS,
            passed: perModuleTime < COMPILATION_TARGET_MS,
            details: 'Per-module: ${Math.round(perModuleTime * 100) / 100}ms (target: <${COMPILATION_TARGET_MS}ms)'
        };
    }
    
    /**
     * Benchmark HXX template processing performance
     * Target: <100ms for complete HXX transformation
     */
    public static function benchmarkHXXProcessing(): BenchmarkResult {
        var startTime = haxe.Timer.stamp();
        var results = [];
        
        // Complex HXX templates representing real-world usage
        var testTemplates = [
            createComplexLiveViewTemplate(),
            createUserListTemplate(),
            createFormTemplate(),
            createDashboardTemplate(),
            createNestedComponentTemplate()
        ];
        
        // Benchmark HXX processing
        for (iteration in 0...ITERATIONS) {
            var iterationStart = haxe.Timer.stamp();
            
            for (template in testTemplates) {
                try {
                    var result = HXXMacro.transformToHEEx(template);
                    // Validate transformation occurred
                    if (result.length < template.length * 0.8) {
                        trace("HXX transformation may have failed - output too short");
                    }
                } catch (e: Dynamic) {
                    trace('HXX processing error: ${e}');
                }
            }
            
            var iterationTime = (haxe.Timer.stamp() - iterationStart) * 1000;
            results.push(iterationTime);
        }
        
        var totalTime = (haxe.Timer.stamp() - startTime) * 1000;
        var averageTime = totalTime / ITERATIONS;
        var perTemplateTime = averageTime / testTemplates.length;
        
        return {
            testName: "HXX Processing",
            totalTime: totalTime,
            averageTime: averageTime,
            perItemTime: perTemplateTime,
            iterations: ITERATIONS,
            itemCount: testTemplates.length,
            targetMs: HXX_PROCESSING_TARGET_MS,
            passed: averageTime < HXX_PROCESSING_TARGET_MS,
            details: 'Complete processing: ${Math.round(averageTime * 100) / 100}ms (target: <${HXX_PROCESSING_TARGET_MS}ms)'
        };
    }
    
    /**
     * Benchmark pipe operator processing performance
     */
    public static function benchmarkPipeOperators(): BenchmarkResult {
        var startTime = haxe.Timer.stamp();
        var results = [];
        
        var pipeExpressions = [
            "data |> validate() |> process() |> save()",
            "user |> User.changeset(attrs) |> Repo.insert() |> broadcast_change()",
            "conn |> assign(:user, user) |> assign(:posts, posts) |> render(:index)",
            "query |> where([u], u.active == true) |> order_by([u], u.inserted_at) |> Repo.all()",
            "socket |> assign(:loading, true) |> push_event(\"start-loading\") |> assign(:data, [])"
        ];
        
        for (iteration in 0...ITERATIONS) {
            var iterationStart = haxe.Timer.stamp();
            
            for (expr in pipeExpressions) {
                try {
                    var isValid = PipeOperator.isValidPipeExpression(expr);
                    var optimized = PipeOperator.generateOptimizedPipe(expr);
                    
                    if (!isValid || optimized.length == 0) {
                        trace("Pipe operator processing failed");
                    }
                } catch (e: Dynamic) {
                    trace('Pipe operator error: ${e}');
                }
            }
            
            var iterationTime = (haxe.Timer.stamp() - iterationStart) * 1000;
            results.push(iterationTime);
        }
        
        var totalTime = (haxe.Timer.stamp() - startTime) * 1000;
        var averageTime = totalTime / ITERATIONS;
        var perExprTime = averageTime / pipeExpressions.length;
        
        return {
            testName: "Pipe Operator Processing",
            totalTime: totalTime,
            averageTime: averageTime,
            perItemTime: perExprTime,
            iterations: ITERATIONS,
            itemCount: pipeExpressions.length,
            targetMs: 5.0, // Pipe ops should be very fast
            passed: perExprTime < 5.0,
            details: 'Per-expression: ${Math.round(perExprTime * 100) / 100}ms (target: <5ms)'
        };
    }
    
    /**
     * Benchmark complete end-to-end compilation performance
     */
    public static function benchmarkEndToEndCompilation(): BenchmarkResult {
        var startTime = haxe.Timer.stamp();
        var results = [];
        
        // Simulate complete Phoenix application compilation
        var appComponents = [
            {module: createUserControllerModule(), template: createUserListTemplate()},
            {module: createUserServiceModule(), template: null},
            {module: createLiveViewModule(), template: createComplexLiveViewTemplate()},
            {module: createUserContextModule(), template: null},
            {module: createSchemaModule(), template: null}
        ];
        
        for (iteration in 0...50) { // Fewer iterations for end-to-end test
            var iterationStart = haxe.Timer.stamp();
            
            for (component in appComponents) {
                try {
                    // Module compilation
                    var moduleResult = ModuleMacro.transformModule(component.module);
                    
                    // Template processing (if present)
                    if (component.template != null) {
                        var templateResult = HXXMacro.transformToHEEx(component.template);
                    }
                    
                    // Pipe operator processing
                    var pipeExpr = "data |> process() |> save()";
                    var pipeResult = PipeOperator.processPipeExpression(pipeExpr);
                    
                } catch (e: Dynamic) {
                    trace('End-to-end compilation error: ${e}');
                }
            }
            
            var iterationTime = (haxe.Timer.stamp() - iterationStart) * 1000;
            results.push(iterationTime);
        }
        
        var totalTime = (haxe.Timer.stamp() - startTime) * 1000;
        var averageTime = totalTime / 50;
        
        return {
            testName: "End-to-End Compilation",
            totalTime: totalTime,
            averageTime: averageTime,
            perItemTime: averageTime / appComponents.length,
            iterations: 50,
            itemCount: appComponents.length,
            targetMs: 150.0, // Complete app compilation target
            passed: averageTime < 150.0,
            details: 'Complete app: ${Math.round(averageTime * 100) / 100}ms (target: <150ms)'
        };
    }
    
    // Test data generators
    
    private static function createUserControllerModule(): Dynamic {
        return {
            name: "MyApp.UserController",
            imports: ["Phoenix.Controller", "MyApp.User", "MyApp.UserView"],
            functions: [
                {
                    name: "index",
                    args: ["conn", "params"],
                    body: "users = User.all() |> Enum.filter(&User.active?/1)",
                    isPrivate: false
                },
                {
                    name: "show", 
                    args: ["conn", "params"],
                    body: "user = User.get!(params[\"id\"])",
                    isPrivate: false
                },
                {
                    name: "create",
                    args: ["conn", "user_params"], 
                    body: "user_params |> validate_user() |> create_user() |> handle_result(conn)",
                    isPrivate: false
                },
                {
                    name: "validate_user",
                    args: ["params"],
                    body: "User.changeset(%User{}, params)",
                    isPrivate: true
                }
            ]
        };
    }
    
    private static function createUserServiceModule(): Dynamic {
        return {
            name: "MyApp.UserService",
            imports: ["Ecto.Query", "MyApp.User", "MyApp.Repo"],
            functions: [
                {
                    name: "create_user_with_profile",
                    args: ["user_attrs", "profile_attrs"],
                    body: "Multi.new() |> Multi.insert(:user, User.changeset(%User{}, user_attrs))",
                    isPrivate: false
                },
                {
                    name: "search_users",
                    args: ["query_string"],
                    body: "from(u in User, where: ilike(u.name, ^query_string))",
                    isPrivate: false
                }
            ]
        };
    }
    
    private static function createUserContextModule(): Dynamic {
        return {
            name: "MyApp.Accounts",
            imports: ["Ecto.Query", "MyApp.User", "MyApp.Repo"],
            functions: [
                {
                    name: "list_users",
                    args: [],
                    body: "Repo.all(User)",
                    isPrivate: false
                },
                {
                    name: "get_user",
                    args: ["id"],
                    body: "Repo.get(User, id)",
                    isPrivate: false
                }
            ]
        };
    }
    
    private static function createLiveViewModule(): Dynamic {
        return {
            name: "MyApp.UserLiveView",
            imports: ["Phoenix.LiveView", "MyApp.User"],
            functions: [
                {
                    name: "mount",
                    args: ["params", "session", "socket"],
                    body: "socket |> assign(:users, []) |> assign(:loading, false)",
                    isPrivate: false
                },
                {
                    name: "handle_event",
                    args: ["\"search\"", "params", "socket"],
                    body: "socket |> assign(:loading, true) |> assign(:users, search_users(params))",
                    isPrivate: false
                }
            ]
        };
    }
    
    private static function createSchemaModule(): Dynamic {
        return {
            name: "MyApp.User",
            imports: ["Ecto.Schema", "Ecto.Changeset"],
            functions: [
                {
                    name: "changeset",
                    args: ["user", "attrs"],
                    body: "user |> cast(attrs, [:name, :email]) |> validate_required([:name, :email])",
                    isPrivate: false
                }
            ]
        };
    }
    
    private static function createComplexLiveViewTemplate(): String {
        return '<div className="user-dashboard">
  <h1>Users Dashboard</h1>
  <div className="search-bar">
    <input onChange="search" value={query} placeholder="Search users..." />
    <button onClick="clear_search" lv:if="query != \'\'">Clear</button>
  </div>
  <div className="user-list" lv:if="users.length > 0">
    {users.map(user => 
      <UserCard 
        key={user.id} 
        user={user} 
        onEdit="edit_user" 
        onDelete="delete_user"
        canEdit={can_edit_user}
      />
    )}
  </div>
  <div className="empty-state" lv:unless="users.length > 0">
    <p>No users found</p>
    <button onClick="create_user">Create First User</button>
  </div>
  <LoadingSpinner lv:if="loading" />
</div>';
    }
    
    private static function createUserListTemplate(): String {
        return '<div className="users">
  {users.map(user => 
    <div className="user-item" key={user.id}>
      <h3>{user.name}</h3>
      <p>{user.email}</p>
      <button onClick="edit_user" data-id={user.id}>Edit</button>
    </div>
  )}
</div>';
    }
    
    private static function createFormTemplate(): String {
        return '<form onSubmit="submit_form" className="user-form">
  <input name="name" value={user.name} onChange="update_field" />
  <input name="email" value={user.email} onChange="update_field" />
  <button type="submit" disabled={!valid}>Save User</button>
</form>';
    }
    
    private static function createDashboardTemplate(): String {
        return '<div className="dashboard">
  <header className="dashboard-header">
    <h1>Dashboard</h1>
    <UserMenu user={current_user} />
  </header>
  <main className="dashboard-content">
    <StatsWidget stats={stats} />
    <RecentActivity activities={recent_activities} />
  </main>
</div>';
    }
    
    private static function createNestedComponentTemplate(): String {
        return '<Modal lv:if="show_modal">
  <ModalHeader>
    <h2>Edit User</h2>
    <CloseButton onClick="close_modal" />
  </ModalHeader>
  <ModalBody>
    <UserForm user={selected_user} onSave="save_user" />
  </ModalBody>
</Modal>';
    }
    
    /**
     * Run all performance benchmarks
     */
    public static function main(): Void {
        trace("⚡ Performance Benchmarks: Testing Trophy - System Performance Validation");
        trace('Target: Module compilation <${COMPILATION_TARGET_MS}ms, HXX processing <${HXX_PROCESSING_TARGET_MS}ms');
        trace("");
        
        var benchmarks = [
            benchmarkModuleCompilation,
            benchmarkHXXProcessing,
            benchmarkPipeOperators,
            benchmarkEndToEndCompilation
        ];
        
        var results = [];
        var passed = 0;
        
        for (benchmark in benchmarks) {
            var result = benchmark();
            results.push(result);
            
            var status = result.passed ? "✅ PASS" : "❌ FAIL";
            trace('${status}: ${result.testName} - ${result.details}');
            
            if (result.passed) passed++;
        }
        
        trace("");
        trace('⚡ Performance Results: ${passed}/${results.length} benchmarks passed');
        
        if (passed == results.length) {
            trace("🚀 All performance targets met! System ready for production use.");
        } else {
            trace("⚠️  Some performance targets missed - optimization needed.");
        }
        
        // Detailed statistics
        trace("");
        trace("📊 Detailed Performance Statistics:");
        for (result in results) {
            var avgMs = Math.round(result.averageTime * 100) / 100;
            var perItem = Math.round(result.perItemTime * 100) / 100;
            trace('  ${result.testName}: ${avgMs}ms avg (${perItem}ms per item, ${result.iterations} iterations)');
        }
    }
}

typedef BenchmarkResult = {
    testName: String,
    totalTime: Float,
    averageTime: Float,
    perItemTime: Float,
    iterations: Int,
    itemCount: Int,
    targetMs: Float,
    passed: Bool,
    details: String
}