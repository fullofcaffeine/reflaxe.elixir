import server.live.RowState;
import shared.liveview.ProjectUiEvent;

class Main {
	static function main():Void {
		var event = ProjectUiEvent.Select(42);
		var state = RowState.Open;

		switch (event) {
			case Select(id):
				if (id <= 0) {
					throw "invalid id";
				}
			case Clear:
		}

		switch (state) {
			case Open:
			case Closed:
				throw "unexpected";
		}
	}
}
