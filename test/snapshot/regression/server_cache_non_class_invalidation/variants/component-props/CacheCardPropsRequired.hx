package;

/**
 * The props of the `cache_card` component, now with a required `subtitle`.
 * The unchanged `CacheCardPage` does not set it, so a fresh build rejects the
 * page.
 */
typedef CacheCardProps = {
	var title:String;
	var subtitle:String;
	var inner_content:String;
}
