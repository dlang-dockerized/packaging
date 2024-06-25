# dlang-dockerized

Commands

```sh
./tools/ddct generate-all

docker build -f dockerfiles/dmd/2.105/bookworm/Dockerfile . --tag=dlang-dockerized/dmd:{2.105,latest}-bookworm
docker build -f dockerfiles/dmd/2.105/ubi9/Dockerfile . --tag=dlang-dockerized/dmd:{2.105,latest}-ubi9
docker tag dlang-dockerized/dmd:latest-bookworm dlang-dockerized/dmd:latest

docker build -f containerfiles/llvm/7.0.1/bookworm/Containerfile . --tag=dlang-dockerized/llvm:{7.0.1,7.0,7}-bookworm
docker build -f containerfiles/llvm/10.0.1/bookworm/Containerfile . --tag=dlang-dockerized/llvm:{10.0.1,10.0,10}-bookworm
docker build -f containerfiles/llvm/15.0.7/bookworm/Containerfile . --tag=dlang-dockerized/llvm:{15.0.7,15.0,15}-bookworm

docker build -f dockerfiles/ldc/0.17.6/bookworm/Dockerfile . --tag=dlang-dockerized/ldc:{0.17.6,0.17,lts}-bookworm
docker build -f dockerfiles/ldc/1.20.1/bookworm/Dockerfile . --tag=dlang-dockerized/ldc:{1.20.1,1.20}-bookworm
docker build -f dockerfiles/ldc/1.33.0/bookworm/Dockerfile . --tag=dlang-dockerized/ldc:{1.33.0,1.33,latest}-bookworm
docker tag dlang-dockerized/ldc:latest-bookworm dlang-dockerized/ldc:latest
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
