# Building manually

Running `./autobuild.sh --both` on a debian-environment should install all needed dependensies, as well as build the project.

The `--both` signals it to build for both linux, and windows. Omitting it will build for linux, and specifying `--win` will build just a windows package.

# Building with Docker

```sh
docker build -t spplicecpp-builder -f builder.Dockerfile .
docker run --rm -v $(pwd)/dist:/src/dist spplicecpp-builder
```

The first command will take a while to run, but only the first time (It's going to compile QT5 for linux & windows).
Subsequent times most of the build dependensies will be cached, so it should be nearly instant to run.

Note, that you do need to run both commands every time you change code.
