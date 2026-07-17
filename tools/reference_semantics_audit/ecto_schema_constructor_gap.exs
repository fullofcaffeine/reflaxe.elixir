repo_root = Path.expand("../..", __DIR__)
snapshot = Path.join(repo_root, "test/snapshot/ecto/ecto_schema/intended/my_app/user.ex")

Application.ensure_all_started(:ecto)

# The example fixture used to supply Ecto on the Mix path may already define this module. Remove
# that loaded copy so this probe exercises the checked-in compiler snapshot and nothing else.
Code.ensure_loaded(MyApp.User)
:code.delete(MyApp.User)
:code.purge(MyApp.User)

ignore_module_conflict = Code.get_compiler_option(:ignore_module_conflict)

try do
  Code.put_compiler_option(:ignore_module_conflict, true)
  Code.compile_file(snapshot)
after
  Code.put_compiler_option(:ignore_module_conflict, ignore_module_conflict)
end

value = MyApp.User.new()

unless is_map(value) and not is_struct(value, MyApp.User) and
         Map.get(value, :__reflaxe_class__) == MyApp.User do
  raise "expected the current constructor gap: new/0 must still return a tagged map, not an Ecto struct"
end

rejected =
  try do
    Ecto.Changeset.change(value)
    false
  rescue
    FunctionClauseError -> true
  end

unless rejected do
  raise "expected Ecto.Changeset.change/1 to reject the tagged-map constructor result"
end

IO.puts("confirmed: current Ecto schema new/0 returns a tagged map rejected by Ecto.Changeset.change/1")
