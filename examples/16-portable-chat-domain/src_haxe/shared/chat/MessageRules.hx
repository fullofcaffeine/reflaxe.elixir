package shared.chat;

typedef ChatMessage = {
	var author:String;
	var body:String;
	var preview:String;
}

enum MessageDecision {
	Accepted(message:ChatMessage);
	Rejected(reason:String);
}

class MessageRules {
	static inline final MAX_AUTHOR_LENGTH = 32;
	static inline final MAX_BODY_LENGTH = 280;
	static inline final PREVIEW_LENGTH = 48;

	public static function normalizeAuthor(author:String):String {
		if (author == null) {
			return "";
		}

		return StringTools.trim(author);
	}

	public static function normalizeBody(body:String):String {
		if (body == null) {
			return "";
		}

		return StringTools.trim(body.split("\n").join(" "));
	}

	public static function validate(author:String, body:String):MessageDecision {
		var normalizedAuthor = normalizeAuthor(author);
		var normalizedBody = normalizeBody(body);

		if (normalizedAuthor.length == 0) {
			return Rejected("author is required");
		}

		if (normalizedAuthor.length > MAX_AUTHOR_LENGTH) {
			return Rejected("author is too long");
		}

		if (normalizedBody.length == 0) {
			return Rejected("message body is required");
		}

		if (normalizedBody.length > MAX_BODY_LENGTH) {
			return Rejected("message body is too long");
		}

		return Accepted({
			author: normalizedAuthor,
			body: normalizedBody,
			preview: preview(normalizedBody)
		});
	}

	public static function format(message:ChatMessage):String {
		return message.author + ": " + message.body;
	}

	static function preview(body:String):String {
		if (body.length <= PREVIEW_LENGTH) {
			return body;
		}

		return body.substr(0, PREVIEW_LENGTH) + "...";
	}
}
