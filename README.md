# godot-zig
Zig bindings for Godot 4

## Prerequisite:
1. zig master build
2. godot 4.2+
3. make sure godot is in your $PATH ( 'godot --version' works)

## Building:

```
zig build bind                 # generate zig bindings for current godot version
zig build
godot -e --path ./project      # -e is only needed for the first run to get assets imported
```

## Have fun!