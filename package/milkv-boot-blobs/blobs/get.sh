#!/usr/bin/env bash
# Not to be run in the buildroot env. There's not host-7z
set -xe
[[ -f base.zip ]] || curl -Lo base.zip -\# 'https://github.com/milkv-duo/duo-buildroot-sdk/releases/download/v1.1.4/milkv-duo-sd-v1.1.4.img.zip'
[[ -f milkv-duo-sd-v1.1.4.img ]] || unzip base.zip
[[ -f 0.fat ]] || 7z x milkv-duo-sd-v1.1.4.img 0.fat
[[ -f fip.bin ]] || 7z x 0.fat fip.bin boot.sd
