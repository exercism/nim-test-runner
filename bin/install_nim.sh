#!/bin/bash

set -ex

readonly ARCHIVE_FILENAME='nim.tar.xz'
readonly NIM_VERSION='1.6.0'
readonly BUILD_DIR='/build/nim'
readonly INSTALL_DIR='/nim/'
mkdir -p "${BUILD_DIR}"

(
  cd "${BUILD_DIR}" || exit
  curl -sSfL -o "${ARCHIVE_FILENAME}" "https://nim-lang.org/download/nim-${NIM_VERSION}.tar.xz"
  tar --strip-components=1 -xf "${ARCHIVE_FILENAME}"
  sh build.sh
  rm -r c_code "${ARCHIVE_FILENAME}"

  bin/nim c --skipUserCfg --skipParentCfg koch.nim
  ./koch boot -d:release -d:leanCompiler

  mkdir -p "${INSTALL_DIR}"
  mv bin config lib "${INSTALL_DIR}"
)

rm -r "${BUILD_DIR}"
