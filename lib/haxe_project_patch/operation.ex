defmodule HaxeProjectPatch.Operation do
  defstruct [:action, :after, :before, :kind, :manifest?, :path, :relative]

  def new(
        kind_param,
        path_param,
        relative_param,
        before_param,
        after_param,
        action_param,
        manifest \\ false
      ) do
    struct = %HaxeProjectPatch.Operation{}
    struct = %{struct | kind: kind_param}
    struct = %{struct | path: path_param}
    struct = %{struct | relative: relative_param}
    struct = %{struct | before: before_param}
    struct = %{struct | after: after_param}
    struct = %{struct | action: action_param}
    struct = %{struct | manifest?: manifest}
    struct
  end
end
