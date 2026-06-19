package;

import ecto.Association;
import ecto.TypedQuery;
import ecto.TypedQuery.JoinType;

class Main {
	public static function typedQueryPreload():ecto.EctoQueryStruct {
		return TypedQuery.from(User).preloadAssociations([Association.of((user:User) -> user.posts)]).query;
	}

	public static function typedQueryJoin():ecto.EctoQueryStruct {
		return TypedQuery.from(Post).joinAssociation(Association.of((post:Post) -> post.user), Left).query;
	}

	public static function typedQueryJoinAs():ecto.EctoQueryStruct {
		return TypedQuery.from(Post).joinAssociationAs(Association.of((post:Post) -> post.user), Left, "user").query;
	}

	public static function main():Void {}
}
