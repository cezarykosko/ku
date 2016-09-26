# Ku

Ku is a simple pub/sub engine.

## Usage

- start the application by executing `Ku.start/0`,
- subscribe a callback to a set of keys by executing `Ku.subscribe/2`:<br/>
 `Ku.subscribe "foo.bar", &MyModule.do_it/1           # Matches only "foo.bar" events.`<br/>
 `Ku.subscribe "foo.*", &MyOtherModule.also_do_it/1   # Matches all "foo. ..." events.`
- publish via `Ku.publish/3` and watch your callbacks executed:<br/>
 `Ku.publish "foo.bar", %{bar: "baz"}, %{optional: "metadata object"} # delivers to both callbacks`<br/>
 `Ku.publish "foo.notbar", "body", :meta # delivers only to the second one`<br/>
 `Ku.publish "unknown", <<"lots of data">>, 123 # delivers to none`.

### Keys, patterns, callbacks

Keys are strings containing any alphanumeric character (case sensitive), `.`, `-` and `_`.

Patterns are Graphite-like strings describing desired keys.
Pattern that is a key matches only that key.
Furthermore, three additional behaviours are available:
- `{a[1],a[2],a[3],...,a[n]}` matches any of `a[1]`,`a[2]`,...,`a[n]`, e.g. `ab{c,d,e}` matches `abc`, `abd`, `abe`;
- `?` matches one character, e.g. `a?b` matches any key of length 3, whose first character is `a` and third is `b`;
- `*` matches any number of characters, e.g. `ab*` matches keys starting with `ab`, while `ab{*d, ce}` matches strings starting with `ab` and ending with `d` and `abce`.

Callbacks are `1`-arity functions. They will be passed (should relevant subscribers' patterns match some keys) maps with 2 keys: `body` and `metadata`.

### Subscribing

`Ku.subscribe` takes two parameters:
- a key pattern,
- a callback to be executed.
The function's return value is a `ref`, being an interlan `Subscriber`'s identifier.

### Publishing
`Ku.publish` takes three parameters:
- a key string
- message body,
- message metadata (`()` by default).

### Unsubscribing
Two functions are given for cancelling subscriptions:
- `Ku.unsubscribe/1`, cancelling a single subscription, given its `ref`,
- `Ku.clear/0`, wiping all subscriptions.

## License

Standard MIT License, no quirks, no catches.
