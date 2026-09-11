#!/usr/bin/env bash
SRCIMG=$1
CACHEDIR=$(realpath $2)

SRCHASH=$(sha256sum $SRCIMG | awk '{print substr($1, 0, 10)}')

DSTDIR=${CACHEDIR}/foregrounds
DSTIMG=${DSTDIR}/${SRCHASH}
mkdir -p $DSTDIR

# Only process wallpaper when not already cached.
if ! [ -f "${DSTIMG}" ]; then
  echo "[INFO] Extracting wallpaper foreground"
  if rembg i -m birefnet-general $SRCIMG $DSTIMG &> $CACHEDIR/rembg.log; then
    echo "[INFO] Successfully extracted foreground"
  else
    echo "[ERROR] Failed to extract foreground"
    echo "[INFO] find log in ${CACHEDIR}/rembg.log"
    exit 1
  fi
else
  echo "[INFO] Foreground file in cache"
fi

echo -n "FOREGROUND $DSTIMG"
