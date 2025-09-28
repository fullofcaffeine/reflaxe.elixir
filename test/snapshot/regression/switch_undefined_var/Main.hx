class Main {
	static function main() {
		var items = [{id: 1}, {id: 2}];
		
		// Simple switch in loop - this should generate proper variable assignment
		for (item in items) {
			switch (updateItem(item)) {
				case Ok(updated): trace("Updated: " + updated.id);
				case Error(reason): trace("Failed: " + reason);
			}
		}
	}
	
	static function updateItem(item: {id: Int}): Result<{id: Int}, String> {
		return Ok(item);
	}
}

enum Result<T, E> {
	Ok(value: T);
	Error(error: E);
}