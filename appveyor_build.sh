cd "$APPVEYOR_BUILD_FOLDER"

# Libraries versions
PPL_VERSION=1.2
GMP_VERSION=6.1.2
MPFR_VERSION=4.0.1
NCURSES_VERSION=6.1

# Environment Variables
export PATH=/bin:$PATH
export CPATH=/usr/local/include:$CPATH
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export LIBRARY_PATH=/usr/local/lib:$LIBRARY_PATH

# Adding ncurses
wget https://ftp.gnu.org/gnu/ncurses/ncurses-${NCURSES_VERSION}.tar.gz -O - | tar -xz
(cd ncurses-${NCURSES_VERSION}; ./configure --prefix=/usr/local --with-shared --with-termlib; make -j 4; make install)
rm -rf ncurses-${NCURSES_VERSION}

# Install apt-cyng
wget -O /bin/apt-cyg https://raw.githubusercontent.com/transcode-open/apt-cyg/master/apt-cyg && chmod +x /bin/apt-cyg

# Installing patch
apt-cyg install patch

# Initialize opam
opam init --use-internal-solver -y -a

# Updating environment variables
eval $(opam config env)
export OCAML_TOPLEVEL_PATH=$(opam config var toplevel)
export OPAM_LIB_PATH=$(opam config var lib)

# Installation of dependencies
opam install --use-internal-solver -y ocamlfind ocamlbuild oasis extlib.1.7.2

# Install GMP
wget https://gmplib.org/download/gmp/gmp-${GMP_VERSION}.tar.bz2 -O - | tar -xj
(cd gmp-${GMP_VERSION}; ./configure --enable-shared --disable-static --enable-cxx; make -j 4; make install)
rm -rf gmp-${GMP_VERSION}

# Install MPFR
wget http://www.mpfr.org/mpfr-current/mpfr-${MPFR_VERSION}.tar.bz2 -O - | tar -xj
(cd mpfr-${MPFR_VERSION}; ./configure --enable-shared --disable-static --enable-thread-safe --with-gmp=/usr/local; make -j 4; make install)
rm -rf mpfr-${MPFR_VERSION}

# Installation MLGMP
opam install --use-internal-solver -y mlgmp

# Install PPL
wget http://www.bugseng.com/products/ppl/download/ftp/releases/${PPL_VERSION}/ppl-${PPL_VERSION}.tar.bz2 -O - | tar -xj
(cd ppl-${PPL_VERSION}; ./configure --prefix=/usr --enable-shared --disable-static --enable-interfaces=ocaml --with-gmp=/usr/local --with-mlgmp=${OPAM_LIB_PATH}/gmp --disable-documentation; make -j 4; make check; make install)
rm -rf ppl-${PPL_VERSION}

# Adding PPL interface to OPAM
mkdir ${OPAM_LIB_PATH}/ppl
cp METAS/META.ppl ${OPAM_LIB_PATH}/ppl/META

# Build IMITATOR
dos2unix.exe build.sh
bash build.sh
