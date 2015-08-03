## bindx2 - crossplatform library for data binding in Haxe.

[![Build Status](https://travis-ci.org/profelis/bindx2.svg?branch=master)](https://travis-ci.org/profelis/bindx2)

======

## Features:

- automatically generates signals to notify about properties/methods changes of a class
- automatically generates setters or modifies existing setters
- neat API for subscribing to properties and methods changes
- extended API for custom expressions binding
- API for fast properties binding

======

## Examples:

```haxe
// UserModel.hx

import bindx.IBindable;

@:bindable
class UserModel implements IBindable
{
    public var name:String;
    public var coins:Int;

    public var health:Float = 1;

    public function new(name:String, coins:Int) {
        this.name = name;
        this.coins = coins;
    }
}
```
...
```haxe
// bind complex expression with another field
unbindOldUser = BindExt.exprTo('Hello ${user.name}. You have ' + user.coins + " coins", this.textField.text);

// listen field changes
Bind.bind(user.health, onHealthChange);

function onHealthChange(from:Null<Float>, to:Null<Float>) {
    trace('user health changed from $from to $to');
}
```

[All examples](https://github.com/profelis/bindx2/tree/master/samples/)

======

## API:

Method       | Description
------------ | -------------
Bind.bind(expr, listener) | executes `listener` if property or method in `expr` was changed. If `expr` contains property, then `listener` accepts 2 arguments: old and new values. If `expr` contains method, `listener` accepts no arguments. Use `Bind.unbind` for unbind
Bind.bindTo(expr, toExpr) | Assign result of `expr` to `toExpr` (NB: if `expr` contains method, then this method will be executed without arguments!). Does NOT invoke `expr` automatically. Returns reference callback, which can be used to unbind.
Bind.notify(expr, oldValue, newValue) | Manually execute notification about property or method changes (if `expr` is method, then `oldValue` and `newValue` are not required)
Bind.unbind(expr, listener) | Unsubscribe provided `listener` from `expr` changes (NB: if `listener` is not specified, all listeners for binded to this `expr` will be unsubscribed)
Bind.bindAll(obj:IBindable, listener, force) | Bind all properties and methods of `obj` (force mode instantiate all lazy signals). Return unbind callback
Bind.unbindAll(obj:IBindable) | `listener(name:String, oldValue:Dynamic, newValue:Dynamic):Void` Unbind all properties and methods of `obj` (NB: still can bind new listeners after that!)

## Extended API:

Method       | Description
------------ | -------------
BindExt.chain(chainExpr, listener) | Subscribe to sequence of invokations like `a.b.c(1).d..`, fires signal if any member of `chainExpr` was changed (automatically unsubscribes from old value and subscribes to new one). Methods can be specified with arguments. (NB: for the first time `listener` will be called automatically). `listener` behaves identicaly to `listener` in Bind.bind(). `BindExt.chain()`  `chainExpr`.
BindExt.chainTo(chainExpr, toExpr) | Bind `chainExpr` to `toExpr`. (NB: for the first time binding is executed automatically). Returns a callback to unbind `chainExpr`.
BindExt.expr(expr, listener) | Universal method. `expr` can be any valid Haxe expression. All `IBindable` instances and bindables properties will be found automatically. `listener` always accepts 2 arguments. Previous values automatically stored for methods. (NB: for the first time `listener` is called automatically). BindExt.expr() returns a callback to unbind `expr`.
BindExt.exprTo(expr, toExpr) | Bind any valid `expr` to `toExpr`. (NB: for the first time `listener` is called automatically). Returns a callback to unbind `expr`.

======

## `bindx.IBindable` and @:bindable meta:

Bindx will process special meta - `@:bindable`. If `@:bindable` is set for the whole class then it will be inherited by all public properties which don't have this meta already. `@:bindable` only processed for classes and interfaces which implement `bindx.IBindable`.

Accepts additional arguments: `@:bindable(paramName1 = value, paramName2 = value ...)`, short notation `paramName` equals with `paramName = true`

Parameter    | Default value | Description
------------ | ------------- | -------------
inlineSetter | false | Whether to add `inline` accessor to automatically generated setters or not.
force | false | Special mode to ignore other arguments. Creates signal for notifications, but does not create or modify setters, so developer can manage signal firing manually using `Bind.notify`. Also `force` mode extends list of allowed properties if setter is `null`, `never` or `dynamic` (without `force` mode binding such properties is impossible because setters cannot be generated or modified automatically).
lazySignal | true | Whether to create notification signal immediately or wait till the first request. (By default: wait for request).
inlineSignalGetter | false | if `lazySignal` is `true`, add `inline` accessor to automatically generated getter.


======

## Logging:

```-D bindx_log=LOG_LEVEL```

Log level    | Description
------------ | -------------
0 | Do not log anything
1 | Concise log (optimal). (NB: also enabled with shorten flag: -D bindx_log)
2 | Full binding log (useful for debugging)

======

## Installation:

`haxelib install bindx2`

======

## Additional

`-D bindx_compareMethods` enables methods comparing with `Reflect.compareMethods` (enabled for Neko by default)
- BindExt and `this`. Use `this.bindableA.bindableB` to listen changes of `bindableA`, not only `bindableB`
