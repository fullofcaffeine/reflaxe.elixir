@typedoc """

	An `Iterator` is a structure that permits iteration over elements of type `T`.

	Any class with matching `hasNext()` and `next()` fields is considered an `Iterator`
	and can then be used e.g. in `for`-loops. This makes it easy to implement
	custom iterators.

	@see https://haxe.org/manual/lf-iterators.html

"""
@type iterator(t) :: %{
  has_next: (() -> boolean()),
  next: (() -> t)
}

@typedoc """

	An `Iterable` is a data structure which has an `iterator()` method.
	See `Lambda` for generic functions on iterable structures.

	@see https://haxe.org/manual/lf-iterators.html

"""
@type iterable(t) :: %{
  iterator: (() -> iterator(t))
}

@typedoc """

	A `KeyValueIterator` is an `Iterator` that has a key and a value.

"""
@type key_value_iterator(k, v) :: iterator(%{
  key: k,
  value: v
})

@typedoc """

	A `KeyValueIterable` is a data structure which has a `keyValueIterator()`
	method to iterate over key-value-pairs.

"""
@type key_value_iterable(k, v) :: %{
  key_value_iterator: (() -> key_value_iterator(k, v))
}