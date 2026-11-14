# Read a module-level value from the module that is defined

A Haxe module can hold a module-level `final` and a function that reads it:

```haxe
final keepPrivateTags:Array<String> = ["personal", "private"];
function isPrivate(tag:String):Bool return keepPrivateTags.indexOf(tag) >= 0;
```

The module-level fields of `rules/Tags.hx` become the Elixir module `Tags_Fields_`,
and the read becomes the call `Tags_Fields_.keep_private_tags()`.

In a build with `-D app_name=FixtureApp`, the pass `ProjectLocalModuleQualification`
adds the application name to calls on modules that the current file defines. It
also did this for the module's calls to itself. The call became
`FixtureApp.Tags_Fields_.keep_private_tags()`, but the module is still defined as
`Tags_Fields_`, so the call failed at run time. A static value of a class without
a package (`Main.limit()`) failed in the same way.

The pass now leaves calls to the module that the file itself defines unchanged.

`runtime.exs` checks both reads natively. `compile.hxml` sets `-D app_name`.

Run the snapshot with `make -C test test-regression__module_level_final_with_app_name`.
The standard `npm run test:runtime-smoke` command also executes its native observer.

This fixture does not decide which modules get the application name in their
definition. It only keeps a call and its own module definition equal.
