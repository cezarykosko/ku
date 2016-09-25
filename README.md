# Ku

Ku is a simple pub/sub engine.

## Usage

```
Ku.start

Ku.subscribe "foo.bar", &MyModule.do_it/1           # Matches only "foo.bar" events.
Ku.subscribe "foo.*", &MyOtherModule.also_do_it/1   # Matches all "foo. ..." events.
```

Deliver to both `MyModule.do_it/1` and `MyOtherModule.also_do_it/1`
```
Ku.publish "foo.bar", %{bar: "baz"}, %{optional: "metadata object"}
```

Deliver only to `MyOtherModule.also_do_it/1`

```
Ku.publish "foo.lala", %{bar: "baz"}, %{optional: "metadata object"}
```

Deliver to none

```
Ku.publish "unhandled_key", %{bar: "baz"}, %{optional: "metadata object"}
```
