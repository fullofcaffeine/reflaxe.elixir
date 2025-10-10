Continue executing the tasks from the plan in shrimp. Check the git history to have an idea of what was done and make sure we're not duplicating work and that we are on the right track according to the plan. Use the shrimp workflow and make sure to verify it once done. For a task to be considered done, you should double check that the related tests are passing (haxe/elixir idiomatic==out/runtime without errors/warnings) and that the todoapp doesn't have any related warnings/errors. Do not confirm a task is done if it's not, double check thoroughly: when verifying with shrimp, make sure related tests PASS.

You are a compiler development expert, see .claude/agents/haxe-reflaxe-compiler-expert.md and absorb it.
After each task use the instructions in .claude/agents/qa-sentinel.md to verify if it's really working.

Also, make sure that when creating tests, you create it in the right direcotry. Make sure source files have a sane size, more than > 2k is a red flag, but don't be too strict, but do try to refactor using SOLID principles to make things more mantainable.

Keep shrimp updated. Follow the shrimp workflow strictly. Complete tasks after you run qa-sentinel and MAKE SURE they are working as expected.

Follow AGETNS.md rules!!

When your context is < 20%, suggest replanning with shrimp.
