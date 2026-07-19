import type {Iterator} from "../StdTypes.js"

export class Register {
	declare static $global: typeof globalThis & { [key: string]: unknown };
	declare static globals: {[key: string]: HxRegistry};
	declare static readonly ["new"]: unique symbol;
	declare static readonly init: unique symbol;
	declare static fid: number;

	/**
	 * Get (or lazily create) a named registry object on `globalThis`.
	 *
	 * This function is intentionally dynamic: the returned object is used for
	 * heterogeneous registries like `$hxClasses` and `$hxEnums`.
	 */
	static global(name: string): HxRegistry {
		let existing: HxRegistry | null = (Register.globals[name] ?? null);
		if (existing != null) {
			return existing;
		};
		let created: HxRegistry = Object.create(null);
		Register.globals[name] = created;
		return created;
	}

	/**
	 * Register a runtime type in the `$hxClasses` global registry.
	 *
	 * This is used by genes-ts output to keep Haxe/Genes reflection compatible
	 * without emitting `(… as any)[…] = …` patterns into every generated module.
	 */
	static setHxClass(id: string, value: Function): void {
		let hxClasses: HxRegistry = Register.global("$hxClasses");
		hxClasses[id] = value;
	}

	/**
	 * Register a runtime enum in the `$hxEnums` global registry.
	 *
	 * This registry is used by `Type.resolveEnum(...)` and parts of the Haxe JS
	 * runtime (e.g. `js.Boot.__string_rec`) to map enum names to their values.
	 */
	static setHxEnum(id: string, value: Function): void {
		let hxEnums: HxRegistry = Register.global("$hxEnums");
		hxEnums[id] = value;
	}

	/**
	 * Typed view of the `$hxClasses` registry (reflection).
	 *
	 * This keeps `Type.resolveClass(...)` and related code typed in generated TS
	 * without leaking `unknown` into user modules.
	 */
	static hxClasses(): HxClasses {
		return Register.unsafeCast(Register.global("$hxClasses"));
	}

	/**
	 * Typed view of the `$hxEnums` registry (reflection).
	 *
	 * This keeps enum reflection code typed in generated TS without leaking
	 * `unknown` into user modules.
	 */
	static hxEnums(): HxEnums {
		return Register.unsafeCast(Register.global("$hxEnums"));
	}

	/**
	 * Ensure an instance field exists on a class prototype for reflection
	 * (`Type.getInstanceFields`, etc) without forcing a TS `any` cast.
	 *
	 * We intentionally set a `null` value (not `undefined`) to match Genes' legacy
	 * behavior for uninitialized fields.
	 */
	static seedProtoField(cls: Function, name: string): void {
		Object.defineProperty(cls.prototype, name, {"value": null, "writable": true, "enumerable": true, "configurable": true});
	}

	/**
	 * Unsafe type assertion helper.
	 *
	 * This is used by the TS emitter to keep `any` out of user modules when:
	 * - metadata forces a TS type override (`@:genes.type`, `@:genes.returnType`)
	 * - Haxe semantics rely on "impossible" states under TS types (e.g. some JS
	 *   APIs return `undefined` but Haxe models `null`)
	 *
	 * It intentionally centralizes the unsafety inside the runtime boundary.
	 */
	static unsafeCast<T>(value: any): T {
		return value;
	}
	static createStatic<T>(obj: {
	}, name: string, get: ((() => T)) | null): void {
		let value: T | null = null;
		Object.defineProperty(obj, name, {"enumerable": true, "get": function () {
			if (get != null) {
				value = get();
				get = null;
			};
			return Register.unsafeCast<any>(value);
		}, "set": function (v: any) {
			if (get != null) {
				value = get();
				get = null;
			};
			value = v;
		}});
	}

	/**
	 * NOTE: This function is intentionally typed as `any` in generated TS.
	 *
	 * In JS/Genes, dynamic field access to `.iterator` may refer to either:
	 * - the Haxe/Genes iterator function (callable), OR
	 * - an arbitrary user field value (non-callable), e.g. `{ iterator: 0 }`.
	 *
	 * Returning `any` preserves Genes semantics for dynamic field access while
	 * keeping the unsafety confined to the runtime boundary.
	 */
	static iterator<T>(a: Array<T> | { iterator: () => Iterator<T> } | { keys: () => Iterator<any>; get: (k: any) => T | null }): any {
		if (!Array.isArray(a)) {
			if ("iterator" in a) {
				return Register.unsafeCast<(() => Iterator<T>)>(typeof a.iterator === "function" ? a.iterator.bind(a) : a.iterator);
			} else {
				return function () {
					let keys: Iterator<any> = Register.unsafeCast<Iterator<any>>((a!).keys());
					return {"hasNext": function () {
						return keys.hasNext();
					}, "next": function () {
						return Register.unsafeCast((a!).get(keys.next()));
					}};
				};
			};
		} else {
			let a1: T[] = a;
			return function () {
				return Register.mkIter(a1);
			};
		};
	}
	static getIterator<T>(a: Array<T> | { iterator: () => Iterator<T> } | { keys: () => Iterator<any>; get: (k: any) => T | null }): Iterator<T> {
		if (!Array.isArray(a)) {
			if ("iterator" in a) {
				return Register.unsafeCast<Iterator<T>>(a.iterator());
			} else {
				let keys: Iterator<any> = Register.unsafeCast<Iterator<any>>((a!).keys());
				return {"hasNext": function () {
					return keys.hasNext();
				}, "next": function () {
					return Register.unsafeCast((a!).get(keys.next()));
				}};
			};
		} else {
			return Register.mkIter(a);
		};
	}
	static mkIter<T>(a: T[]): Iterator<T> {
		return new ArrayIterator<T>(a);
	}

	/**
	 * Create a "synthetic" subclass constructor at runtime.
	 *
	 * genes-ts uses this to preserve Genes/Haxe JS inheritance semantics while
	 * breaking module cycles. The return type is a broad constructor shape because
	 * TS cannot express the precise constructor signature of the dynamically-computed
	 * superclass.
	 *
	 * Why not just return `any`? TypeScript declaration emit looks at classes such
	 * as `class Child extends Register.extend(parent)` and synthesizes a helper
	 * declaration like `declare const Child_base: ...` in the public `.d.ts`. If
	 * this helper returns `any`, that public declaration becomes `Child_base: any`
	 * and downstream users lose type safety before they even touch their own code.
	 *
	 * `new (...args: unknown[]) => {}` is intentionally broad: it says "this is
	 * some constructor" without claiming we know its exact parameters or instance
	 * fields. That is enough for `extends`, avoids a leaked `any`, and keeps the
	 * one unavoidable assertion contained in this runtime helper.
	 */
	static extend(superClass: any): new (...args: unknown[]) => {} {
		function res() {
        // Prefer the legacy Genes initializer path when present.
        // @ts-ignore
        const init = this[Register.new]
        if (typeof init === "function") {
          // @ts-ignore
          init.apply(this, arguments)
          return
        }
        // genes-ts may emit real constructors (no `[Register.new]`), so fall
        // back to delegating to the provided superclass constructor.
        return Reflect.construct(superClass, arguments, new.target)
      }
      Object.setPrototypeOf(res.prototype, superClass.prototype)
      return Register.unsafeCast(res);
	}

	/**
	 * Return a base class for `extends` that supports deferred resolution.
	 *
	 * This is a core part of Genes' cycle handling. The return type is a broad
	 * constructor shape because the actual superclass can be resolved lazily and
	 * may have an arbitrary constructor signature.
	 *
	 * The important part is the generated `.d.ts` surface: TypeScript creates
	 * intermediate declarations for dynamic `extends` expressions. If this
	 * function is typed as `any`, those intermediates leak into published
	 * declarations as `declare const *_base: any`. Returning the broad constructor
	 * type instead tells TypeScript "this value is constructable" while still
	 * forcing every real use site to prove anything more specific.
	 */
	static inherits(resolve: any | null = null, defer?: boolean): new (...args: unknown[]) => {} {
		if (defer == null) {
			defer = false;
		};
		function res() {
        // @ts-ignore
        if (defer && resolve && res[Register.init]) res[Register.init]()
        // Prefer the legacy Genes initializer path when present.
        // @ts-ignore
        const init = this[Register.new]
        if (typeof init === "function") {
          // @ts-ignore
          init.apply(this, arguments)
          return
        }
        // genes-ts may emit real constructors (no `[Register.new]`). In that
        // case, delegate to the resolved superclass constructor.
        if (resolve) {
          const superClass = (defer && !resolve.prototype) ? resolve() : resolve
          // @ts-ignore
          if (superClass[Register.init]) superClass[Register.init]()
          return Reflect.construct(superClass, arguments, new.target)
        }
      }
      if (!defer) {
        if (resolve && resolve[Register.init]) {
          defer = true
          // @ts-ignore
	          res[Register.init] = () => {
	            if (resolve[Register.init]) resolve[Register.init]()
	            Object.setPrototypeOf(res.prototype, resolve.prototype)
	            // @ts-ignore
	            res[Register.init] = undefined
	          }
	        } else if (resolve) {
	          Object.setPrototypeOf(res.prototype, resolve.prototype)
	        }
      } else {
        // @ts-ignore
        res[Register.init] = () => {
          const superClass = resolve()
          if (superClass[Register.init]) superClass[Register.init]()
	          Object.setPrototypeOf(res.prototype, superClass.prototype)
	          // @ts-ignore
	          res[Register.init] = undefined
	        }
	      }
	      return Register.unsafeCast(res);
	}

	/**
	 * Returns the stable Haxe-JavaScript closure for one receiver/method pair.
	 *
	 * Why: reading an instance method as a value must preserve `this`, and
	 * repeated reads must return the same closure for Haxe identity semantics.
	 *
	 * What: `null` methods remain `null`; the same receiver and callable reuse
	 * one closure; a different receiver or callable receives a different one.
	 *
	 * How: the Haxe JS protocol attaches a numeric `__id__` to the callable and
	 * an `hx__closures__` cache to the receiver. Those hidden mutable properties
	 * are not part of the user's nominal Haxe types, so this helper deliberately
	 * remains a contained dynamic runtime boundary. The emitters recover the
	 * precise callable type at user-module assignments and calls. Direct uses
	 * require a mutable, extensible object receiver; primitives and frozen host
	 * objects are outside this internal helper's supported contract.
	 */
	static bind(o: any, m: any): any | null {
		if (m == null) {
			return null;
		};
		if (m.__id__ == null) {
			m.__id__ = Register.fid++;
		};
		let f: any | null = null;
		if ((o!).hx__closures__ == null) {
			(o!).hx__closures__ = {};
		} else {
			f = ((o!).hx__closures__[m.__id__] ?? null);
		};
		if (f == null) {
			f = m.bind(o);
			(o!).hx__closures__[m.__id__] = f;
		};
		return f;
	}
	static get __name__(): string {
		return "genes.Register"
	}
	get __class__(): Function {
		return Register
	}
}

Register.$global = globalThis
Register.globals = Object.create(null)
// @ts-ignore
Register["new"] = Symbol()
// @ts-ignore
Register.init = Symbol()
Register.fid = 0
/**
 * genes-ts runtime registry type.
 *
 * The values are intentionally `unknown`: these registries store heterogeneous
 * values (classes, enums, internal helpers) and are populated dynamically at
 * runtime. Using `unknown` avoids leaking `any` into user modules.
 */
export type HxRegistry = {[key: string]: unknown}

/**
 * `$hxClasses` registry: `Type.resolveClass(...)` and friends.
 */
export type HxClasses = {[key: string]: Function}

/**
 * Minimal runtime shape for Haxe enum values stored in `$hxEnums`.
 *
 * We only type what the runtime reflection code actually uses today.
 */
export type HxEnumInfo = { __constructs__: Array<{ _hx_name: string }> }

/**
 * `$hxEnums` registry: `Type.resolveEnum(...)` and friends.
 */
export type HxEnums = {[key: string]: HxEnumInfo}

export class ArrayIterator<T> extends Register.inherits() {
	constructor(array: T[]) {
		super(array);
	}
	declare array: T[];
	declare current: number;
	[Register.new](...args: never[]): void;
	[Register.new](array: T[]): void {
		this.current = 0;
		this.array = array;
	}
	hasNext(): boolean {
		return this.current < this.array.length;
	}
	next(): T {
		return this.array[this.current++]!;
	}
	static get __name__(): string {
		return "genes._Register.ArrayIterator"
	}
	get __class__(): Function {
		return ArrayIterator
	}
}
Register.setHxClass("genes._Register.ArrayIterator", ArrayIterator);

Register.seedProtoField(ArrayIterator, "array");

Register.seedProtoField(ArrayIterator, "current");

//# sourceMappingURL=Register.tsx.map