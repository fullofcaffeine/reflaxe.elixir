defmodule ManagedReferenceSpike.HybridHeap do
  @moduledoc false

  use GenServer

  alias ManagedReferenceSpike.Native

  defmodule Ref do
    @moduledoc false
    @enforce_keys [:owner, :lease]
    defstruct [:owner, :lease]
  end

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, :ok, options)
  end

  def new(owner, value), do: safe_call(owner, {:new, value})

  def clone(%Ref{} = reference) do
    with {:ok, id} <- reference_id(reference) do
      safe_call(reference.owner, {:clone, id})
    end
  end

  def same(%Ref{owner: owner} = left, %Ref{owner: owner} = right) do
    with {:ok, left_id} <- reference_id(left),
         {:ok, right_id} <- reference_id(right) do
      left_id == right_id
    end
  end

  def same(%Ref{}, %Ref{}), do: false

  def get(%Ref{} = reference), do: call_reference(reference, :get)

  def put(%Ref{} = reference, value) do
    call_reference(reference, {:put, value})
  end

  def increment(%Ref{} = reference, delta) do
    call_reference(reference, {:increment, delta})
  end

  def set_strong_nested(%Ref{} = owner, nested) do
    with {:ok, owner_id} <- reference_id(owner),
         {:ok, ids} <- extract_ids(nested, owner.owner) do
      safe_call(owner.owner, {:set_edges, owner_id, :strong, ids})
    end
  end

  def set_weak_nested(%Ref{} = owner, nested) do
    with {:ok, owner_id} <- reference_id(owner),
         {:ok, ids} <- extract_ids(nested, owner.owner) do
      safe_call(owner.owner, {:set_edges, owner_id, :weak, ids})
    end
  end

  def strong_ids(%Ref{} = reference), do: call_reference(reference, {:edges, :strong})
  def weak_ids(%Ref{} = reference), do: call_reference(reference, {:edges, :weak})

  def lease_for(%Ref{} = owner, object_id) do
    call_reference(owner, {:lease_for, object_id})
  end

  def object_info(owner, object_id), do: safe_call(owner, {:object_info, object_id})
  def stats(owner), do: safe_call(owner, :stats)
  def collect(owner), do: safe_call(owner, :collect)

  @impl true
  def init(:ok) do
    {:ok, %{next_id: 1, objects: %{}, lease_destructors: 0, collections: 0}}
  end

  @impl true
  def handle_call({:new, value}, _from, state) when is_integer(value) do
    id = state.next_id
    object = %{value: value, roots: 1, strong: MapSet.new(), weak: MapSet.new()}
    reference = %Ref{owner: self(), lease: Native.new_hybrid_lease(self(), id)}

    {:reply, reference, %{state | next_id: id + 1, objects: Map.put(state.objects, id, object)}}
  end

  def handle_call({:clone, id}, _from, state) do
    case Map.fetch(state.objects, id) do
      :error ->
        {:reply, {:error, :not_found}, state}

      {:ok, object} ->
        reference = %Ref{owner: self(), lease: Native.new_hybrid_lease(self(), id)}
        objects = Map.put(state.objects, id, %{object | roots: object.roots + 1})
        {:reply, reference, %{state | objects: objects}}
    end
  end

  def handle_call({:get, id}, _from, state) do
    reply = with {:ok, object} <- Map.fetch(state.objects, id), do: object.value
    {:reply, normalize_fetch(reply), state}
  end

  def handle_call({:put, id, value}, _from, state) when is_integer(value) do
    update_value(state, id, fn _current -> value end)
  end

  def handle_call({:increment, id, delta}, _from, state) when is_integer(delta) do
    update_value(state, id, fn current -> current + delta end)
  end

  def handle_call({:set_edges, owner_id, kind, ids}, _from, state) do
    with {:ok, owner} <- Map.fetch(state.objects, owner_id),
         true <- Enum.all?(ids, &Map.has_key?(state.objects, &1)) do
      unique_ids = MapSet.new(ids)
      updated = Map.put(owner, kind, unique_ids)

      {:reply, {:ok, MapSet.size(unique_ids)},
       %{state | objects: Map.put(state.objects, owner_id, updated)}}
    else
      _ -> {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:edges, id, kind}, _from, state) do
    reply =
      case Map.fetch(state.objects, id) do
        :error -> {:error, :not_found}
        {:ok, object} -> object |> Map.fetch!(kind) |> MapSet.to_list()
      end

    {:reply, reply, state}
  end

  def handle_call({:lease_for, owner_id, target_id}, _from, state) do
    with {:ok, owner} <- Map.fetch(state.objects, owner_id),
         {:ok, target} <- Map.fetch(state.objects, target_id),
         true <- MapSet.member?(owner.strong, target_id) or MapSet.member?(owner.weak, target_id) do
      reference = %Ref{owner: self(), lease: Native.new_hybrid_lease(self(), target_id)}
      objects = Map.put(state.objects, target_id, %{target | roots: target.roots + 1})
      {:reply, reference, %{state | objects: objects}}
    else
      _ -> {:reply, {:error, :not_found}, state}
    end
  end

  def handle_call({:object_info, id}, _from, state) do
    reply =
      case Map.fetch(state.objects, id) do
        :error ->
          {:error, :not_found}

        {:ok, object} ->
          {:ok,
           %{
             id: id,
             value: object.value,
             roots: object.roots,
             strong_edges: MapSet.size(object.strong),
             weak_edges: MapSet.size(object.weak)
           }}
      end

    {:reply, reply, state}
  end

  def handle_call(:stats, _from, state) do
    roots = Enum.reduce(state.objects, 0, fn {_id, object}, total -> total + object.roots end)

    {:reply,
     %{
       live_objects: map_size(state.objects),
       external_roots: roots,
       lease_destructors: state.lease_destructors,
       collections: state.collections
     }, state}
  end

  def handle_call(:collect, _from, state) do
    reachable = mark_reachable(state.objects)

    survivors =
      state.objects
      |> Map.take(MapSet.to_list(reachable))
      |> prune_weak_edges()

    collected = map_size(state.objects) - map_size(survivors)
    {:reply, collected, %{state | objects: survivors, collections: state.collections + 1}}
  end

  @impl true
  def handle_info({:hybrid_lease_down, id}, state) do
    objects =
      case Map.fetch(state.objects, id) do
        :error -> state.objects
        {:ok, object} -> Map.put(state.objects, id, %{object | roots: max(object.roots - 1, 0)})
      end

    {:noreply, %{state | objects: objects, lease_destructors: state.lease_destructors + 1}}
  end

  defp call_reference(%Ref{} = reference, operation) do
    with {:ok, id} <- reference_id(reference) do
      message =
        case operation do
          :get -> {:get, id}
          {:put, value} -> {:put, id, value}
          {:increment, delta} -> {:increment, id, delta}
          {:edges, kind} -> {:edges, id, kind}
          {:lease_for, target_id} -> {:lease_for, id, target_id}
        end

      safe_call(reference.owner, message)
    end
  end

  defp reference_id(%Ref{lease: lease}), do: Native.hybrid_id(lease)

  defp safe_call(owner, message) do
    try do
      GenServer.call(owner, message, 5_000)
    catch
      :exit, _reason -> {:error, :heap_down}
    end
  end

  defp update_value(state, id, update) do
    case Map.fetch(state.objects, id) do
      :error ->
        {:reply, {:error, :not_found}, state}

      {:ok, object} ->
        value = update.(object.value)
        objects = Map.put(state.objects, id, %{object | value: value})
        {:reply, value, %{state | objects: objects}}
    end
  end

  defp normalize_fetch(:error), do: {:error, :not_found}
  defp normalize_fetch(value), do: value

  defp extract_ids(nested, owner) do
    case do_extract_ids(nested, owner, MapSet.new()) do
      {:ok, ids} -> {:ok, MapSet.to_list(ids)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_extract_ids(%Ref{owner: owner} = reference, owner, ids) do
    case reference_id(reference) do
      {:ok, id} -> {:ok, MapSet.put(ids, id)}
      {:error, reason} -> {:error, reason}
    end
  end

  defp do_extract_ids(%Ref{}, _owner, _ids), do: {:error, :wrong_heap}
  defp do_extract_ids(value, _owner, _ids) when is_function(value), do: {:error, :opaque_closure}

  defp do_extract_ids(value, owner, ids) when is_list(value) do
    reduce_nested(value, owner, ids)
  end

  defp do_extract_ids(value, owner, ids) when is_tuple(value) do
    value |> Tuple.to_list() |> reduce_nested(owner, ids)
  end

  defp do_extract_ids(value, owner, ids) when is_map(value) do
    value
    |> Enum.flat_map(fn {key, nested_value} -> [key, nested_value] end)
    |> reduce_nested(owner, ids)
  end

  defp do_extract_ids(value, _owner, ids) do
    case Native.descriptor(value) do
      {token, id} when is_integer(token) and is_integer(id) -> {:error, :foreign_carrier}
      {:error, :wrong_node_or_stale} -> {:ok, ids}
    end
  end

  defp reduce_nested(values, owner, ids) do
    Enum.reduce_while(values, {:ok, ids}, fn value, {:ok, current} ->
      case do_extract_ids(value, owner, current) do
        {:ok, updated} -> {:cont, {:ok, updated}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp mark_reachable(objects) do
    roots = for {id, object} <- objects, object.roots > 0, do: id
    mark_queue(roots, objects, MapSet.new())
  end

  defp mark_queue([], _objects, visited), do: visited

  defp mark_queue([id | rest], objects, visited) do
    if MapSet.member?(visited, id) do
      mark_queue(rest, objects, visited)
    else
      case Map.fetch(objects, id) do
        :error ->
          mark_queue(rest, objects, visited)

        {:ok, object} ->
          mark_queue(MapSet.to_list(object.strong) ++ rest, objects, MapSet.put(visited, id))
      end
    end
  end

  defp prune_weak_edges(objects) do
    live = objects |> Map.keys() |> MapSet.new()

    Map.new(objects, fn {id, object} ->
      {id, %{object | weak: MapSet.intersection(object.weak, live)}}
    end)
  end
end
