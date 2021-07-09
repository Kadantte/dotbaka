#!/usr/bin/env bash

SAVE_SS="yes"
SAVE_DIR="${HOME}/Pictures/Screenshots"
COPY2CLIP="yes"
ENABLE_FRAME="yes"
FRAME_COLOR="#7E9DBC"
OPEN_FRAMED="no"
FRAMED_SHADOW_OPACITY="50"
TIMER_SEC="5"
QUALITY="100"
EXNOTIFY_SEND="dunstify"

# Create directory if needed
if [ ! -d "$SAVE_DIR" ]; then
    mkdir -p "$SAVE_DIR"
fi

LC_ALL=C LANG=C

noterr() { $EXNOTIFY_SEND -u low -r 12 "Install scrot!"; exit 1; }
type -p "scrot" &> /dev/null || noterr

{
    rm -f /tmp/*_scrot*.png; read -rt ".1" <> <(:) || :
    
    if scrot -q "${QUALITY:-75}" -sfbe 'mv $f /tmp/' -l style=dash,width=3,color="#7FA5FF" &> /dev/null; then
        $EXNOTIFY_SEND -r 12 -t 750 -i "$NOTIF_SS_ICON" -u low "" "Processing captured image .."
    else
        $EXNOTIFY_SEND -r 12 -t 500 -i "$NOTIF_SS_ICON" -u low "" "Screenshot canceled!" && exit 1
    fi
    
    for CURRENT in /tmp/*_scrot*.png; do
        CURRENT="$(echo $CURRENT | grep -oP '/tmp/\K[^.png]+' | sort -u)"
    done
    
    if [[ "$ENABLE_FRAME" = "yes" ]]; then
        convert /tmp/"$CURRENT".png \
        \( +clone -alpha extract -draw 'fill black polygon 0,0 0,8 8,0 fill white circle 8,8 8,0' \
        \( +clone -flip \) -compose Multiply -composite \( +clone -flop \) -compose Multiply -composite \) \
        -alpha off -compose CopyOpacity -composite /tmp/"$CURRENT"-rounded.png && rm -f /tmp/"$CURRENT".png

        convert /tmp/"$CURRENT"-rounded.png \( +clone -background black -shadow "${FRAMED_SHADOW_OPACITY:-25}"x10+0+5 \) \
        +swap -background none -layers merge +repage /tmp/"$CURRENT"-shadow.png && rm -f /tmp/"$CURRENT"-rounded.png

        convert /tmp/"$CURRENT"-shadow.png -bordercolor "${FRAME_COLOR:-#434c5e}" \
        -border 5 /tmp/"$CURRENT".png && rm -f /tmp/"$CURRENT"-shadow.png
    fi
    
    while true; do
        if [[ "$COPY2CLIP" = "yes" ]] && [[ -n "$(command -v "xclip")" ]]; then
            xclip -selection clipboard -target image/png -i /tmp/"$CURRENT".png
            STAT="\n(+CLIPBOARD)" && break
        elif [[ "$SAVE_SS" != "yes" ]]; then
            COPY2CLIP="yes"
        else break;
        fi
    done
    
    if [[ "$SAVE_SS" = "yes" ]]; then
        [[ ! -d "$SAVE_DIR/Screenshots" ]] && mkdir -p "$SAVE_DIR/Screenshots" || :
        mv /tmp/"$CURRENT".png "$SAVE_DIR/Screenshots"
        SV_LOC="$(echo $SAVE_DIR | grep -oE '[^/]+$')/Screenshots${STAT:-}"
    else
        rm -f /tmp/"$CURRENT".png
        SV_LOC="CLIPBOARD"
    fi
    
    $EXNOTIFY_SEND -r 12 -i "$NOTIF_SS_ICON" -u low "" "<span size='small'><u>$SV_LOC</u></span>\nChissu! Take Screenshot"
    
    if [[ -f "$SAVE_DIR/Screenshots/$CURRENT.png" ]]; then
        [[ "$OPEN_FRAMED" = "yes" ]] && [[ -n "$(command -v "viewnior")" ]] && \
        viewnior "$SAVE_DIR/Screenshots/$CURRENT.png"
    fi
} &> /dev/null &
