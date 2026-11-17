#!/usr/bin/env bash
set -euo pipefail

fail() { printf '%s\n' "$*" >&2; exit 1; }

if (( $# < 3 )); then
  fail "Uso: $0 CLIP SOTTOTITOLI MASTER.mp4 [--keep-audio] [INIZIO:FINE[:2] ...]"
fi

clip=$1
subtitles=$2
output=$3
shift 3
script_dir=$(cd "$(dirname "$0")" && pwd)
font_dir="$script_dir/../../MoneyTracker/Resources/Fonts"

# I nomi semplici delle clip si risolvono nella cartella sul Desktop.
[[ "$clip" == */* ]] || clip="$HOME/Desktop/clip-social/$clip"
[[ -f "$clip" && -f "$subtitles" ]] || fail "Clip o sottotitoli non trovati."
[[ "$output" == *.mp4 && ! -e "$output" ]] || fail "Indica un file MP4 di destinazione nuovo."
case "$subtitles" in
  *.srt|*.ass) ;;
  *) fail "Usa sottotitoli .srt o .ass." ;;
esac

keep_audio=0
if [[ ${1:-} == --keep-audio ]]; then
  keep_audio=1
  shift
fi

ffmpeg=${FFMPEG_BIN:-ffmpeg}
ffprobe=${FFPROBE_BIN:-ffprobe}
if [[ -z ${FFMPEG_BIN:-} ]] && command -v brew >/dev/null; then
  full_bin="$(brew --prefix ffmpeg-full)/bin"
  if [[ -x "$full_bin/ffmpeg" ]]; then
    ffmpeg="$full_bin/ffmpeg"
    ffprobe=${FFPROBE_BIN:-"$full_bin/ffprobe"}
  fi
fi
command -v "$ffmpeg" >/dev/null && command -v "$ffprobe" >/dev/null ||
  fail "Servono ffmpeg e ffprobe. Su macOS: brew install ffmpeg-full"
filters=$("$ffmpeg" -hide_banner -filters)
[[ "$filters" =~ [[:space:]]ass[[:space:]] ]] ||
  fail "FFmpeg è presente ma manca libass. Su macOS: brew install ffmpeg-full"

work=$(mktemp -d "${TMPDIR:-/tmp}/bucktrail-master.XXXXXXXX")
trap 'rm -rf -- "$work"' EXIT
mkdir "$work/fonts"
cp "$font_dir/SpaceGrotesk-Bold.ttf" "$font_dir/Inter_18pt-Regular.ttf" "$work/fonts/"

if [[ "$subtitles" == *.srt ]]; then
  "$ffmpeg" -v error -nostdin -i "$subtitles" "$work/converted.ass"
  awk '/^\[Events\]/{exit} {print}' "$script_dir/modello.ass" > "$work/text.ass"
  awk '/^\[Events\]/{events=1} events' "$work/converted.ass" >> "$work/text.ass"
else
  cp "$subtitles" "$work/text.ass"
fi

audio=0
if (( keep_audio )); then
  track=$("$ffprobe" -v error -select_streams a:0 -show_entries stream=index -of csv=p=0 "$clip")
  [[ -z "$track" ]] || audio=1
fi

video='[0:v:0]'
sound='[0:a:0]'
graph=''
if (( $# )); then
  duration=$("$ffprobe" -v error -show_entries format=duration -of csv=p=0 "$clip")
  count=$#
  inputs=''
  i=0
  if (( count > 1 )); then
    graph="[0:v:0]split=$count"
    for ((n=0; n<count; n++)); do graph+="[sourcev$n]"; done
    graph+=';'
    if (( audio )); then
      graph+="[0:a:0]asplit=$count"
      for ((n=0; n<count; n++)); do graph+="[sourcea$n]"; done
      graph+=';'
    fi
  fi
  for segment in "$@"; do
    if [[ ! "$segment" =~ ^([0-9]+([.][0-9]+)?):([0-9]+([.][0-9]+)?)(:2)?$ ]]; then
      fail "Intervallo non valido: $segment. Formato: INIZIO:FINE[:2]."
    fi
    start=${BASH_REMATCH[1]}
    end=${BASH_REMATCH[3]}
    speed=1
    [[ -z ${BASH_REMATCH[5]} ]] || speed=2
    awk -v start="$start" -v end="$end" -v duration="$duration" \
      'BEGIN {exit !(end > start && end <= duration + 0.001)}' ||
      fail "Intervallo fuori dalla clip o vuoto: $segment"
    from_video='[0:v:0]'
    from_audio='[0:a:0]'
    if (( count > 1 )); then
      from_video="[sourcev$i]"
      from_audio="[sourcea$i]"
    fi
    graph+="${from_video}trim=start=$start:end=$end,setpts=(PTS-STARTPTS)/$speed[v$i];"
    inputs+="[v$i]"
    if (( audio )); then
      graph+="${from_audio}atrim=start=$start:end=$end,asetpts=PTS-STARTPTS,atempo=$speed[a$i];"
      inputs+="[a$i]"
    fi
    i=$((i + 1))
  done
  video='[v0]'
  sound='[a0]'
  if (( count > 1 )); then
    video='[cutv]'
    sound='[cuta]'
    graph+="${inputs}concat=n=$count:v=1:a=$audio$video"
    (( ! audio )) || graph+="$sound"
    graph+=';'
  fi
fi

normalize=''
transfer=$("$ffprobe" -v error -select_streams v:0 -show_entries stream=color_transfer -of csv=p=0 "$clip")
case "$transfer" in
  smpte2084|arib-std-b67)
    [[ "$filters" =~ [[:space:]]zscale[[:space:]] ]] ||
      fail "Per convertire HDR in SDR serve zscale (ffmpeg-full su macOS)."
    normalize='zscale=transfer=linear:npl=100,format=gbrpf32le,zscale=primaries=bt709,tonemap=tonemap=mobius:desat=2,zscale=transfer=bt709:matrix=bt709:range=limited,'
    ;;
  bt709|unknown|unspecified|'') ;;
  *)
    normalize='colorspace=all=bt709,'
    ;;
esac

# Il testo viene composto nel riquadro di sicurezza. I pixel esterni restano quelli della clip.
graph+="$video${normalize}scale=1080:1920:force_original_aspect_ratio=decrease:force_divisible_by=2:out_color_matrix=bt709:out_range=tv,pad=1080:1920:(ow-iw)/2:(oh-ih)/2:color=0x0E1210,setsar=1,fps=30,format=yuv420p,split[base][caption];"
graph+="[caption]ass=text.ass:fontsdir=fonts:shaping=complex,crop=780:970:120:280[safe];[base][safe]overlay=120:280,setparams=range=limited:color_primaries=bt709:color_trc=bt709:colorspace=bt709[out]"
audio_args=(-an)
if (( audio )); then audio_args=(-map "$sound" -c:a aac -b:a 192k -ar 48000); fi

# Percorsi fissi nel filtro ASS, anche quando la directory di lavoro contiene spazi.
case "$clip" in /*) ;; *) clip="$PWD/$clip";; esac
(
  cd "$work"
  "$ffmpeg" -hide_banner -loglevel warning -nostdin -i "$clip" \
    -filter_complex "$graph" -map '[out]' "${audio_args[@]}" \
    -c:v libx264 -preset fast -pix_fmt yuv420p \
    -b:v 16M -minrate 16M -maxrate 16M -bufsize 32M -x264-params nal-hrd=cbr \
    -color_primaries bt709 -color_trc bt709 -colorspace bt709 -color_range tv \
    -map_metadata -1 -map_chapters -1 -movflags +faststart final.mp4
)
# Il file finito compare solo dopo la codifica e non sovrascrive altri master.
(set -o noclobber; cat "$work/final.mp4" > "$output")
printf 'Master pronto: %s\n' "$output"
