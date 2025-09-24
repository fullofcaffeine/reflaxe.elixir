ok, let's take that issue that into the existing shrimp plan that thinks carefully about a solution, updating what's needed and then replanning thoroughly, this new state should be integrated into the current plan's graph, also 
aking sure we don't miss any steps until 1.0. Double check the plan with Codex, and add that as part of the plan: 1) You should let tests drive the development, with idiomatic intetnded results; 2) todoapp will function as a overall e2e test that will also verify that the compiler reaches 1.0 - todoapp
should compile in haxe and elixir without errors and warnings and no runtime errors either; 3) if you get stuck, give codex detailed info and context about the issue and verify its reply to unblock, then replan
i n shrimp to reintegrate the solution with this prompt if needed. You should also refer to the git history to make sure you understand what you worked on before, and that you are not duplicating work!
Ultrathink your way to it. This is like a map->reduce process that makes sure we're always focusing on the right tasks and efficiently using context and model power, makes sure we have the holistic plan updated with all the necessary knowledge to allow the model to focus efficiently without losing precious knowledge and prevent it from walking in circles.

For reference, you can check the source code for reflaxe, reflaxe reference compilers, haxe, pheonix and elixir in the haxe.elixir.refernece directory. Please refer to them often to learn good patterns and best practices for us to follow and integrate into our tasks.

Also, make sure that when creating tests, you create it in the right direcotry. Make sure source files have a sane size, more than > 2k is a red flag, but don't be too strict, but do try to refactor using SOLID principles to make things more mantainable. 

Follow CLAUDE.md rules!!
