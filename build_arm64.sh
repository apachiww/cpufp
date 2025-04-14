SRC=arm64
ASM=$SRC/asm
COMM=common
BUILD_DIR=build_dir
OS=$(uname -o)

# make directory
if [ -d "$BUILD_DIR" ]; then
    rm -rf $BUILD_DIR/*
else
    mkdir $BUILD_DIR
fi

# build common tools
g++ -O3 -std=gnu++17 -c $COMM/table.cpp -o $BUILD_DIR/table.o
g++ -O3 -std=gnu++17 -pthread -c $COMM/smtl.cpp -o $BUILD_DIR/smtl.o

# gen benchmark macro according to cpuid feature
gcc $SRC/cpuid.c -o $BUILD_DIR/cpuid
SIMD_MACRO=" "
SIMD_OBJ=" "
AS_EXTRA_FLAGS="-mcpu=all"
if [ "${OS}" == "Darwin" ]; then
    AS_EXTRA_FLAGS="-mcpu=apple-m2"
fi
for SIMD in `$BUILD_DIR/cpuid`;
do
    SIMD_MACRO="$SIMD_MACRO-D$SIMD "
    SIMD_OBJ="$SIMD_OBJ$BUILD_DIR/$SIMD.o "
    as ${AS_EXTRA_FLAGS} -c $ASM/$SIMD.S -o $BUILD_DIR/$SIMD.o
done

# compile cpufp
EXTRA_CFLAGS=""
if [ "${OS}" != "Darwin" ]; then
    EXTRA_CFLAGS="-z noexecstack"
fi
g++ -std=gnu++17 -O3 -I$COMM $SIMD_MACRO -c $SRC/cpufp.cpp -o $BUILD_DIR/cpufp.o
g++ -std=gnu++17 -O3 ${EXTRA_CFLAGS} -pthread -o cpufp $BUILD_DIR/cpufp.o $BUILD_DIR/smtl.o $BUILD_DIR/table.o $SIMD_OBJ
