#!/usr/bin/env bash
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/bucktrail-test.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
ffmpeg=${FFMPEG_BIN:-ffmpeg}
ffprobe=${FFPROBE_BIN:-ffprobe}

"$ffmpeg" -v error -f lavfi -i 'testsrc2=size=432x768:rate=30:duration=6' \
  -f lavfi -i 'sine=frequency=440:duration=6' -c:v libx264 -c:a aac "$work/clip di prova.mp4"

cat > "$work/test.srt" <<'SRT'
1
00:00:00,250 --> 00:00:02,000
Saldo previsto

2
00:00:02,250 --> 00:00:04,000
Bucktrail · link in bio
SRT

"$here/master.sh" "$work/clip di prova.mp4" "$here/modello.ass" "$work/ass.mp4" \
  0:2 2:4:2 4:6
"$here/master.sh" "$work/clip di prova.mp4" "$work/test.srt" "$work/srt.mp4" \
  --keep-audio 0:2 2:4:2 4:6

for master in "$work/ass.mp4" "$work/srt.mp4"; do
  stats=$("$ffprobe" -v error -select_streams v:0 \
    -show_entries stream=codec_name,width,height,r_frame_rate,pix_fmt,color_transfer,color_space,color_primaries,bit_rate,duration \
    -of default=nw=1 "$master")
  for expected in codec_name=h264 width=1080 height=1920 r_frame_rate=30/1 \
    pix_fmt=yuv420p color_transfer=bt709 color_space=bt709 color_primaries=bt709; do
    grep -qx "$expected" <<< "$stats"
  done
  awk -F= '
    $1=="bit_rate" {rate=$2}
    $1=="duration" {duration=$2}
    END {exit !(rate>=15000000 && rate<=20000000 && duration>=4.9 && duration<=5.1)}
  ' <<< "$stats"
done

audio_codec() {
  "$ffprobe" -v error -select_streams a:0 -show_entries stream=codec_name -of csv=p=0 "$1"
}
[[ -z "$(audio_codec "$work/ass.mp4")" ]]
[[ "$(audio_codec "$work/srt.mp4")" == aac ]]
printf 'Test di fumo superato: ASS, SRT, safe zone configurata, tagli, 2x e specifiche master.\n'
