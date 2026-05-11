#!/bin/sh

rm -rf ./out
rm -rf ./work

mkarchiso -v .

echo ":: Complete!"