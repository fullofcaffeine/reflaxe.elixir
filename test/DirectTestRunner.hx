package test;

import tink.unit.TestBatch;
import tink.testrunner.Reporter;
import tink.testrunner.Suite;
import tink.testrunner.Case;
import tink.testrunner.Result;
import tink.testrunner.Assertion;
import tink.streams.Stream;
import tink.testrunner.Assertions;

using tink.CoreApi;

/**
 * DirectTestRunner - Simplified test execution to avoid tink_testrunner's complex Promise chains
 * 
 * This runner uses tink_testrunner's Reporter for colored output and formatting
 * but executes tests synchronously to avoid the Promise chain state corruption
 * that causes framework timeouts.
 * 
 * Based on analysis of tink_testrunner source code and the timeout elimination investigation.
 */
class DirectTestRunner {
    
    public static function run(batch:TestBatch):Future<BatchResult> {
        return Future.async(function(cb) {
            var reporter = new BasicReporter();
            var results:BatchResult = [];
            
            // Start the batch reporting
            reporter.report(BatchStart);
            
            // Process each suite sequentially and synchronously  
            for (suite in batch.suites) {
                var suiteResult = runSuiteDirectly(suite, reporter);
                results.push(suiteResult);
                reporter.report(SuiteFinish(suiteResult));
            }
            
            // Finish batch reporting
            reporter.report(BatchFinish(results));
            
            // Return results immediately (no Promise chain delays)
            cb(results);
        });
    }
    
    /**
     * Run a suite directly without complex Promise chains
     * This avoids the state corruption issues in tink_testrunner.Runner.runSuite()
     */
    static function runSuiteDirectly(suite:Suite, reporter:Reporter):SuiteResult {
        var cases = suite.getCasesToBeRun(false);
        var hasCases = cases.length > 0;
        
        reporter.report(SuiteStart(suite.info, hasCases));
        
        if (!hasCases) {
            return {
                info: suite.info,
                result: Succeeded([])
            };
        }
        
        var results = [];
        
        // Setup phase - execute synchronously
        var setupResult = executePromiseSync(suite.setup());
        if (setupResult.isFailure()) {
            return {
                info: suite.info,
                result: SetupFailed(setupResult.sure())
            };
        }
        
        // Execute each case directly
        for (caze in suite.cases) {
            if (caze.shouldRun(false)) {
                var caseResult = runCaseDirectly(caze, suite, reporter);
                results.push(caseResult);
            } else {
                var excludedResult:CaseResult = {
                    info: caze.info,
                    result: Excluded
                };
                reporter.report(CaseStart(caze.info, false));
                reporter.report(CaseFinish(excludedResult));
                results.push(excludedResult);
            }
        }
        
        // Teardown phase - execute synchronously  
        var teardownResult = executePromiseSync(suite.teardown());
        
        return {
            info: suite.info,
            result: switch teardownResult {
                case Success(_): Succeeded(results);
                case Failure(e): TeardownFailed(e, results);
            }
        };
    }
    
    /**
     * Run a case directly without Promise chain complexity
     * This avoids the timeout issues in tink_testrunner.Runner.runCase()
     */
    static function runCaseDirectly(caze:Case, suite:Suite, reporter:Reporter):CaseResult {
        reporter.report(CaseStart(caze.info, true));
        
        // Before phase - execute synchronously
        var beforeResult = executePromiseSync(suite.before());
        if (beforeResult.isFailure()) {
            var failedResult:CaseResult = {
                info: caze.info,
                result: Failed(beforeResult.sure())
            };
            reporter.report(CaseFinish(failedResult));
            return failedResult;
        }
        
        // Execute test case - this is where timeouts were occurring
        var assertions = [];
        var caseExecutionResult = try {
            // Get the assertion stream from the case
            var assertionStream = caze.execute();
            
            // Process assertions synchronously instead of via Promise chains
            var streamResult = executeStreamSync(assertionStream);
            switch streamResult {
                case Success(assertionList): 
                    assertions = assertionList;
                    // Report each assertion individually
                    for (assertion in assertions) {
                        reporter.report(Assertion(assertion));
                    }
                    Success(assertions);
                case Failure(e): 
                    Failure(e);
            }
        } catch (e:Dynamic) {
            Failure(new Error('Test execution failed: $e'));
        }
        
        // After phase - execute synchronously
        var afterResult = executePromiseSync(suite.after());
        
        // Combine results
        var finalResult:CaseResult = {
            info: caze.info,
            result: switch [caseExecutionResult, afterResult] {
                case [Success(_), Success(_)]: Succeeded(assertions);
                case [Failure(e), _]: Failed(e);
                case [_, Failure(e)]: Failed(e);
            }
        };
        
        reporter.report(CaseFinish(finalResult));
        return finalResult;
    }
    
    /**
     * Execute a Promise synchronously to avoid async complexity
     * This is the key to avoiding framework state corruption
     */
    static function executePromiseSync<T>(promise:Promise<T>):Outcome<T, Error> {
        var result:Outcome<T, Error> = null;
        var completed = false;
        
        // Set up the promise handler
        promise.handle(function(outcome) {
            result = outcome;
            completed = true;
        });
        
        // Simple polling wait (avoiding Timer complexity)
        var maxAttempts = 1000; // ~1 second total wait
        var attempts = 0;
        
        while (!completed && attempts < maxAttempts) {
            // Give the promise a chance to complete
            attempts++;
            // Simple busy wait to avoid Timer/setTimeout complexity
            for (i in 0...1000) {
                // Minimal CPU cycle to allow promise resolution
            }
        }
        
        if (!completed) {
            return Failure(new Error('Promise execution timeout'));
        }
        
        return result;
    }
    
    /**
     * Execute an assertion Stream synchronously 
     * This replaces tink_testrunner's complex Stream.forEach() Promise chains
     */
    static function executeStreamSync(stream:Assertions):Outcome<Array<Assertion>, Error> {
        var assertions = [];
        var completed = false;
        var streamError:Error = null;
        
        // Process stream items
        stream.forEach(function(assertion) {
            assertions.push(assertion);
            return Resume; // Continue processing
        }).handle(function(outcome) {
            switch outcome {
                case Depleted: completed = true;
                case Failed(e): streamError = e;
                case Halted(_): streamError = new Error('Stream was halted unexpectedly');
            }
        });
        
        // Wait for stream completion
        var maxAttempts = 1000;
        var attempts = 0;
        
        while (!completed && streamError == null && attempts < maxAttempts) {
            attempts++;
            // Simple busy wait
            for (i in 0...1000) {
                // Minimal CPU cycle
            }
        }
        
        if (streamError != null) {
            return Failure(streamError);
        }
        
        if (!completed) {
            return Failure(new Error('Stream execution timeout'));
        }
        
        return Success(assertions);
    }
}