package;

import elixir.Supervisor;
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
        // Test supervisor with different restart strategies
        var children = [
            Supervisor.workerSpec("MyWorker", {name: "worker1"}, "worker1", "permanent"),
            Supervisor.workerSpec("MyWorker", {name: "worker2"}, "worker2", "temporary"),
            Supervisor.supervisorSpec("SubSupervisor", {}, "sub_supervisor", "permanent")
        ];
        
        var options = Supervisor.simpleOneForOne(5, 10);
        
        // Start supervisor
        var result = Supervisor.startLink(children, options);
        if (result._0 == "ok") {
            var supervisor = result._1;
            
            // Test child management
            var childrenList = Supervisor.whichChildren(supervisor);
            var counts = Supervisor.countChildren(supervisor);
            
            // Test restart
            Supervisor.restartChild(supervisor, "worker1");
            
            // Test terminate
            Supervisor.terminateChild(supervisor, "worker2");
            
            // Test delete
            Supervisor.deleteChild(supervisor, "worker2");
            
            // Test dynamic child addition
            var newChild = Supervisor.workerSpec("DynamicWorker", {}, "dynamic", "transient");
            Supervisor.startChild(supervisor, newChild);
            
            // Test supervisor stats
            var stats = Supervisor.getStats(supervisor);
            trace('Active workers: ${stats.workers}, Supervisors: ${stats.supervisors}');
            
            // Check if alive
            if (Supervisor.isAlive(supervisor)) {
                trace("Supervisor is running");
            }
            
            // Stop supervisor
            Supervisor.stop(supervisor);
        }
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
            if (taskResult._1 != null && taskResult._1._0 == "ok") {
                trace('Task result: ${taskResult._1._1}');
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
        // Test supervisor with simpler configuration
        var children = [
            Supervisor.workerSpec("Worker1", {}, "worker1", "permanent"),
            Supervisor.workerSpec("Worker2", {}, "worker2", "temporary"),
            Supervisor.workerSpec("Worker3", {}, "worker3", "transient")
        ];
        
        var options: Map<String, Dynamic> = [
            "strategy" => "one_for_all",
            "max_restarts" => 10,
            "max_seconds" => 60
        ];
        
        var result = Supervisor.startLink(children, options);
        if (result._0 == "ok") {
            var supervisor = result._1;
            
            // Verify tree structure
            var stats = Supervisor.getStats(supervisor);
            trace('Supervisor - Workers: ${stats.workers}, Supervisors: ${stats.supervisors}');
            
            // Test child management
            var childrenList = Supervisor.whichChildren(supervisor);
            for (child in childrenList) {
                trace('Child: ${child._0}, Type: ${child._2}');
            }
            
            // Test restart behavior
            Supervisor.restartChild(supervisor, "worker1");
            
            // Clean shutdown
            Supervisor.stopWithReason(supervisor, "normal");
        }
    }
}