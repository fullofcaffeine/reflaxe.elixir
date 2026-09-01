package reflaxe.elixir.runtime;

import elixir.types.Atom;

/** Native BEAM devices and results used by the standard stream adapters. */
enum abstract StandardIODevice(Atom) to Atom {
	var StandardIO = "standard_io";
	var StandardError = "stderr";
	var EndOfFile = "eof";
}
