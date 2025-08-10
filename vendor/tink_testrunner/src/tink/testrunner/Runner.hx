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
						teardown().handle(function(o) cb({
							info: suite.info,
							result: switch o {
								case Success(_): Succeeded(results);
								case Failure(e): TeardownFailed(e, results);
							}
						}));
					}
				}
				setup().handle(function(o) switch o {
					case Success(_): next();
					case Failure(e): cb({info: suite.info, result: SetupFailed(e)});
				});
			});
		});
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



