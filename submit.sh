#!/bin/bash

rm -f haxelib.zip
zip -r haxelib.zip src haxelib.json README.md LICENSE extraParams.hx
haxelib submit haxelib.zip