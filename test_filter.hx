import haxe.functional.Result; import haxe.functional.ResultTools; using haxe.functional.ResultTools; class Test { static function main() { var r = Ok(42); r.filter(x -> x > 10, "too small"); } }
