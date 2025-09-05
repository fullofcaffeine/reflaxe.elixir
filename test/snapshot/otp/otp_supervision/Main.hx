package;

import elixir.otp.Supervisor;
import elixir.otp.Supervisor.SupervisorExtern;
import elixir.otp.Supervisor.ChildSpec;
import elixir.otp.Supervisor.SupervisorOptions;
import elixir.otp.Supervisor.RestartType;
import elixir.otp.Supervisor.ChildType;
import elixir.otp.Supervisor.SupervisorStrategy;
import elixir.Task;
import elixir.TaskSupervisor;
import elixir.GenServer;
import elixir.Process;
import elixir.Registry;

/**
 * OTP Supervision Patterns Test
 * Tests Supervisor, Task, and Task.Supervisor extern definitions
 */
class Main {
    static function main() {
        testSupervisor();
        testTask();
        testTaskSupervisor();
        testSupervisionTree();
    }
    
    /**
     * Test Supervisor extern functions
     */
    static function testSupervisor() {
        // Test supervisor with different restart strategies using ChildSpecFormat
        var children: Array<ChildSpecFormat> = [
            FullSpec({
                id: "worker1",
                start: {module: "MyWorker", func: "start_link", args: [{name: "worker1"}]},
                restart: RestartType.Permanent,
                type: ChildType.Worker
            }),
            FullSpec({
                id: "worker2", 
                start: {module: "MyWorker", func: "start_link", args: [{name: "worker2"}]},
                restart: RestartType.Temporary,
                type: ChildType.Worker
            }),
            FullSpec({
                id: "sub_supervisor",
                start: {module: "SubSupervisor", func: "start_link", args: [{}]},
                restart: RestartType.Permanent, 
                type: ChildType.Supervisor
            })
        ];
        
        var options = {
            strategy: SupervisorStrategy.OneForOne,
            max_restarts: 5,
            max_seconds: 10
        };
        
        // Start supervisor
        var result = SupervisorExtern.startLink(children, options);
        // For now, just assume it succeeds and returns the supervisor
        var supervisor = result;
            
            // Test child management
            var childrenList = SupervisorExtern.whichChildren(supervisor);
            var counts = SupervisorExtern.countChildren(supervisor);
            
            // Test restart
            SupervisorExtern.restartChild(supervisor, "worker1");
            
            // Test terminate
            SupervisorExtern.terminateChild(supervisor, "worker2");
            
            // Test delete
            SupervisorExtern.deleteChild(supervisor, "worker2");
            
            // Test dynamic child addition
            var newChild = {
                id: "dynamic",
                start: {module: "DynamicWorker", func: "start_link", args: [{}]},
                restart: RestartType.Transient,
                type: ChildType.Worker
            };
            SupervisorExtern.startChild(supervisor, newChild);
            
            // Test supervisor stats
            var stats = SupervisorExtern.countChildren(supervisor);
            trace('Active workers: ${stats.workers}, Supervisors: ${stats.supervisors}');
            
            // Check if alive
            if (Process.alive(supervisor)) {
                trace("Supervisor is running");
            }
            
            // Stop supervisor
            // SupervisorExtern doesn't have stop, use Process.exit
            Process.exit(supervisor, "normal");
        }
    
    /**
     * Test Task extern functions
     */
    static function testTask() {
        // Test async/await
        var task = Task.async(function() {
            // Simulate work
            Process.sleep(100);
            return 42;
        });
        
        var result = Task.await(task);
        trace('Async result: $result');
        
        // Test with timeout
        var slowTask = Task.async(function() {
            Process.sleep(5000);
            return "slow";
        });
        
        var yieldResult = Task.yieldWithTimeout(slowTask, 100);
        if (yieldResult == null) {
            trace("Task timed out");
            Task.shutdown(slowTask);
        }
        
        // Test fire and forget
        Task.start(function() {
            trace("Background task running");
        });
        
        // Test linked task
        var linkedResult = Task.startLink(function() {
            trace("Linked task running");
        });
        
        // Test multiple concurrent tasks
        var tasks = [
            Task.async(function() return 1),
            Task.async(function() return 2),
            Task.async(function() return 3)
        ];
        
        var results = Task.yieldMany(tasks);
        for (taskResult in results) {
            // taskResult has task and result fields
            if (taskResult.result != null) {
                trace('Task result: ${taskResult.result}');
            }
        }
        
        // Test helper functions
        var quickResult = Task.runAsync(function() {
            return "quick";
        });
        
        var concurrentResults = Task.runConcurrently([
            function() return "a",
            function() return "b",
            function() return "c"
        ]);
        
        var timedResult = Task.runWithTimeout(function() {
            Process.sleep(50);
            return "timed";
        }, 100);
        
        Task.runInBackground(function() {
            trace("Fire and forget");
        });
        
        // Test async stream
        var stream = Task.asyncStream([1, 2, 3, 4, 5], function(x) {
            return x * 2;
        });
    }
    
    /**
     * Test Task.Supervisor extern functions
     */
    static function testTaskSupervisor() {
        // Start task supervisor
        var supervisorResult = TaskSupervisor.startLink();
        if (supervisorResult._0 == "ok") {
            var supervisor = supervisorResult._1;
            
            // Test supervised async
            var task = TaskSupervisor.async(supervisor, function() {
                return "supervised";
            });
            var result = Task.await(task);
            trace('Supervised task result: $result');
            
            // Test async nolink
            var nolinkTask = TaskSupervisor.asyncNolink(supervisor, function() {
                return "not linked";
            });
            Task.await(nolinkTask);
            
            // Test start child
            TaskSupervisor.startChild(supervisor, function() {
                trace("Supervised child task");
            });
            
            // Get children
            var children = TaskSupervisor.children(supervisor);
            trace('Supervised tasks count: ${children.length}');
            
            // Test async stream
            var stream = TaskSupervisor.asyncStream(
                supervisor,
                [10, 20, 30],
                function(x) return x + 1
            );
            
            // Test helper functions
            var supervisedResult = TaskSupervisor.runSupervised(supervisor, function() {
                return "helper result";
            });
            
            var concurrentResults = TaskSupervisor.runSupervisedConcurrently(supervisor, [
                function() return 100,
                function() return 200,
                function() return 300
            ]);
            
            TaskSupervisor.runSupervisedInBackground(supervisor, function() {
                trace("Background supervised task");
            });
        }
    }
    
    /**
     * Test complete supervision tree
     */
    static function testSupervisionTree() {
        // Test supervisor with ChildSpecFormat enum
        var children: Array<ChildSpecFormat> = [
            FullSpec({
                id: "worker1",
                start: {module: "Worker1", func: "start_link", args: [{}]},
                restart: RestartType.Permanent,
                type: ChildType.Worker
            }),
            FullSpec({
                id: "worker2",
                start: {module: "Worker2", func: "start_link", args: [{}]},
                restart: RestartType.Temporary, 
                type: ChildType.Worker
            }),
            FullSpec({
                id: "worker3",
                start: {module: "Worker3", func: "start_link", args: [{}]},
                restart: RestartType.Transient,
                type: ChildType.Worker
            })
        ];
        
        var options = {
            strategy: SupervisorStrategy.OneForAll,
            max_restarts: 10,
            max_seconds: 60
        };
        
        var result = SupervisorExtern.startLink(children, options);
        // Assume success for test
        var supervisor = result;
            
            // Verify tree structure
            var stats = SupervisorExtern.countChildren(supervisor);
            trace('Supervisor - Workers: ${stats.workers}, Supervisors: ${stats.supervisors}');
            
            // Test child management
            var childrenList = SupervisorExtern.whichChildren(supervisor);
            for (child in childrenList) {
                trace('Child: ${child._0}, Type: ${child._2}');
            }
            
            // Test restart behavior
            SupervisorExtern.restartChild(supervisor, "worker1");
            
            // Clean shutdown
            SupervisorExtern.terminateChild(supervisor, "normal");
    }
}