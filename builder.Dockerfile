FROM ubuntu:latest

# base dependencies
RUN apt update && apt install -y \
    git \
    sudo \
    wget \
    unzip \
    build-essential \
    cmake \
    libssl-dev \
    mesa-common-dev \
    libpsl-dev \
    libzstd-dev

# Found on qt5 wiki page for building from source
RUN apt install -y \
    '^libxcb.*-dev' \
    libx11-xcb-dev \
    libglu1-mesa-dev \
    libxrender-dev \
    libxi-dev \
    libxkbcommon-dev \
    libxkbcommon-x11-dev

# From random blog post. Something here is needed for qwindows.dll to be built, and I can't figure out which one.
RUN apt install -y \
    libxcomposite-dev \
    libxcursor-dev \
    libxdamage-dev \
    libxext-dev \
    libxfixes-dev \
    libxrandr-dev \
    libxrender-dev \
    libxslt-dev \
    libxss-dev \
    libxtst-dev

WORKDIR /src

# Copy only what's necessary to install dependencies, for docker-build caching purposes
COPY scripts scripts

# --both / --win / [empty]
ARG TARGET=--both

RUN cd /src/scripts; /src/scripts/deps.sh
RUN cd /src/scripts; /src/scripts/qt5setup.sh ${TARGET}

# Now copy everything else
COPY . .

CMD ["./autobuild.sh", "${TARGET}"]
