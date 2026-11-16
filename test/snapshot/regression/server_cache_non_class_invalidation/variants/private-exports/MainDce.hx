class Main {
	static function main():Void {
		Sys.println(PrivateDceCaller.live() + PrivateDceOwner.anchor() + PrivateDceUser.run());
	}
}
