#!/bin/sh
rm -rf converted \
&& mkdir converted \
&& for png in *.png
	do magick convert "$png" -quality 98 "converted/$png.jpg";
done
