package tink.testrunner;

import tink.testrunner.Case;
import tink.testrunner.Suite;
import tink.testrunner.Batch;

using tink.CoreApi;

@:forward
abstract BatchResult(Array<SuiteResult>) from Array<SuiteResult> to Array<SuiteResult> {
	public function summary() {
		var ret = {
			assertions: [],
			failures: [],
		};
		
		function handleCases(cases:Array<CaseResult>)
			for(c in cases) switch c.result {
				case Succeeded(assertions):
					ret.assertions = ret.assertions.concat(assertions);
					ret.failures = ret.failures.concat(
						assertions.filter(function(a) return !a.holds)
							.map(function(a) return AssertionFailed(a))
					);
				case Failed(e):
					ret.failures.push(CaseFailed(e, c.info));
				case Excluded:
					// do nothing
			}
		
		for(s in this) switch s.result {
			case Succeeded(cases):
				handleCases(cases);
			case SetupFailed(e):
				ret.failures.push(SuiteFailed(e, s.info));
			case TeardownFailed(e, cases): 
			 	handleCases(cases);
				ret.failures.push(SuiteFailed(e, s.info));
		}
		
		return ret;
	}
}

typedef SuiteResult = {
	info:SuiteInfo,
	result:SuiteResultType,
}

typedef CaseResult = {
	info:CaseInfo,
	result:CaseResultType,
}

enum SuiteResultType {
	Succeeded(cases:Array<CaseResult>);
	SetupFailed(e:Error);
	TeardownFailed(e:Error, cases:Array<CaseResult>);
}

enum CaseResultType {
	Succeeded(assertions:Array<Assertion>);
	Failed(e:Error);
	Excluded;
}

enum FailureType {
	AssertionFailed(assertion:Assertion);
	CaseFailed(err:Error, info:CaseInfo);
	SuiteFailed(err:Error, info:SuiteInfo);
}
