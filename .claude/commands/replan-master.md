Commit all changes describing the progress so far now, and let's work on a thoroguh plan **that will lead us to haxe.elixir 1.0 and the todoapp working well after compiled with it**.

The plan shouldn't be too general, it should be as specfiic as we can make it with the information we gather now << THIS IS VERY IMPORTANT. We don't want the work to be delegated to hte execution part of the
process. The execution should, for the most part, just follow instructions. It can research a thing or two, but it should be the exception. If the plan is not complete, then the agent shoudl suggest updating the
task or the whole plan based on what's missing <<< THIS IS VERY IMPORTANT AND KEY FOR THE PROCESS TO WORK.

A very important directive to add as part of each shrimp task is to NOT couple the compiler logic to sepecific todoapp code, like todoapp var names, shapes etc. The compiler should ot be tied to any example or
app or any code that's being compiled to it specifically!!!

ok, check the state of the system in the shrimp plan and code, all that we've learned in this session, the delta agains the goal (what's done, what's left to be done), the state of the system, things remainig to
fix, create an UPDATED PRD plan to 1.0, then integrate that plan with the current shrimp plan. You should take
what's in the shrimp plan, discard what's not relevant anymore, and integrate our new plan and add to the shrimp plan again so tasks are split and prioritized. Use .claude/commands/replan.md and .claude/
agents/haxe-reflaxe-compiler-expert.md.

You should thoroughly research what's left for the compiler to be finished and todoapp to be compiled and working. You should let the user know about this.

> > Don't use "quick-win" solutions if there's a clean architectural way to do it. We want the compiler to be clean and maintainable, not a hacky mess that works for now but will be hard to maintain in the future. This should be added as a directive to each shrimp task.<<

  <IMPORTANT>

Based on the data in this session, Reprioritze accordingly! The plan in shrimp should be taken as a basis, and the info in this session integrated following the instructions in this promp.

Make sure we're creating tranfomers wisely and only if needed. Make sure they are general enough and if there aren't existing tranfomrers that can be adapted/used. Don't overuse transformers, us ethem wisely!!!

Update the plan accordingly -- make sure to remove tasks that are not relevant anymore. This process should work like a kind of effective reduce process that gets us closer to the goal with very detailed and
specific plans for GPT5 to leverage and achieve the goals more easily and effectivelly.

Use the shrimp workflow - process_thought tool and the reflect_task, etc, ask the tool - to first analyze and research the plan thoroughly before itegrating it. The plan should ideally have a waterfall-like
step-by-step instruction on how to get to 1.0 with no or few questions on the way. Finally, after going through this process, get the full plan on shrimp and integrate with the new one, deprcate what's already
done or non-relevant.

Remember, you're a compiler development expert and you're a Haxe and Elixir expert, too. Follow the instructions on .claude/agents/haxe-reflaxe-compiler-expert.md.

> > > After each task, use the qa-sentinel to verify .claude/agents/qa-sentinel.md << THIS IS VERY IMPORTANT and shuld be encoded in each task!
> > > After each task, tell me how far we are from 1.0/todoapp working without erorrs/warnings/runtime errors. Show me the percentage progress.
> > > IMPORTANT: DO NOT GROW SOURCE FILeS THAT ARE > 2000 lines. If you have an opporuntity to improve the code by extracting/modularizing, then do it. This is a hard directive that you should follow and should be part
> > > of all tasks in shrimp.

-> Proper architectural root fixes and not app-specific ones/bandaids!!!
-> Don't edit ex files directly, we're working on a compiler, editing ex files directly should be the exception and you should first ask / tell me why. Otherwise, it shouldbe generted by compiling hx code via the
haxe->elixir compiler pipeline
-> To automatically debug the phoenix app when it starts, you should start it in the background and use curl to check the html output. You should also pay attention to the shell output of phx.server. We shall not
tolarate any warnings or errors there, either, they should all be tackled following the principles here.

Any compilation issues found in elixir or haxe should be analysed from the architectural perspective and we should consider if we need to change anything at the higher level insead of specific ad-hoc issues that
might pollute and cause the code to be unmaintainable. In sum, we should make sure that architecture of the compiler is right and supports its funcitonality well.

THe todoapp should work beautifully but because it's a e2e test for the compiler. If it works well, it means the compiler is (probably) working well, too!

EACH SHRIMP TASK SHOULD HAVE ALL THE ASPECTS DESCRIBED HERE SO THE AGENT KNOWS WHAT TO DO AND QUALITY OF THE OUTPUT DOES NOT DEGRADE.

YOU SHOULD PROVIDE A DETAILED REPORT (WHICH IS THE PLAN) OF WHAT IS LEFT TO COMPLETE V1.0 FOR THE PROJECT.

YOU SHOULD ALSO COMPARE WHAT WE DID IN THIS SESSION TO WHAT NEEDS TO BE DONE AND INCLUDE THIS DELTA INFO AS PART OF THE NEW PLAN SO WE CAN TRACK PROGRESS BETTER AND KNOW WE'RE NOT WALKING IN CIRCLES - THIS IS VERY IMPORTANT, WE SHOULD REACH A POINT WHERE WE CAN SAY WE REACHED THE GOALS NAD NOT BE WORKING ON THIS FOREVER.

Follow the instructions strictly. Execute the plan in shrimp following the shrimp workflow.
