# dlang-dockerized

Commands

```sh
./ddct generate-all

docker build -f dockerfiles/dmd/2.105/bookworm/Dockerfile . --tag=dlang-dockerized/dmd:{2.105,latest}-bookworm
docker build -f dockerfiles/dmd/2.105/ubi9/Dockerfile . --tag=dlang-dockerized/dmd:{2.105,latest}-ubi9
docker tag dlang-dockerized/dmd:latest-bookworm dlang-dockerized/dmd:latest

#./ddct build llvm 7
#./ddct build llvm 10
#./ddct build llvm 15

#./ddct build ldc 0.17.6
#./ddct build ldc 1.20.1
./ddct build ldc 1.33.0
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
