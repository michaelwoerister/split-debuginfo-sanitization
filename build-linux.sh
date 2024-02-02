#!/bin/bash

BASE_DIR=$(pwd)
PROJECT_BASE_DIR=$BASE_DIR/split-debuginfo-sanitization
DUMP_DIR=$BASE_DIR/debuginfo-dump-linux
MY_CARGO_HOME=$BASE_DIR/my-cargo-home

mkdir -p $MY_CARGO_HOME

mkdir -p $DUMP_DIR
rm -f $DUMP_DIR/*


cd $PROJECT_BASE_DIR

cargo clean

CARGO_HOME=$MY_CARGO_HOME cargo build --release --target x86_64-unknown-linux-gnu

ARTIFACT_PATH=$PROJECT_BASE_DIR/target/x86_64-unknown-linux-gnu/release/split-debuginfo-sanitization

# We delete the .dwp file so that readelf cannot get clever and try to read
# strings from it when decoding the binary. Just in case.
rm $ARTIFACT_PATH.dwp

readelf --debug-dump=no-follow-links -wl $ARTIFACT_PATH > $DUMP_DIR/binary.split.raw.debug_line
readelf --debug-dump=no-follow-links -wL $ARTIFACT_PATH > $DUMP_DIR/binary.split.decoded.debug_line
readelf --debug-dump=no-follow-links -w $ARTIFACT_PATH > $DUMP_DIR/binary.split.all.debuginfo

echo "LOOKING FOR PROJECT BASE DIR IN BINARY .debug_line"
cat $DUMP_DIR/binary.split.raw.debug_line | grep "$PROJECT_BASE_DIR"
echo "FOUND $(cat $DUMP_DIR/binary.split.raw.debug_line | grep -c "$PROJECT_BASE_DIR") INSTANCES"


echo "LOOKING FOR CARGO_HOME DIR IN BINARY .debug_line"
cat $DUMP_DIR/binary.split.raw.debug_line | grep $MY_CARGO_HOME
echo "FOUND $(cat $DUMP_DIR/binary.split.raw.debug_line | grep -c $MY_CARGO_HOME) INSTANCES"

echo "LOOKING FOR PROJECT BASE DIR IN COMPLETE BINARY DEBUGINFO DUMP"
cat $DUMP_DIR/binary.split.all.debuginfo | grep "$BASE_DIR"
echo "FOUND $(cat $DUMP_DIR/binary.split.all.debuginfo | grep -c "$BASE_DIR") INSTANCES"

echo "LOOKING FOR BASE DIR IN BINARY (RAW GREP)"
cat $ARTIFACT_PATH | grep "$BASE_DIR"
echo "FOUND $(cat $ARTIFACT_PATH | grep -c "$BASE_DIR") INSTANCES"


## build with debug_link
cd $PROJECT_BASE_DIR
cargo clean
CARGO_PROFILE_RELEASE_SPLIT_DEBUGINFO="off" CARGO_HOME=$MY_CARGO_HOME cargo build --release --target x86_64-unknown-linux-gnu

ARTIFACT_PATH=$PROJECT_BASE_DIR/target/x86_64-unknown-linux-gnu/release/split-debuginfo-sanitization

# Separate out the debuginfo and add a .gnu_debuglink to the stripped binary
objcopy --only-keep-debug $ARTIFACT_PATH $ARTIFACT_PATH.debug
strip -S $ARTIFACT_PATH -o $ARTIFACT_PATH.stripped
objcopy --add-gnu-debuglink=$ARTIFACT_PATH.debug $ARTIFACT_PATH.stripped

# We delete the files with debuginfo so that readelf cannot get clever and try to read
# strings from it when decoding the binary. Just in case.
rm $ARTIFACT_PATH
rm $ARTIFACT_PATH.debug

readelf --debug-dump=no-follow-links -wl $ARTIFACT_PATH.stripped > $DUMP_DIR/binary.stripped.raw.debug_line
readelf --debug-dump=no-follow-links -wL $ARTIFACT_PATH.stripped > $DUMP_DIR/binary.stripped.decoded.debug_line
readelf --debug-dump=no-follow-links -w $ARTIFACT_PATH.stripped > $DUMP_DIR/binary.stripped.all.debuginfo

echo "LOOKING FOR PROJECT BASE DIR IN BINARY"
cat $DUMP_DIR/binary.stripped.raw.debug_line | grep $PROJECT_BASE_DIR
echo "FOUND $(cat $DUMP_DIR/binary.stripped.raw.debug_line | grep -c $PROJECT_BASE_DIR) INSTANCES"

echo "LOOKING FOR CARGO_HOME DIR IN BINARY"
cat $DUMP_DIR/binary.stripped.raw.debug_line | grep $MY_CARGO_HOME
echo "FOUND $(cat $DUMP_DIR/binary.stripped.raw.debug_line | grep -c $MY_CARGO_HOME) INSTANCES"

echo "LOOKING FOR PROJECT BASE DIR IN COMPLETE BINARY DEBUGINFO DUMP"
cat $DUMP_DIR/binary.stripped.all.debuginfo | grep "$BASE_DIR"
echo "FOUND $(cat $DUMP_DIR/binary.stripped.all.debuginfo | grep -c "$BASE_DIR") INSTANCES"

echo "LOOKING FOR BASE DIR IN BINARY (RAW GREP)"
cat $ARTIFACT_PATH.stripped | grep "$BASE_DIR"
echo "FOUND $(cat $ARTIFACT_PATH.stripped | grep -c "$BASE_DIR") INSTANCES"
