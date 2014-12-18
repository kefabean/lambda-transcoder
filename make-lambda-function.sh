mkdir ~/ffmpeg_sources

# install pre-requisites
sudo yum -y install git
sudo yum -y install autoconf
sudo yum -y install automake
sudo yum -y install gcc
sudo yum -y install libtool
sudo yum -y gcc-c++
sudo 

# install yasm
cd ~/ffmpeg_sources
git clone --depth 1 git://github.com/yasm/yasm.git
cd yasm
autoreconf -fiv
./configure --prefix="./ffmpeg_build" --bindir="./bin"
make
make install
make distclean

# install libx264
cd ~/ffmpeg_sources
git clone --depth 1 git://git.videolan.org/x264
cd x264
./configure --prefix="./ffmpeg_build" --bindir="./bin" --enable-static
make
make install
make distclean

# install libfdk_aac
cd ~/ffmpeg_sources
git clone --depth 1 git://git.code.sf.net/p/opencore-amr/fdk-aac
cd fdk-aac
autoreconf -fiv
./configure --prefix="./ffmpeg_build" --disable-shared
make
make install
make distclean

# install libmp3lame
cd ~/ffmpeg_sources
curl -L -O http://downloads.sourceforge.net/project/lame/lame/3.99/lame-3.99.5.tar.gz
tar xzvf lame-3.99.5.tar.gz
cd lame-3.99.5
./configure --prefix="./ffmpeg_build" --bindir="./bin" --disable-shared --enable-nasm
make
make install
make distclean

# install libopus
cd ~/ffmpeg_sources
git clone git://git.opus-codec.org/opus.git
cd opus
autoreconf -fiv
./configure --prefix="./ffmpeg_build" --disable-shared
make
make install
make distclean

#install libogg
cd ~/ffmpeg_sources
curl -O http://downloads.xiph.org/releases/ogg/libogg-1.3.2.tar.gz
tar xzvf libogg-1.3.2.tar.gz
cd libogg-1.3.2
./configure --prefix="./ffmpeg_build" --disable-shared
make
make install
make distclean

# install libvorbis
cd ~/ffmpeg_sources
curl -O http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.4.tar.gz
tar xzvf libvorbis-1.3.4.tar.gz
cd libvorbis-1.3.4
./configure --prefix="./ffmpeg_build" --with-ogg="./ffmpeg_build" --disable-shared
make
make install
make distclean

# install libvpx
cd ~/ffmpeg_sources
git clone --depth 1 https://chromium.googlesource.com/webm/libvpx.git
cd libvpx
./configure --prefix="./ffmpeg_build" --disable-examples
make
make install
make clean

# install ffmpeg
cd ~/ffmpeg_sources
git clone --depth 1 git://source.ffmpeg.org/ffmpeg
cd ffmpeg
PKG_CONFIG_PATH="./ffmpeg_build/lib/pkgconfig" ./configure --enable-static --disable-shared --prefix="./ffmpeg_build" --extra-cflags="-I./ffmpeg_build/include" --extra-ldflags="-L./ffmpeg_build/lib" --bindir="$./bin" --enable-gpl --enable-nonfree --enable-libfdk_aac --enable-libmp3lame --enable-libopus --enable-libvorbis --enable-libvpx --enable-libx264
make
make install
make distclean
hash -r
