#!/bin/sh

rm -rf build \
&& mkdir build \
&& cp -r shaders build/shaders \
&& cp LICENSE.md build/ \
&& cp LICENSE-ADDITIONAL-TERMS.md build/ \
&& cp README.md build/ \
&& rm -f Steadfast-$1.zip \
&& cd build \
&& zip --strip-extra -r Steadfast-$1.zip . \
&& cd ..

