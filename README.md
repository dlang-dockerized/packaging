# dlang-dockerized

Commands

```sh
./ddct generate-all
./ddct build ldc 1.38.0
./ddct build dmd 2.107.1
```

```
system gcc → build ldc lts ← custom llvm 7
                    ↓
system gcc → build ldc 1.20 ← custom llvm 10
                    ↓
system gcc → build ldc stable ← custom llvm 15+
                    ↓
system gcc → build ldc stable (again?) ← custom llvm 15+
                    ↓
system gcc → build any other compilers
```
