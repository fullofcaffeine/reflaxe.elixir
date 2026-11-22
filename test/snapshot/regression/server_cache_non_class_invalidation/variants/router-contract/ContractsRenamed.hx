/**
 * The params contract without the field `id`. A fresh build rejects the
 * unchanged router, because its path has the param `id`.
 */
typedef UserIdPathParams = {
	var ident:Int;
}
