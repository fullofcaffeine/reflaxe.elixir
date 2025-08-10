package;

import tink.testrunner.*;
import tink.testrunner.Assertion.*;
import tink.testrunner.Case;
import tink.testrunner.Suite;
import tink.testrunner.Reporter;
import travix.Logger.*;

using tink.CoreApi;
using Lambda;

class RunTests {
	static function main() {
		
		var code = 0;
		
		function assertEquals<T>(expected:T, actual:T, ?pos:haxe.PosInfos) {
			if(expected != actual) {
				println('${pos.fileName}:${pos.lineNumber}: Expected $expected but got $actual ');
				code++;
			}
		}
		
		var futures = [];
		
		// Test: cast from single case
		var single = new SingleCase();
		futures.push(
			function() return Runner.run(single).map(function(result) {
				assertEquals(0, result.summary().failures.length);
				return Noise;
			})
		);
		
		// Test: cast from multiple cases
		futures.push(
			function() return Runner.run([
				single, 
				new FutureCase(),
				new PromiseCase(),
				new SurpriseCase(),
				new FuturesCase(),
				new PromisesCase(),
				new SurprisesCase(),
			]).map(function(result) {
				assertEquals(0, result.summary().failures.length);
				return Noise;
			})
		);
		
		// Test: empty suite (reporter should not print the empty suite)
		var reporter = new MemoryReporter();
		futures.push(
			function() return Runner.run([
				new BasicSuite({name: 'SingleSuite'}, [
					single,
				]),
				new BasicSuite({name: 'EmptySuite'}, [
					new ExcludedCase(),
				]),
				new BasicSuite({name: 'MixedSuite'}, [
					single,
					new ExcludedCase(),
				]),
			], reporter).map(function(result) {
				assertEquals(0, result.summary().failures.length);
				assertEquals(3, reporter.logs.filter(function(t) return t.match(SuiteStart(_))).length);
				assertEquals(true, reporter.logs.exists(function(t) return t.match(SuiteStart({name: 'SingleSuite'}, true))));
				assertEquals(true, reporter.logs.exists(function(t) return t.match(SuiteStart({name: 'EmptySuite'}, false))));
				assertEquals(true, reporter.logs.exists(function(t) return t.match(SuiteStart({name: 'MixedSuite'}, true))));
				assertEquals(2, reporter.logs.filter(function(t) return t.match(CaseStart({name: 'SingleCase'}, true))).length);
				assertEquals(2, reporter.logs.filter(function(t) return t.match(CaseStart({name: 'ExcludedCase'}, false))).length);
				assertEquals(2, reporter.logs.filter(function(t) return t.match(CaseFinish({info: {name: 'SingleCase'}, result: Succeeded(_)}))).length);
				assertEquals(2, reporter.logs.filter(function(t) return t.match(CaseFinish({info: {name: 'ExcludedCase'}, result: Excluded}))).length);
				return Noise;
			})
		);
		
		// Test: after/teardown should be run even if case errored
		var suite = new ActionSuite({name: 'ErrorSuite'}, [
			new ErrorCase(),
		]);
		futures.push(
			function() return Runner.run([
				suite,
			]).map(function(result) {
				assertEquals(suite.actions.join(','), 'setup,before,after,teardown');
				assertEquals(1, result.summary().failures.length);
				return Noise;
			})
		);
		
		var iter = futures.iterator();
		function next() {
			if(iter.hasNext()) iter.next()().handle(next);
			else {
				trace('Exiting with code: $code');
				exit(code);
			}
		}
		next();
	}
}

class SingleCase extends BasicCase {
	override function execute():Assertions {
		return new Assertion(true, 'Dummy');
	}
}
class FutureCase extends BasicCase {
	override function execute():Assertions {
		return Future.sync(new Assertion(true, 'Dummy'));
	}
}
class PromiseCase extends BasicCase {
	override function execute():Assertions {
		return (new Assertion(true, 'Dummy'):Promise<Assertion>);
	}
}
class SurpriseCase extends BasicCase {
	override function execute():Assertions {
		return Future.sync(Success(new Assertion(true, 'Dummy')));
	}
}
class FuturesCase extends BasicCase {
	override function execute():Assertions {
		return Future.sync((new Assertion(true, 'Dummy'):Assertions));
	}
}
class PromisesCase extends BasicCase {
	override function execute():Assertions {
		return ((new Assertion(true, 'Dummy'):Assertions):Promise<Assertions>);
	}
}
class SurprisesCase extends BasicCase {
	override function execute():Assertions {
		return Future.sync(Success((new Assertion(true, 'Dummy'):Assertions)));
	}
}
class ExcludedCase extends BasicCase {
	public function new() {
		super();
		exclude = true;
	}
	override function execute():Assertions {
		return new Assertion(true, 'Dummy');
	}
}
class ErrorCase extends BasicCase {
	override function execute():Assertions {
		return Failure(new Error('Errored'));
	}
}

class ActionSuite extends BasicSuite {
	public var actions:Array<String> = [];
	
	override function setup() {
		actions.push('setup');
		return Promise.NOISE;
	}
	override function before() {
		actions.push('before');
		return Promise.NOISE;
	}
	override function after() {
		actions.push('after');
		return Promise.NOISE;
	}
	override function teardown() {
		actions.push('teardown');
		return Promise.NOISE;
	}
}

class MemoryReporter implements Reporter {
	
	public var logs:Array<ReportType> = [];
	
	public function new() {}
	
	public function report(type:ReportType):Future<Noise> {
		logs.push(type);
		return Future.NOISE;
	}
}