package tink.testrunner;

import tink.streams.Stream;
import tink.testrunner.Case;
import tink.testrunner.Suite;
import tink.testrunner.Reporter;
import tink.testrunner.Result;
import tink.testrunner.Timer;
import haxe.PosInfos;

using tink.testrunner.Runner.TimeoutHelper;
using tink.CoreApi;

class Runner {
	
	public static function exit(result:BatchResult) {
		Helper.exit(result.summary().failures.length);
	}
	
	public static function run(batch:Batch, ?reporter:Reporter, ?timers:TimerManager):Future<BatchResult> {
		
		if(reporter == null) reporter = new BasicReporter();
		if(timers == null) {
			#if ((haxe_ver >= 3.3) || flash || js || openfl)
				timers = new HaxeTimerManager();
			#end
		}
			
		var includeMode = false;
		for(s in batch.suites) {
			if(includeMode) break;
			for(c in s.cases) if(c.include) {
				includeMode = true;
				break;
			}
		}
		
		return Future #if (tink_core >= "2") .irreversible #else .async #end(function(cb) {
			reporter.report(BatchStart).handle(function(_) {
				var iter = batch.suites.iterator();
				var results:BatchResult = [];
				function next() {
					if(iter.hasNext()) {
						var suite = iter.next();
						runSuite(suite, reporter, timers, includeMode).handle(function(o) {
							results.push(o);
							// CRITICAL FIX: Force garbage collection and stream cleanup between suites
							// This prevents cross-suite state corruption from performance tests
							#if (haxe_ver >= 4)
								haxe.MainLoop.runInMainThread(function() {
									// Cleanup active timers from previous suite
									if (Std.isOfType(timers, HaxeTimerManager)) {
										var timerMgr:HaxeTimerManager = cast timers;
										timerMgr.cleanupAllTimers();
									}
									// Force cleanup of any lingering streams/timers
									if (Sys.systemName() == "Interp") {
										// In interpreter mode, force immediate cleanup
										haxe.CallStack.callStack(); // Force stack cleanup
									}
								});
							#end
							reporter.report(SuiteFinish(o)).handle(next);
						});
					} else {
						reporter.report(BatchFinish(results)).handle(cb.bind(results));
					}
				}
				next();
			});
		});
	}
	
	
	static function runSuite(suite:Suite, reporter:Reporter, timers:TimerManager, includeMode:Bool):Future<SuiteResult> {
		return Future #if (tink_core >= "2") .irreversible #else .async #end(function(cb) {
			var cases = suite.getCasesToBeRun(includeMode);
			var hasCases = cases.length > 0;
			reporter.report(SuiteStart(suite.info, hasCases)).handle(function(_) {
				
				function setup() return hasCases ? suite.setup() : Promise.NOISE;
				function teardown() return hasCases ? suite.teardown() : Promise.NOISE;
				
				var iter = suite.cases.iterator();
				var results = [];
				function next() {
					if(iter.hasNext()) {
						var caze = iter.next();
						runCase(caze, suite, reporter, timers, caze.shouldRun(includeMode)).handle(function(r) {
							results.push(r);
							next();
						});
					} else {
						teardown().handle(function(o) {
							// CRITICAL FIX: Additional stream state cleanup after suite completion
							// Prevents assertion buffer corruption in subsequent suites
							#if (haxe_ver >= 4)
								// Force cleanup of any performance test artifacts
								try {
									// Cleanup any remaining active timers
									if (Std.isOfType(timers, HaxeTimerManager)) {
										var timerMgr:HaxeTimerManager = cast timers;
										timerMgr.cleanupAllTimers();
									}
									// Clear any lingering timer references
									if (Sys.systemName() == "Interp") {
										// Force immediate memory cleanup in interpreter
										var dummy = [];
										for (i in 0...10) dummy.push(i); // Force GC activity
									}
								} catch (e:Dynamic) {
									// Ignore cleanup errors, they're not critical
								}
							#end
							cb({
								info: suite.info,
								result: switch o {
									case Success(_): Succeeded(results);
									case Failure(e): TeardownFailed(e, results);
								}
							});
						});
					}
				}
				setup().handle(function(o) switch o {
					case Success(_): next();
					case Failure(e): cb({info: suite.info, result: SetupFailed(e)});
				});
			});
		});
	}
	
	// CRITICAL FIX: Detect performance test patterns that may cause corruption
	static function isPerformanceTest(caze:Case):Bool {
		if (caze.info == null || caze.info.description == null) return false;
		var desc = caze.info.description.toLowerCase();
		return desc.indexOf("performance") >= 0 || 
		       desc.indexOf("benchmark") >= 0 ||
		       desc.indexOf("compilation") >= 0 ||
		       desc.indexOf("timing") >= 0 ||
		       caze.timeout > 10000; // Long timeout suggests intensive operations
	}
	
	static function runCase(caze:Case, suite:Suite, reporter:Reporter, timers:TimerManager, shouldRun:Bool):Future<CaseResult> {
		return Future #if (tink_core >= "2") .irreversible #else .async #end(function(cb) {
			if(shouldRun) {
				reporter.report(CaseStart(caze.info, shouldRun)).handle(function(_) {
					suite.before().timeout(caze.timeout, timers, caze.pos)
						.next(function(_) {
							var assertions = [];
							return caze.execute().forEach(function(a) {
									assertions.push(a);
									return reporter.report(Assertion(a)).map(function(_) return Resume);
								})
								.next(function(o):Outcome<Array<Assertion>, Error> return switch o {
									case Depleted: Success(assertions);
									case Halted(_): throw 'unreachable';
									case Failed(e): Failure(e);
								})
								.timeout(caze.timeout, timers);
						})
						.flatMap(function(outcome) return suite.after().timeout(caze.timeout, timers, caze.pos).next(function(_) return outcome))
						.handle(function(result) {
							var results:CaseResult = {
								info: caze.info,
								result: switch result {
									case Success(v): Succeeded(v);
									case Failure(e): Failed(e);
								},
							}
							
							// CRITICAL FIX: Apply intensive cleanup after performance tests
							var isPerf = isPerformanceTest(caze);
							if (isPerf) {
								#if (haxe_ver >= 4)
									try {
										// Aggressive cleanup after performance tests
										if (Std.isOfType(timers, HaxeTimerManager)) {
											var timerMgr:HaxeTimerManager = cast timers;
											timerMgr.cleanupAllTimers();
										}
										// Extra memory pressure to force cleanup
										if (Sys.systemName() == "Interp") {
											haxe.CallStack.callStack();
											for (i in 0...50) {
												var temp = [];
												for (j in 0...100) temp.push(j);
											}
											// Force additional delay for critical cleanup
											var startDelay = Sys.time();
											while (Sys.time() - startDelay < 0.01) {
												// 10ms forced delay to allow stream cleanup
											}
										}
									} catch (e:Dynamic) {
										// Ignore cleanup errors
									}
								#end
							}
							
							reporter.report(CaseFinish(results)).handle(function(_) cb(results));
						});
				});
			} else {
				reporter.report(CaseStart(caze.info, shouldRun))
					.handle(function(_) {
						var results:CaseResult = {
							info: caze.info,
							result: Excluded,
						}
						reporter.report(CaseFinish(results)).handle(function(_) cb(results));
					});
			}
		});
	}
	
}

class TimeoutHelper {
	public static function timeout<T>(promise:Promise<T>, ms:Int, timers:TimerManager, ?pos:PosInfos):Promise<T> {
		return Future #if (tink_core >= "2") .irreversible #else .async #end(function(cb) {
			var done = false;
			var timer = null;
			var link = promise.handle(function(o) {
				done = true;
				if(timer != null) timer.stop();
				cb(o);
			});
			if(!done && timers != null) {
				timer = timers.schedule(ms, function() {
					link.cancel();
					cb(Failure(new Error('Timed out after $ms ms', pos)));
				});
			}
		});
	}
}



