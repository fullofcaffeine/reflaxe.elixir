package tink.testrunner;

import tink.testrunner.Suite;
import tink.testrunner.Case;
import tink.testrunner.Result;

using tink.CoreApi;
using Lambda;
using StringTools;

interface Reporter {
	function report(type:ReportType):Future<Noise>; // reporter cannot fail, so it won't ruin the test
}

enum ReportType {
	BatchStart;
	SuiteStart(info:SuiteInfo, hasCasesToRun:Bool);
	CaseStart(info:CaseInfo, shouldRun:Bool);
	Assertion(assertion:Assertion);
	CaseFinish(result:CaseResult);
	SuiteFinish(result:SuiteResult);
	BatchFinish(result:BatchResult);
}

interface Formatter {
	function success(v:String):String;
	function error(v:String):String;
	function warning(v:String):String;
	function info(v:String):String;
	function extra(v:String):String;
	function mute(v:String):String;
	function normal(v:String):String;
	function color(v:String, color:String):String;
}

class BasicFormatter implements Formatter {
	public function new() {}
	
	public function success(v:String):String return color(v, 'green');
	public function error(v:String):String return color(v, 'red');
	public function warning(v:String):String return color(v, 'yellow');
	public function info(v:String):String return color(v, 'yellow');
	public function extra(v:String):String return color(v, 'cyan');
	public function mute(v:String):String return color(v, 'blue');
	public function normal(v:String):String return color(v, '');
	public function color(v:String, c:String):String return v;
}

#if ansi
class AnsiFormatter extends BasicFormatter {
	override function color(v:String, c:String):String
		return switch c {
			case 'red': ANSI.aset([ANSI.Attribute.Red]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			case 'green': ANSI.aset([ANSI.Attribute.Green]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			case 'blue': ANSI.aset([ANSI.Attribute.Blue]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			case 'yellow': ANSI.aset([ANSI.Attribute.Yellow]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			case 'magenta': ANSI.aset([ANSI.Attribute.Magenta]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			case 'cyan': ANSI.aset([ANSI.Attribute.Cyan]) + v + ANSI.aset([ANSI.Attribute.DefaultForeground]);
			default: ANSI.aset([ANSI.Attribute.DefaultForeground]) + v;
		}
}
#end

class BasicReporter implements Reporter {
	#if (ansi && (sys || nodejs))
	static var inited = false;
	#end
	var formatter:Formatter;
	
	public function new(?formatter) {
		#if (ansi && (sys || nodejs))
		if(!inited) {
			inited = true;
			init();
		}
		#end
		this.formatter =
			if(formatter != null)
				formatter;
			else {
				#if (ansi && (sys || nodejs))
					if(ANSI.available) {
						ANSI.stripIfUnavailable = false;
						new AnsiFormatter();
					} else {
						new BasicFormatter();
					}
				#elseif(ansi && js && travix) {
					ANSI.stripIfUnavailable = false;
					new AnsiFormatter();
				}
				#else
					new BasicFormatter();
				#end
			}
	}

	#if (ansi && (sys || nodejs))
	static function init() {
		if(Sys.systemName() == 'Windows') { 
			// HACK: use the "ANSICON" env var to force enable ANSI if running in PowerShell
			var value = Sys.getEnv('PSModulePath');
			var isPowerShell = value != null && value.split(';').length >= 3;
			#if !java // Java cannot do this ... perhaps it's possible via Sys.command, but since this is a hack anyway, I'll forgo the pleasure of messing with this
			if(isPowerShell) Sys.putEnv('ANSICON', '1');
			#end
		}
	}
	#end
	
	public function report(type:ReportType):Future<Noise> {
		switch type {
			case BatchStart:
				reportBatchStart();
			case SuiteStart(info, hasCasesToRun):
				reportSuiteStart(info, hasCasesToRun);
			case CaseStart(info, shouldRun):
				reportCaseStart(info, shouldRun);
			case Assertion(assertion):
				reportAssertion(assertion);
			case CaseFinish(result):
				reportCaseFinish(result);
			case SuiteFinish(result):
				reportSuiteFinish(result);
			case BatchFinish(result):
				reportBatchFinish(result);
		}
		return Future.NOISE;
	}

	function reportBatchStart() {}

	function reportSuiteStart(info:SuiteInfo, hasCasesToRun:Bool) {
		if (hasCasesToRun) {
			println(' ');
			var m = formatter.info(info.name) + ': ';
			if (info.pos != null)
				m += formatter.extra('[${info.pos.fileName}:${info.pos.lineNumber}]');
			println(m);
		}
	}

	function reportCaseStart(info:CaseInfo, shouldRun:Bool) {
		if (shouldRun) {
			var m = formatter.info(indent(info.name, 2)) + ': ';
			if (info.pos != null)
				m += formatter.extra('[${info.pos.fileName}:${info.pos.lineNumber}] ');
			if (info.description != null)
				m += formatter.mute(info.description);
			println(m);
		}
	}

	function reportAssertion(assertion:Assertion) {
		var failure = null;
		var holds = switch assertion.holds {
			case Success(_): formatter.success('[OK]');
			case Failure(msg):
				failure = msg;
				formatter.error('[FAIL]');
		}
		var pos = formatter.extra('[${assertion.pos.fileName}:${assertion.pos.lineNumber}]');
		var m = indent('- $holds $pos ${indent(assertion.description, 4, true)}', 4);
		println(m);
		if (failure != null)
			println(formatter.error(indent(failure, 8)));
	}

	function reportCaseFinish(result:CaseResult) {
		switch result.result {
			case Failed(e):
				println(formatter.error(indent('- ${formatError(e)}', 4)));
			case _:
		}
	}

	function reportSuiteFinish(result:SuiteResult) {
		switch result.result {
			case Succeeded(_): // ok
			case SetupFailed(e):
				println(formatter.error(indent('Setup Failed: ${formatError(e)}', 2)));
			case TeardownFailed(e, _):
				println(formatter.error(indent('Teardown Failed: ${formatError(e)}', 2)));
		}
	}

	function reportBatchFinish(result:BatchResult) {
		var summary = result.summary();
		var total = summary.assertions.length;
		var failures = 0, errors = 0;
		for (f in summary.failures)
			switch f {
				case AssertionFailed(_):
					failures++;
				default:
					errors++;
			}
		var success = total - failures;

		var m = new StringBuf();
		m.add(total);
		m.add(' Assertion');
		if (total > 1)
			m.add('s');
		m.add('   ');

		m.add(success);
		m.add(' Success');
		m.add('   ');

		m.add(failures);
		m.add(' Failure');
		if (failures > 1)
			m.add('s');
		m.add('   ');

		m.add(errors);
		m.add(' Error');
		if (errors > 1)
			m.add('s');
		m.add('   ');

		var m = m.toString();

		println(' ');
		println(failures == 0 && errors == 0 ? formatter.success(m) : formatter.error(m));
		println(' ');
	}

	function println(v:String)
		#if travix
			travix.Logger.println(v);
		#elseif (flash || air || air3)
			flash.Lib.trace(v);
		#elseif (sys || nodejs)
			Sys.println(v);
		#elseif js
			js.Browser.window.console.log(v);
		#else
			throw "Not supported yet";
		#end
	
	function indent(v:String, i = 0, skipFirst = false) {
		var prefix = ''.lpad(' ', i);
		var ret = v.split('\n')
			.map(function(line) return prefix + line)
			.join('\n');
		return skipFirst ? ret.substr(i) : ret;
	}
	
	function formatError(e:Error) {
		var str = e.toString();
		if(e.data != null) str += '\n' + Std.string(e.data);
		return str;
	}
}

class CompactReporter extends BasicReporter {
	var count = 0;

	override function reportCaseStart(info, shouldRun) {
		count = 0;
		super.reportCaseStart(info, shouldRun);
	}

	override function reportAssertion(assertion:Assertion) {
		if (assertion.holds) {
			count++;
		} else {
			super.reportAssertion(assertion);
		}
	}

	override function reportCaseFinish(result) {
		println(formatter.success(indent('+ $count assertion(s) succeeded', 4)));
		super.reportCaseFinish(result);
	}
}

