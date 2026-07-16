defmodule ManagedReferenceSpike.HybridHeapTest do
  use ExUnit.Case, async: false

  alias ManagedReferenceSpike.HybridHeap
  alias ManagedReferenceSpike.Native

  setup do
    start_supervised!(HybridHeap)
    |> then(&{:ok, heap: &1})
  end

  test "destructor leases make Elixir-owned graph state observable through aliases", %{heap: heap} do
    reference = HybridHeap.new(heap, 3)
    alias_reference = reference

    task = Task.async(fn -> HybridHeap.put(alias_reference, 9) end)
    assert Task.await(task) == 9
    assert HybridHeap.get(reference) == 9

    clone = HybridHeap.clone(reference)
    assert HybridHeap.same(reference, clone)
    assert HybridHeap.stats(heap).external_roots == 2
  end

  test "the hybrid collector reclaims cycles after destructor notifications", %{heap: heap} do
    parent = self()

    {pid, monitor} =
      spawn_monitor(fn ->
        left = HybridHeap.new(heap, 1)
        right = HybridHeap.new(heap, 2)
        {:ok, left_id} = Native.hybrid_id(left.lease)
        {:ok, right_id} = Native.hybrid_id(right.lease)
        assert HybridHeap.set_strong_nested(left, right) == {:ok, 1}
        assert HybridHeap.set_strong_nested(right, left) == {:ok, 1}
        send(parent, {:hybrid_cycle, left_id, right_id})
      end)

    assert_receive {:hybrid_cycle, left_id, right_id}
    assert_receive {:DOWN, ^monitor, :process, ^pid, :normal}
    eventually(fn -> HybridHeap.stats(heap).external_roots == 0 end)

    assert HybridHeap.collect(heap) == 2
    assert HybridHeap.object_info(heap, left_id) == {:error, :not_found}
    assert HybridHeap.object_info(heap, right_id) == {:error, :not_found}
  end

  test "weak edges and closure gaps match the native candidate's explicit contract", %{heap: heap} do
    owner = HybridHeap.new(heap, 1)
    target = HybridHeap.new(heap, 2)
    {:ok, target_id} = Native.hybrid_id(target.lease)

    assert HybridHeap.set_weak_nested(owner, target) == {:ok, 1}
    assert HybridHeap.set_strong_nested(owner, fn -> target end) == {:error, :opaque_closure}

    target = nil
    :erlang.garbage_collect()

    eventually(fn ->
      HybridHeap.object_info(heap, target_id) ==
        {:ok, %{id: target_id, roots: 0, strong_edges: 0, value: 2, weak_edges: 0}}
    end)

    assert HybridHeap.collect(heap) == 1
    assert HybridHeap.weak_ids(owner) == []
    assert target == nil
  end

  test "owner-process death invalidates otherwise live handles", %{heap: heap} do
    reference = HybridHeap.new(heap, 7)
    GenServer.stop(heap)

    assert HybridHeap.get(reference) == {:error, :heap_down}
  end

  defp eventually(assertion) do
    deadline = System.monotonic_time(:millisecond) + 2_000
    do_eventually(assertion, deadline)
  end

  defp do_eventually(assertion, deadline) do
    if assertion.() do
      :ok
    else
      if System.monotonic_time(:millisecond) >= deadline do
        flunk("condition did not become true before the bounded deadline")
      else
        Process.sleep(10)
        do_eventually(assertion, deadline)
      end
    end
  end
end
