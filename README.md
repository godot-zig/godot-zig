# godot-zig
Zig bindings for Godot 4

# Prerequisite:
1. zig master build
2. godot 4.2
3. make sure godot is in your $PATH

# Building:

```
zig build bind                 # generate zig binding for current godot version
zig build
godot -e --path ./project      # -e is needed to enter editor mode to import assets
```


# Have fun!