#!/bin/bash

file="$1"
dirname=$(basename "$file" .zip);

mkdir $dirname;
cd $dirname;
unzip ../$file
