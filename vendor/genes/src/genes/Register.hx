package genes;

import js.lib.Object;
import js.Syntax;
import haxe.DynamicAccess;
import js.lib.Function;

class Register {
  @:keep @:native("$global")
  public static final _global = js.Syntax.code('typeof window != "undefined" ? window : typeof global != "undefined" ? global : typeof self != "undefined" ? self : undefined');

  static final globals: DynamicAccess<Object> = {};
  @:keep @:native('new')
  static final construct = new js.lib.Symbol();
  @:keep static final init = new js.lib.Symbol();

  @:keep public static function global(name) {
    var existing = globals[name];
    if (existing != null) return existing;
    var created: Object = new Object();
    globals[name] = created;
    return created;
  }

  @:keep public static function createStatic<T>(obj: {}, name: String,
      get: () -> T) {
    var value: T = null;
    inline function init() {
      if (get != null) {
        value = get();
        get = null;
      }
    }
    Object.defineProperty(obj, name, {
      enumerable: true,
      get: () -> {
        init();
        return value;
      },
      set: v -> {
        init();
        value = v;
      }
    });
  }

  @:keep public static function iterator<T>(a: Array<T>): Void->Iterator<T> {
    var isArray: Bool = Syntax.code("Array.isArray({0})", a);
    return if (!isArray) {
      Syntax.code('typeof {0}.iterator === "function" ? {0}.iterator.bind({0}) : {0}.iterator', a);
    } else {
      mkIter.bind(a);
    }
  }

  @:keep public static function getIterator<T>(a: Array<T>): Iterator<T> {
    var isArray: Bool = Syntax.code("Array.isArray({0})", a);
    return if (!isArray) {
      Syntax.code('{0}.iterator()', a);
    } else {
      mkIter(a);
    }
  }

  @:keep static function mkIter<T>(a: Array<T>): Iterator<T> {
    return new ArrayIterator(a);
  }

  @:keep public static function extend(superClass) {
    Syntax.code('
      function res() {
        this[Register.new].apply(this, arguments)
      }
      Object.setPrototypeOf(res.prototype, superClass.prototype)
      return res
    ');
  }

  @:keep public static function inherits(resolve, defer = false) {
    Syntax.code('
      function res() {
        if (defer && resolve && res[Register.init]) res[Register.init]()
        this[Register.new].apply(this, arguments)
      }
      if (!defer) {
        if (resolve && resolve[Register.init]) {
          defer = true
          res[Register.init] = () => {
            if (resolve[Register.init]) resolve[Register.init]()
            Object.setPrototypeOf(res.prototype, resolve.prototype)
            res[Register.init] = undefined
          } 
        } else if (resolve) {
          Object.setPrototypeOf(res.prototype, resolve.prototype)
        }
      } else {
        res[Register.init] = () => {
          const superClass = resolve()
          if (superClass[Register.init]) superClass[Register.init]()
          Object.setPrototypeOf(res.prototype, superClass.prototype)
          res[Register.init] = undefined
        } 
      }
      return res
    ');
  }

  static var fid = 0;

  @:keep public static function bind(o: Object, m: Function): Null<Function> {
    if (m == null) return null;

    var id: Null<Int> = Syntax.code("{0}.__id__", m);
    if (id == null) {
      id = fid++;
      Syntax.code("{0}.__id__ = {1}", m, id);
    }

    var closures: Null<DynamicAccess<Function>> = Syntax.code("{0}.hx__closures__", o);
    if (closures == null) {
      closures = {};
      Syntax.code("{0}.hx__closures__ = {1}", o, closures);
    }

    var key = Std.string(id);
    var existing = closures[key];
    if (existing != null) return existing;

    var bound: Function = Syntax.code("{0}.bind({1})", m, o);
    closures[key] = bound;
    return bound;
  }
}

private class ArrayIterator<T> {
  final array: Array<T>;
  var current: Int = 0;

  public function new(array: Array<T>) {
    this.array = array;
  }

  public function hasNext() {
    return current < array.length;
  }

  public function next() {
    return array[current++];
  }
}
