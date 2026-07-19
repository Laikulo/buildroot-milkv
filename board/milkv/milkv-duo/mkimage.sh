#!/usr/bin/env bash

set -xe

IMAGES_DIR="$1"
SCRIPT_DIR="$(dirname "$(realpath "$0")")"

FW_DIR="$IMAGES_DIR/duo-firmware"
## Create output in images for work area
[[ -d $FW_DIR ]] || install -d "$FW_DIR"

CVI_FW_DIR="$HOST_DIR/share/firmware/cvi"
MILKV_FW_DIR="$HOST_DIR/share/firmware/milkv"

USE_VENDOR_FIP=1
#USE_VENDOR_KERNEL=1
USE_VENDOR_DT=1

if [[ $USE_VENDOR_FIP ]]; then
	cp "$MILKV_FW_DIR/fip.bin" "$FW_DIR/fip.bin"
else
# Not quite sure why the RTOS below is required. IIUC, it should be optional
## TODO: UBOOT
## TODO: opensbi
"$HOST_DIR/bin/cvi-fiptool" \
  --fsbl "$CVI_FW_DIR/fsbl/cv180x.bin" \
  --ddr_param "$CVI_FW_DIR/ddr_param.bin" \
  --rtos "$CVI_FW_DIR/cvirtos.bin" \
  --opensbi "/dev/null" \
  --uboot "/dev/null" \
  "$FW_DIR/fip.bin"
fi

if [[ $USE_VENDOR_KERNEL ]]; then
	KERNEL_PATH="$MILKV_FW_DIR/kernel.bin"
else
	KERNEL_PATH="$IMAGES_DIR/Image"
fi

if [[ $USE_VENDOR_DT ]]; then
	DT_PATH="$MILKV_FW_DIR/dt.bin"
else
	echo >&2 "Non-vendor DT not supported"
	exit 1
fi

"$HOST_DIR/bin/lzma" -c -9 -f -k "$KERNEL_PATH" > "$KERNEL_PATH.lzma"

cat >"$IMAGES_DIR/duo-firmware/sd.its" <<-END
/dts-v1/;

/ {
	description = "Various kernels, ramdisks and FDT blobs";
	#address-cells = <0x02>;

	images {

		kernel-1 {
			description = "cvitek kernel";
			type = "kernel";
			data = /incbin/("$KERNEL_PATH.lzma");
			arch = "riscv";
			os = "linux";
			compression = "lzma";
			load = <0x00 0x80200000>;
			entry = <0x00 0x80200000>;

			hash-2 {
				algo = "crc32";
			};
		};

		fdt-cv1800b_milkv_duo_sd {
			description = "cvitek device tree - cv1800b_milkv_duo_sd";
			data = /incbin/("$DT_PATH");
			type = "flat_dt";
			arch = "riscv";
			compression = "none";

			hash-1 {
				algo = "sha256";
			};
		};
	};

	configurations {

		config-cv1800b_milkv_duo_sd {
			description = "boot cvitek system with board cv1800b_milkv_duo_sd";
			kernel = "kernel-1";
			fdt = "fdt-cv1800b_milkv_duo_sd";
		};
	};
};
END


"$HOST_DIR/bin/mkimage" -f "$IMAGES_DIR/duo-firmware/sd.its" "$IMAGES_DIR/duo-firmware/boot.sd"

"$HOST_DIR/bin/genimage"  --rootpath "$IMAGES_DIR" --inputpath "$IMAGES_DIR" --outputpath "$IMAGES_DIR" --config "$SCRIPT_DIR/genimage.cfg"
