#!/usr/bin/env bash
set -e

target_windows=false
target_both=false
working_dir=$(pwd)

for arg in "$@"; do
  if [ "$arg" == "--win" ]; then
    target_windows=true
  elif [ "$arg" == "--both" ]; then
    target_both=true
  fi
done

# Pull, configure, and statically build Qt5.
# Doing this, of course, assumes you agree to comply with the Qt open source licence.
if [ ! -d "./qt5build" ]; then
  cd scripts

  if [ "$target_both" == true ]; then
    ./qt5setup.sh --both
  elif [ "$target_windows" == true ]; then
    ./qt5setup.sh --win
  else
    ./qt5setup.sh
  fi

  cd $working_dir
fi

# Compile UI files into headers.
echo "Compiling UI files..."
cd ui
../qt5build/linux/bin/uic -o mainwindow.h MainWindow.ui
../qt5build/linux/bin/uic -o packageitem.h PackageItem.ui
../qt5build/linux/bin/uic -o errordialog.h ErrorDialog.ui
../qt5build/linux/bin/uic -o packageinfo.h PackageInfo.ui
../qt5build/linux/bin/uic -o repositories.h Repositories.ui
../qt5build/linux/bin/uic -o settings.h Settings.ui
cd ..

# Build application dependencies if not present
if [ ! -d "./deps" ]; then
  echo "Building dependencies..."
  cd scripts
  ./deps.sh
  cd $working_dir
fi

rm -rf build
mkdir build

# Create a directory for the distributable files.
mkdir -p dist

cd build

if [ "$target_both" == true ]; then

  rm -rf ../dist/linux; mkdir ../dist/linux
  rm -rf ../dist/win32; mkdir ../dist/win32

  # Build for both platforms back to back.
  sed -i "s|^#define TARGET_WINDOWS|// #define TARGET_WINDOWS|" ../globals.h
  cmake ../scripts
  make -j$(nproc)
  mv ./SppliceCPP ../dist/linux/SppliceCPP
  rm -rf ./*

  sed -i "s|^// #define TARGET_WINDOWS|#define TARGET_WINDOWS|" ../globals.h
  cmake -DCMAKE_TOOLCHAIN_FILE="../scripts/windows.cmake" ../scripts
  make -j$(nproc)
  mv ./SppliceCPP.exe ../dist/win32/SppliceCPP.exe

else

  # Build for the specified platform using CMake.
  if [ "$target_windows" == true ]; then
    rm -rf ../dist/win32; mkdir ../dist/win32
    sed -i "s|^// #define TARGET_WINDOWS|#define TARGET_WINDOWS|" ../globals.h
    cmake -DCMAKE_TOOLCHAIN_FILE="../scripts/windows.cmake" ../scripts
  else
    rm -rf ../dist/linux; mkdir ../dist/linux
    sed -i "s|^#define TARGET_WINDOWS|// #define TARGET_WINDOWS|" ../globals.h
    cmake ../scripts
  fi

  make -j$(nproc)

  # Move the output binary to distributables directory.
  if [ "$target_windows" == true ]; then
    mv ./SppliceCPP.exe ../dist/win32/SppliceCPP.exe
  else
    mv ./SppliceCPP ../dist/linux/SppliceCPP
  fi

fi

# Clear any residual build cache.
cd ..
rm -rf build

cd dist

# Prepare the Windows binary for distribution.
if [ "$target_windows" == true ] || [ "$target_both" == true ]; then
  # Copy project dependencies
  cp ../deps/win32/lib/libcurl-4.dll                               ./win32
  cp ../deps/win32/lib/archive.dll                                 ./win32
  cp ../deps/win32/lib/liblzma.dll                                 ./win32
  cp ../deps/win32/lib/libcrypto-1_1-x64.dll                       ./win32
  # Copy Qt5 dependencies
  cp ../qt5build/win32/bin/Qt5Core.dll                             ./win32
  cp ../qt5build/win32/bin/Qt5Gui.dll                              ./win32
  cp ../qt5build/win32/bin/Qt5Widgets.dll                          ./win32
  # Copy Qt5 plugins
  mkdir ./win32/platforms
  cp -r ../qt5build/win32/plugins/platforms/qwindows.dll           ./win32/platforms
  cp -r ../qt5build/win32/plugins/imageformats                     ./win32
  # Copy C++ dependencies
  cp /usr/x86_64-w64-mingw32/lib/libwinpthread-1.dll               ./win32
  cp /usr/lib/gcc/x86_64-w64-mingw32/*-posix/libgcc_s_seh-1.dll   ./win32
  cp /usr/lib/gcc/x86_64-w64-mingw32/*-posix/libstdc++-6.dll      ./win32
  # Strip debug symbols
  strip ./win32/SppliceCPP.exe
  strip ./win32/*.dll
  strip ./win32/platforms/*.dll
  strip ./win32/imageformats/*.dll
fi

if [ "$target_windows" == false ] || [ "$target_both" == true ]; then
  # Strip debug symbols
  strip ./linux/SppliceCPP
  # Pack with UPX
  ../deps/shared/upx/upx --best --lzma ./linux/SppliceCPP
fi
