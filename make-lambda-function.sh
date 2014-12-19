#!/bin/bash
CURR_DIR=$(pwd)

# install pre-requisites
sudo yum -y install git
sudo yum -y install autoconf
sudo yum -y install automake
sudo yum -y install gcc
sudo yum -y install libtool
sudo yum -y gcc-c++
sudo yum -y npm
sudo yum -y install epel-release
sudo yum -y install yasm

# install required node modules
cd $CURR_DIR/transcoder
npm install async
npm install fluent-ffmpeg
npm install s3-upload-stream

# download and compile ffmpeg from source including pre-requisites
mkdir $CURR_DIR/ffmpeg_sources

# install libx264
cd $CURR_DIR/ffmpeg_sources
git clone --depth 1 git://git.videolan.org/x264
cd x264
./configure --prefix="$CURR_DIR/ffmpeg_build" --bindir="$CURR_DIR/bin" --enable-static
make
make install
make distclean

# install libfdk_aac
cd $CURR_DIR/ffmpeg_sources
git clone --depth 1 git://git.code.sf.net/p/opencore-amr/fdk-aac
cd fdk-aac
autoreconf -fiv
./configure --prefix="$CURR_DIR/ffmpeg_build" --disable-shared
make
make install
make distclean

# install libmp3lame
cd $CURR_DIR/ffmpeg_sources
curl -L -O http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
tar xzvf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure --prefix="$CURR_DIR/ffmpeg_build" --bindir="$CURR_DIR/bin" --disable-shared --enable-nasm
make
make install
make distclean

# install libopus
cd $CURR_DIR/ffmpeg_sources
git clone git://git.opus-codec.org/opus.git
cd opus
autoreconf -fiv
./configure --prefix="$CURR_DIR/ffmpeg_build" --disable-shared
make
make install
make distclean

#install libogg
cd $CURR_DIR/ffmpeg_sources
curl -O http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz
tar xzvf libogg-1.3.2.tar.gz
cd libogg-1.3.2
./configure --prefix="$CURR_DIR/ffmpeg_build" --disable-shared
make
make install
make distclean

# install libvorbis
cd $CURR_DIR/ffmpeg_sources
curl -O http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.4.tar.gz
tar xzvf libvorbis-1.3.4.tar.gz
cd libvorbis-1.3.4
./configure --prefix="$CURR_DIR/ffmpeg_build" --with-ogg="$CURR_DIR/ffmpeg_build" --disable-shared
make
make install
make distclean

# install libvpx
cd $CURR_DIR/ffmpeg_sources
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
cd libvpx
./configure --prefix="$CURR_DIR/ffmpeg_build" --disable-examples
make
make install
make clean

# install ffmpeg
cd $CURR_DIR/ffmpeg_sources
git clone --depth 1 git://source.ffmpeg.org/ffmpeg
cd ffmpeg
PKG_CONFIG_PATH="$CURR_DIR/ffmpeg_build/lib/pkgconfig" ./configure --enable-static --disable-shared --prefix="$CURR_DIR/ffmpeg_build" --extra-cflags="-I$CURR_DIR/ffmpeg_build/include" --extra-ldflags="-L$CURR_DIR/ffmpeg_build/lib" --bindir="$CURR_DIR/bin" --enable-gpl --enable-nonfree --enable-libfdk_aac --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libvpx --enable-libx264
make
make install
make distclean
hash -r

# copy compiled binary in to correct place within lambda function
mkdir $CURR_DIR/transcoder/bin
cp $CURR_DIR/bin/ffmpeg $CURR_DIR/transcoder/bin/
cd $CURR_DIR/transcoder
zip -r ../transcoder.zip *
