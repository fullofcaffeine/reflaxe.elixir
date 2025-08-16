package test; enum Result<T,E> {Ok(v:T);Error(e:E);} class ResultTools { public static function isOk<T,E>(r:Result<T,E>):Bool return switch(r){case Ok(_):true;case Error(_):false;} }
