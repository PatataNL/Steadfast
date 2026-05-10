#!/bin/sh

grep '^.\{81\}' \
  shaders/*.glsl \
  shaders/**/*.glsl \
  shaders/**/**/*.glsl \
  shaders/*.fsh \
  shaders/*.vsh \
  shaders/program/**/*.fsh \
  shaders/program/**/*.vsh

grep '^.\{81\}' \
  shaders/*.properties \
  pipeline/*.properties \
  pipeline/**/*.properties \
  pipeline/**/**/*.properties
