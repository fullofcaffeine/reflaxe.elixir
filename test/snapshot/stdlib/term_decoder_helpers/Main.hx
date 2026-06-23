import elixir.types.Atom;
import elixir.types.Term;
import elixir.types.TermDecoder;
import haxe.ds.Option;
import haxe.functional.Result;

using haxe.functional.ResultTools;

typedef SearchParams = {
	var query:String;
	var page:Option<Int>;
}

class Main {
	static function decodeSearchParams(params:Term):Result<SearchParams, TermDecodeError> {
		return TermDecoder.fetchStringKeyAs(params, "query", TermDecoder.asString).flatMap(query -> {
			return TermDecoder.optionalStringKeyAs(params, "page", TermDecoder.asInt).map(page -> {
				query: query,
				page: page
			});
		});
	}

	static function decodeChangesetField(changeset:Term):Result<String, TermDecodeError> {
		var field:Atom = "email";
		return TermDecoder.fetchAtomKeyAs(changeset, field, TermDecoder.asString);
	}

	static function decodeRepoResult(result:Term):Result<Result<String, String>, TermDecodeError> {
		return TermDecoder.okError(result, TermDecoder.asString, TermDecoder.asString);
	}

	static function main() {
		var params:Term = untyped __elixir__('%{"query" => "haxe", "page" => 2}');
		var changesetFields:Term = untyped __elixir__('%{email: "user@example.com"}');
		var okTuple:Term = untyped __elixir__('{:ok, "created"}');
		var errorTuple:Term = untyped __elixir__('{:error, "invalid"}');

		var decodedParams = decodeSearchParams(params);
		var decodedField = decodeChangesetField(changesetFields);
		var decodedOk = decodeRepoResult(okTuple);
		var decodedError = decodeRepoResult(errorTuple);

		trace(decodedParams);
		trace(decodedField);
		trace(decodedOk);
		trace(decodedError);
	}
}
