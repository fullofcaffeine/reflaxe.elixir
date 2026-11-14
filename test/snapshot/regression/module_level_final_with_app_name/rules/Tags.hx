package rules;

/** Tags that always stay private. A module-level value, read by the function below. */
final keepPrivateTags:Array<String> = ["personal", "private"];

/** True when the tag is one of the tags that always stay private. */
function isPrivate(tag:String):Bool
	return keepPrivateTags.indexOf(tag) >= 0;
