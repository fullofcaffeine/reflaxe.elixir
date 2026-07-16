defmodule ManagedReferenceSpike.NativeHeapTest do
  use ExUnit.Case, async: false

  alias ManagedReferenceSpike.Native

  setup do
    :erlang.garbage_collect()
    eventually(fn -> Native.stats().external_roots == 0 end)
    Native.collect()
    Native.reset()
    :ok
  end

  test "allocation identity and alias-visible mutation survive process transfer" do
    first = Native.new_object(7)
    second = Native.new_object(7)
    alias_of_first = first

    assert Native.same(first, alias_of_first)
    refute Native.same(first, second)

    task = Task.async(fn -> Native.put(alias_of_first, 11) end)
    assert Task.await(task) == 11
    assert Native.get(first) == 11
  end

  test "concurrent updates are individually linearizable" do
    reference = Native.new_object(0)

    1..8
    |> Enum.map(fn _ ->
      Task.async(fn ->
        Enum.each(1..1_000, fn _ -> Native.increment(reference, 1) end)
      end)
    end)
    |> Enum.each(&Task.await(&1, 5_000))

    assert Native.get(reference) == 8_000
  end

  test "lease destruction and collection serialize safely with active graph reads" do
    owner = Native.new_object(0)
    target = Native.new_object(0)
    {_token, target_id} = Native.descriptor(target)
    assert Native.set_strong_nested(owner, target) == {:ok, 1}

    collector =
      Task.async(fn ->
        Enum.each(1..200, fn _ -> Native.collect() end)
      end)

    1..100
    |> Enum.map(fn _ ->
      Task.async(fn ->
        alias_reference = Native.lease_for(owner, target_id)
        Native.increment(alias_reference, 1)
      end)
    end)
    |> Enum.each(&Task.await(&1, 5_000))

    Task.await(collector, 5_000)
    assert Native.get(target) == 100
    assert Native.collect() == 0
  end

  test "the last lease destructor removes the external root" do
    parent = self()

    {pid, monitor} =
      spawn_monitor(fn ->
        reference = Native.new_object(19)
        send(parent, {:descriptor, Native.descriptor(reference)})
      end)

    assert_receive {:descriptor, {token, id}}
    assert_receive {:DOWN, ^monitor, :process, ^pid, :normal}
    eventually(fn -> match?({:ok, %{roots: 0}}, Native.object_info(id)) end)

    assert Native.collect() == 1
    assert Native.object_info(id) == {:error, :not_found}
    assert Native.resolve(token, id) == {:error, :not_found}
  end

  test "nested containers become strong object-id edges without retaining lease terms" do
    parent = self()

    {pid, monitor} =
      spawn_monitor(fn ->
        owner = Native.new_object(1)
        left = Native.new_object(2)
        right = Native.new_object(3)
        {_owner_token, owner_id} = Native.descriptor(owner)
        {_left_token, left_id} = Native.descriptor(left)
        {_right_token, right_id} = Native.descriptor(right)

        assert Native.set_strong_nested(owner, %{items: [left, {:wrapped, right}]}) == {:ok, 2}
        send(parent, {:graph, owner, owner_id, left_id, right_id})
      end)

    assert_receive {:graph, owner, _owner_id, left_id, right_id}
    assert_receive {:DOWN, ^monitor, :process, ^pid, :normal}

    eventually(fn ->
      Native.object_info(left_id) ==
        {:ok, %{id: left_id, roots: 0, strong_edges: 0, value: 2, weak_edges: 0}}
    end)

    assert MapSet.new(Native.strong_ids(owner)) == MapSet.new([left_id, right_id])
    assert Native.collect() == 0

    left_alias = Native.lease_for(owner, left_id)
    assert Native.get(left_alias) == 2
  end

  test "a doubly linked cycle is reclaimed after both last leases disappear" do
    parent = self()

    {pid, monitor} =
      spawn_monitor(fn ->
        left = Native.new_object(1)
        right = Native.new_object(2)
        {_token, left_id} = Native.descriptor(left)
        {_token, right_id} = Native.descriptor(right)
        assert Native.set_strong_nested(left, right) == {:ok, 1}
        assert Native.set_strong_nested(right, left) == {:ok, 1}
        send(parent, {:cycle, left_id, right_id})
      end)

    assert_receive {:cycle, left_id, right_id}
    assert_receive {:DOWN, ^monitor, :process, ^pid, :normal}
    eventually(fn -> Native.stats().external_roots == 0 end)

    assert Native.collect() == 2
    assert Native.object_info(left_id) == {:error, :not_found}
    assert Native.object_info(right_id) == {:error, :not_found}
  end

  test "weak edges do not keep their target alive" do
    parent = self()

    {pid, monitor} =
      spawn_monitor(fn ->
        owner = Native.new_object(1)
        target = Native.new_object(2)
        {_token, target_id} = Native.descriptor(target)
        assert Native.set_weak_nested(owner, target) == {:ok, 1}
        send(parent, {:weak_graph, owner, target_id})
      end)

    assert_receive {:weak_graph, owner, target_id}
    assert_receive {:DOWN, ^monitor, :process, ^pid, :normal}
    eventually(fn -> match?({:ok, %{roots: 0}}, Native.object_info(target_id)) end)

    assert Native.collect() == 1
    assert Native.weak_ids(owner) == []
    assert Native.object_info(target_id) == {:error, :not_found}
  end

  test "opaque closures and foreign carriers fail instead of hiding graph edges" do
    owner = Native.new_object(1)
    hybrid = Native.new_hybrid_lease(self(), 99)
    caller = self()
    callback = fn -> send(caller, :closure_was_executed) end

    assert Native.set_strong_nested(owner, callback) == {:error, :opaque_closure}
    assert Native.set_strong_nested(owner, hybrid) == {:error, :foreign_carrier}
    assert Native.strong_ids(owner) == []
    refute_received :closure_was_executed
  end

  test "resource takeover preserves live leases across a module code reload" do
    reference = Native.new_object(55)
    beam_path = Native |> :code.which() |> List.to_string()
    {:ok, beam} = File.read(beam_path)

    assert {:module, Native} ==
             :code.load_binary(Native, ~c"managed_reference_spike_hot_upgrade", beam)

    assert Native.get(reference) == 55
  end

  test "a remote VM rejects raw leases and node-local descriptors deterministically" do
    assert Node.alive?()
    paths = Enum.flat_map(:code.get_path(), fn path -> [~c"-pa", path] end)
    peer_name = String.to_atom("managed_reference_peer_#{System.unique_integer([:positive])}")

    {:ok, peer, peer_node} =
      :peer.start_link(%{name: peer_name, connection: :standard_io, args: paths})

    on_exit(fn ->
      try do
        :peer.stop(peer)
      catch
        :exit, _reason -> :ok
      end
    end)

    assert {_major, _minor, _word_size} = :rpc.call(peer_node, Native, :nif_info, [])

    reference = Native.new_object(41)
    {token, id} = Native.descriptor(reference)

    assert :rpc.call(peer_node, Native, :get, [reference]) ==
             {:error, :wrong_node_or_stale}

    assert :rpc.call(peer_node, Native, :resolve, [token, id]) == {:error, :wrong_node}
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
