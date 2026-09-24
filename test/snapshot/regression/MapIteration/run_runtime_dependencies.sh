#!/usr/bin/env bash
set -euo pipefail

# Independent Haxe/JavaScript and BEAM assertions cover ordinary map APIs without
# importing their runtime helper. Haxe 4.3.7 eval cannot run the interface-only
# key/value fixture (missing MapKeyValueIterator prototype); the stock JS target
# provides the reference instead. Each native run gets its own isolated VM.
FIXTURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$FIXTURE_DIR/../../../.." && pwd)"
TIMEOUT="$ROOT_DIR/scripts/with-timeout.sh"
HAXE="$ROOT_DIR/node_modules/.bin/haxe"
mkdir -p "$ROOT_DIR/tmp"
PROBE_ROOT="$(mktemp -d "$ROOT_DIR/tmp/map-runtime-dependencies.XXXXXX")"
export HAXE_NO_SERVER=1
export ERL_FLAGS="${ERL_FLAGS:-+S 2:2}"

cleanup() {
	local result="$?"
	if [[ "$result" == 0 ]]; then
		find "$PROBE_ROOT" -depth -delete
	else
		echo "MAP_DEPENDENCY_EVIDENCE:$PROBE_ROOT" >&2
	fi
}
trap cleanup EXIT

cd "$ROOT_DIR"
probes=("$@")
if [[ ${#probes[@]} == 0 ]]; then
	probes=(Main MapLookupDependencyProbe MapRuntimeDependencyProbe MapInterfaceDependencyProbe MapInterfaceExportProbe CustomMapDependencyProbe StructuralMethodProbe)
fi
for probe in "${probes[@]}"; do
	case "$probe" in
		Main|MapLookupDependencyProbe|MapRuntimeDependencyProbe|MapInterfaceDependencyProbe|MapInterfaceExportProbe|CustomMapDependencyProbe|StructuralMethodProbe) ;;
		*) echo "Unknown map dependency probe: $probe" >&2; exit 2 ;;
	esac
	"$TIMEOUT" --secs 60 -- "$HAXE" -cp "$FIXTURE_DIR" -main "$probe" -js "$PROBE_ROOT/$probe.js"
	"$TIMEOUT" --secs 30 -- node "$PROBE_ROOT/$probe.js"
	# Normal library builds use std DCE; full DCE alone can hide eager helpers.
	# These two boundaries prove absence and demand without doubling every test.
	modes=(full)
	case "$probe" in
		MapLookupDependencyProbe|MapInterfaceExportProbe) modes+=(std) ;;
	esac
	for mode in "${modes[@]}"; do
		output="$PROBE_ROOT/$probe-$mode"
		"$TIMEOUT" --secs 180 -- "$HAXE" -cp "$FIXTURE_DIR" -lib reflaxe.elixir \
			-main "$probe" -dce "$mode" -D no-traces -D reflaxe_elixir_validate_results -D "elixir_output=$output"
		case "$probe" in
			MapLookupDependencyProbe|CustomMapDependencyProbe|StructuralMethodProbe)
				if [[ -f "$output/reflaxe/elixir/i_map.ex" ]]; then
					echo "UNNECESSARY_ITERATOR_HELPER:$probe:$mode" >&2
					exit 1
				fi
				;;
			*)
				test -f "$output/reflaxe/elixir/i_map.ex"
				;;
		esac
		"$TIMEOUT" --secs 90 -- elixir -e '
      [root, name, mode] = System.argv()
      case Kernel.ParallelCompiler.compile(Path.wildcard(Path.join(root, "**/*.ex")), return_diagnostics: true) do
        {:ok, modules, %{compile_warnings: [], runtime_warnings: []}} -> IO.puts("MAP_MODULES:" <> name <> ":" <> mode <> ":" <> Integer.to_string(length(modules)))
        other -> raise inspect(other)
      end
      module = String.to_existing_atom("Elixir." <> name)
      if name == "MapInterfaceExportProbe" do
        # The external map has no concrete Haxe constructor to retain helpers.
        values = apply(module, :values, [%{"entry" => 13}])
        unless values.has_next.() and values.next.() == 13 and not values.has_next.(),
          do: raise("exported value iterator failed")
        pairs = apply(module, :pairs, [%{"entry" => 13}])
        unless pairs.has_next.() and pairs.next.() == %{key: "entry", value: 13} and not pairs.has_next.(),
          do: raise("exported pair iterator failed")
      else
        apply(module, :main, [])
      end
      IO.puts("MAP_RUNTIME_PASSED:" <> name <> ":" <> mode)
    ' -- "$output" "$probe" "$mode"
	done
done

# The dependency fix must preserve existing annotation-only modules, while
# honoring explicit conditions on either a native class or one of its fields.
retention_fixture="$FIXTURE_DIR/../empty_native_module_retention"
retention_output="$PROBE_ROOT/native-retention"
"$TIMEOUT" --secs 180 --cwd "$retention_fixture" -- "$HAXE" compile.hxml -D "elixir_output=$retention_output"
test -f "$retention_output/my_app_web/presence.ex"
test ! -f "$retention_output/retention/conditional_field.ex"
test ! -f "$retention_output/retention/conditional_class.ex"
echo "NATIVE_CONDITIONAL_RETENTION:PASS"
echo "MAP_RUNTIME_DEPENDENCIES:PASS"
