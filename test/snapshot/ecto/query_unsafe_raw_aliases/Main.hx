import ecto.TypedQuery;

class User {}

class Main {
	public static function explicitUnsafe(search:String, minimumAge:Int):TypedQuery<User> {
		var query = TypedQuery.from(User);
		query = query.whereUnsafeRaw("name ILIKE ?", search);
		query = query.whereUnsafeRaw("age >= ?", minimumAge);
		return query.orderByUnsafeRaw("CASE WHEN role = 'admin' THEN 0 ELSE 1 END, inserted_at DESC");
	}

	public static function compatibilityAliases(search:String, minimumAge:Int):TypedQuery<User> {
		var query = TypedQuery.from(User);
		query = query.whereRaw("name ILIKE ?", search);
		query = query.whereRaw("age >= ?", minimumAge);
		return query.orderByRaw("CASE WHEN role = 'admin' THEN 0 ELSE 1 END, inserted_at DESC");
	}
}
