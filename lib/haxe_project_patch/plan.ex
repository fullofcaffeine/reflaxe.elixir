defmodule HaxeProjectPatch.Plan do
  defstruct [:operations, :root, :seen_paths]

  def new(root_param) do
    struct = %HaxeProjectPatch.Plan{}
    struct = %{struct | root: root_param}
    struct = %{struct | operations: []}
    struct = %{struct | seen_paths: MapSet.new()}
    struct
  end
end
