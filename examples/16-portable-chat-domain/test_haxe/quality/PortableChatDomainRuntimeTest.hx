package quality;

import haxe.test.Assert;
import haxe.test.ExUnit.TestCase;
import shared.chat.MessageRules;
import shared.chat.MessageRules.MessageDecision;
import shared.chat.Transcript;
import server.PortableChatServer;

/** Runtime evidence that the same portable domain behaves correctly on BEAM. */
@:exunit
class PortableChatDomainRuntimeTest extends TestCase {
	@:test
	function validationNormalizesAndRejectsMessages() {
		switch MessageRules.validate(" Ada ", " Hello\nBEAM ") {
			case Accepted(message):
				Assert.equals("Ada", message.author);
				Assert.equals("Hello BEAM", message.body);
			case Rejected(reason):
				Assert.fail('Unexpected rejection: ${reason}');
		}

		switch MessageRules.validate("", "ignored") {
			case Rejected(reason):
				Assert.equals("author is required", reason);
			case Accepted(_):
				Assert.fail("Expected an empty author to be rejected");
		}

		var longBody = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
		switch MessageRules.validate("Ada", longBody) {
			case Accepted(message):
				Assert.equals("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUV...", message.preview);
			case Rejected(reason):
				Assert.fail('Unexpected long-message rejection: ${reason}');
		}
	}

	@:test
	function transcriptPreservesOrderAndSkipsRejectedMessages() {
		var history = Transcript.empty();
		history = Transcript.add(history, "Ada", "First");
		history = Transcript.add(history, "", "Rejected");
		history = Transcript.add(history, "Grace", "Second");

		var lines = Transcript.render(history);
		Assert.equals(2, lines.length);
		Assert.equals("Ada: First", lines[0]);
		Assert.equals("Grace: Second", lines[1]);
	}

	@:test
	function serverAdapterRunsThePortableDomainOnBeam() {
		Assert.equals("Ada: Hello from the BEAM side. | Grace: The same Haxe rules compiled to Elixir.", PortableChatServer.sampleSummary());
	}
}
