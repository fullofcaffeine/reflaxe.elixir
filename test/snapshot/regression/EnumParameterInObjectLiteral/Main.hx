/**
 * Regression test for TEnumParameter extraction bug
 *
 * EXACT BUG PATTERN from TodoPubSub.parseMessageImpl:
 *
 * When a nested switch extracts an enum parameter and then wraps it in ANOTHER enum constructor,
 * TEnumParameter extraction creates references to the enum parameter name instead of the
 * pattern-bound variable, resulting in undefined variable errors.
 *
 * Haxe Source Pattern:
 *   switch (outerEnum) {
 *     case Some(innerEnum):
 *       switch (innerEnum) {
 *         case Value(x): Some(Result(x));  // Bug: tries to reference 'x' instead of pattern variable
 *       }
 *   }
 *
 * Generated Elixir (BUGGY):
 *   case outer_enum do
 *     {:some, v} ->
 *       case v do
 *         {:value, extracted} ->
 *           {:some, {:result, x}}  # BUG: 'x' is undefined! Should be 'extracted'
 *       end
 *   end
 *
 * Real-world example: TodoPubSub.parseMessageImpl line 204-206
 * Related: commits 940c7722, bed3790c
 */

enum Option<T> {
	Some(value: T);
	None;
}

enum BulkAction {
	CompleteAll;
	DeleteCompleted;
	SetPriority(priority: String);
}

enum TodoMessage {
	BulkUpdate(action: BulkAction);
	TodoCreated(todo: String);
}

class Main {
	public static function main() {
		// Test the EXACT pattern from TodoPubSub.parseMessageImpl
		// This triggers the nested enum parameter extraction bug

		// Test 1: Nested enum extraction with wrapping (EXACT bug trigger)
		var bulkAction = Some(SetPriority("high"));
		var result = parseAction(bulkAction);
		switch(result) {
			case Some(msg):
				trace('Got message: $msg');
			case None:
				trace('No message');
		}

		// Test 2: Direct nested enum (simpler case)
		var simpleAction = Some(CompleteAll);
		var result2 = parseAction(simpleAction);
		trace('Simple result: $result2');
	}

	// This function matches TodoPubSub.parseMessageImpl pattern exactly:
	// Nested switch that extracts enum parameter, then wraps in another enum
	static function parseAction(optAction: Option<BulkAction>): Option<TodoMessage> {
		return switch(optAction) {
			case Some(action):
				// Inner switch extracts 'priority' from SetPriority
				// Then wraps in BulkUpdate which wraps in Some
				// This triggers TEnumParameter extraction bug
				switch(action) {
					case SetPriority(priority):
						Some(BulkUpdate(SetPriority(priority))); // Bug: 'priority' becomes undefined
					case CompleteAll:
						Some(BulkUpdate(CompleteAll));
					case DeleteCompleted:
						Some(BulkUpdate(DeleteCompleted));
				}
			case None:
				None;
		}
	}
}
