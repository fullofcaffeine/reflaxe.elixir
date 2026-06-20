defmodule BehaviorsExampleTest do
  use ExUnit.Case, async: true

  defp batch_struct do
    %{:__struct__ => BatchProcessor}
  end

  defp stream_struct(processing_state \\ %{processed_count: 0, errors: 0}) do
    %{:__struct__ => StreamProcessor, processing_state: processing_state}
  end

  test "behavior contract stubs raise until implemented" do
    assert_raise Reflaxe.Elixir.HaxeThrow, fn ->
      DataProcessor.init(nil, %{batch_size: 2})
    end

    assert_raise Reflaxe.Elixir.HaxeThrow, fn ->
      DataProcessor.process_item(nil, %{id: 1, payload: "alpha"}, %{processed_count: 0, errors: 0})
    end

    assert_raise Reflaxe.Elixir.HaxeThrow, fn ->
      DataProcessor.get_stats(nil)
    end
  end

  test "batch processor validates items and flushes a full batch into state" do
    struct = batch_struct()
    init_response = BatchProcessor.init(struct, %{batch_size: 2})

    assert init_response.error == ""
    assert init_response.ok.batch_size == 2
    assert init_response.ok.current_batch == []

    first_item = %{id: 1, payload: "alpha"}
    second_item = %{id: 2, payload: "beta"}

    first_response = BatchProcessor.process_item(struct, first_item, init_response.ok)

    assert first_response.result.original == first_item
    assert first_response.new_state.current_batch == [first_item]
    assert first_response.new_state.processed_count == 0

    second_response = BatchProcessor.process_item(struct, second_item, first_response.new_state)

    assert second_response.result.original == second_item
    assert second_response.new_state.current_batch == []
    assert second_response.new_state.processed_count == 2
    assert second_response.new_state.batches_processed == 1
    assert second_response.new_state.total_items == 2

    invalid_response =
      BatchProcessor.process_item(struct, %{id: 0, payload: "bad"}, second_response.new_state)

    assert invalid_response.new_state.errors == 1
    assert invalid_response.new_state.processed_count == 2
  end

  test "stream processor processes batches one item at a time" do
    struct = stream_struct()
    initial_state = %{processed_count: 0, errors: 0, last_processed: nil}
    items = [%{id: 1, payload: "alpha"}, %{id: 2, payload: "beta"}]

    batch_response = StreamProcessor.process_batch(struct, items, initial_state)

    assert Enum.map(batch_response.results, & &1.original) == items
    assert Enum.all?(batch_response.results, &(&1.stream_id == "stream_001"))
    assert batch_response.new_state.processed_count == 2
    assert batch_response.new_state.errors == 0
    assert batch_response.new_state.last_processed.original == List.last(items)

    invalid_response = StreamProcessor.process_item(struct, nil, batch_response.new_state)

    assert invalid_response.new_state.processed_count == 2
    assert invalid_response.new_state.errors == 1

    stats =
      stream_struct(%{processed_count: 9, errors: 1})
      |> StreamProcessor.get_stats()

    assert stats == %{
             type: "stream_processor",
             processed_count: 9,
             error_count: 1,
             status: "active"
           }
  end
end
