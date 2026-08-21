# Official Haxe BEAM Smoke

This directory contains two unchanged tests from Haxe 4.3.7:

- one shared-language test;
- one compiler issue test.

The standard-library part of the smoke uses the existing official `Date.unit.hx` fixture.

`manifest.json` records each official source path and SHA-256 value. The guard rejects a changed, missing, or unclassified fixture.

The package smoke installs the release ZIP in an isolated Haxelib repository. It then compiles these tests with that installed package. Mix rejects Elixir warnings, and ExUnit runs the generated tests on BEAM.

The local `unit.Test` class is an adapter. It adds ExUnit metadata and converts upstream assertion calls to the typed Haxe ExUnit API. It does not change the official test files.
