import {Register} from "../../genes/Register.js"

/**
 * This iterator is used only when `Array<T>` is passed to `Iterable<T>`
 */
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

	/**
	 * See `Iterator.hasNext`
	 */
	hasNext(): boolean {
		return this.current < this.array.length;
	}

	/**
	 * See `Iterator.next`
	 */
	next(): T {
		return this.array[this.current++]!;
	}
	static get __name__(): string {
		return "haxe.iterators.ArrayIterator"
	}
	get __class__(): Function {
		return ArrayIterator
	}
}
Register.setHxClass("haxe.iterators.ArrayIterator", ArrayIterator);

Register.seedProtoField(ArrayIterator, "array");

Register.seedProtoField(ArrayIterator, "current");

//# sourceMappingURL=ArrayIterator.tsx.map