# dlang-dockerized

Commands

```sh
docker build -f dockerfiles/dmd/2.105/bookworm/Dockerfile . --tag=dlang/dmd:{2.105,latest}-bookworm
docker build -f dockerfiles/dmd/2.105/ubi9/Dockerfile . --tag=dlang/dmd:{2.105,latest}-ubi9
docker tag dlang/dmd:latest-bookworm dlang/dmd:latest

docker build -f dockerfiles/llvm/llvmorg-7.0.1/bookworm/Dockerfile . --tag=dlang/llvm:llvmorg-{7.0.1,7.0,7}-bookworm
docker build -f dockerfiles/llvm/llvmorg-10.0.1/bookworm/Dockerfile . --tag=dlang/llvm:llvmorg-{10.0.1,10.0,10}-bookworm
docker build -f dockerfiles/llvm/llvmorg-15.0.7/bookworm/Dockerfile . --tag=dlang/llvm:llvmorg-{15.0.7,15.0,15}-bookworm

docker build -f dockerfiles/ldc/0.17.6/bookworm/Dockerfile . --tag=dlang/ldc:{0.17.6,0.17,lts}-bookworm
docker build -f dockerfiles/ldc/1.20.1/bookworm/Dockerfile . --tag=dlang/ldc:{1.20.1,1.20}-bookworm
docker build -f dockerfiles/ldc/1.33.0/bookworm/Dockerfile . --tag=dlang/ldc:{1.33.0,1.33,latest}-bookworm
docker tag dlang/ldc:latest-bookworm dlang/ldc:latest
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
