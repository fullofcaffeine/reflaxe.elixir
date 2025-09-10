defmodule TypedQuery do
  @query nil
  @schema_type nil
  def where(struct, _predicate) do
    struct
  end
  def where_raw(struct, condition, params) do
    query = EctoQuery_Impl_.where(struct.query, condition, params)
    struct
  end
  def select(struct, _projection) do
    struct
  end
  def select_raw(struct, _fields) do
    struct
  end
  def order_by(struct, _field, _direction) do
    struct
  end
  def order_by_raw(struct, _clause) do
    struct
  end
  def join(struct, _relation, _alias) do
    struct
  end
  def join_raw(struct, _clause) do
    struct
  end
  def group_by(struct, _field) do
    struct
  end
  def having(struct, _predicate) do
    struct
  end
  def limit(struct, count) do
    query = EctoQuery_Impl_.limit(struct.query, count)
    struct
  end
  def offset(struct, count) do
    query = EctoQuery_Impl_.offset(struct.query, count)
    struct
  end
  def preload(struct, associations) do
    query = EctoQuery_Impl_.preload(struct.query, associations)
    struct
  end
  def lock(struct, _type) do
    struct
  end
  def to_ecto_query(struct) do
    struct.query
  end
  def all(struct) do
    Repo.all(struct.query)
  end
  def first(struct) do
    Repo.one(EctoQuery_Impl_.limit(struct.query, 1))
  end
  def one(struct) do
    Repo.one!(struct.query)
  end
  def exists(struct) do
    Repo.exists?(struct.query)
  end
  def count(struct) do
    Std.int(Repo.aggregate(struct.query, "count", "*"))
  end
  def stream(struct) do
    Repo.stream(struct.query)
  end
  def from(schema) do
    TypedQuery.new(schema)
  end
end