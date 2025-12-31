#!/bin/bash

ffmpeg-sub-mkv-mp4() {
    ffmpeg -i $1.mkv -vf subtitles=$1.mkv $1.mp4
}

ffmpeg-mkv-mp4-nv-h24() {
    local vid="$1"
    local cq="-cq:v 26"
    local speed="-preset:v slow"
    local pix_fmt="-pix_fmt yuv420p"
    shift
    while [ "$#" != 0 ]; do
        if [ "$1" == "-cq" ]; then
            shift
            cq="-cq:v $1"
        elif [ "$1" == "-p" ]; then
            shift
            speed="-preset:v $q"
        elif [ "$1" == "-f" ]; then
            shift
            pix_fmt="-pix_fmt $1"
        fi
        shift
    done
    echo "Running FFMPEG with settings: $vid $cq $speed $pix_fmt"
    ffmpeg -hwaccel_output_format cuda -i "$vid.mkv" -c:v h264_nvenc $speed -rc:v vbr $cq $pix_fmt -c:a aac -b:a 128k "$vid.mp4"
}
ffmpeg-sub-mkv-mp4-nv-h24() {
    local vid="$1"
    local cq="-cq:v 26"
    local speed="-preset:v slow"
    local pix_fmt="-pix_fmt yuv420p"
    local audio_stream=""
    local sub_stream=""
    local sub_type="aas"
    local output_suffix=""
    shift
    while [ "$#" != 0 ]; do
        if [ "$1" == "-cq" ]; then
            shift
            cq="-cq:v $1"
        elif [ "$1" == "-p" ]; then
            shift
            speed="-preset:v $q"
        elif [ "$1" == "-f" ]; then
            shift
            pix_fmt="-pix_fmt $1"
        elif [ "$1" == "-a" ]; then
            shift
            audio_stream=$1
        elif [ "$1" == "-s" ]; then
            shift
            sub_stream=$1
        elif [ "$1" == "-st" ]; then
            shift
            sub_type=$1
        elif [ "$1" == "--suffix" ]; then
            shift
            output_suffix="-$1"
        fi
        shift
    done
    
    # Handle subtitle extraction
    local sub_file="$vid$output_suffix.$sub_type"
    if [ -z "$sub_stream" ]; then
        sub_file=$vid.mkv
    else
        mkvextract tracks $vid.mkv $sub_stream:$vid$output_suffix.$sub_type
    fi

    # Handle custom audio mapping
    local audio_map=""
    if [ -n "$audio_stream" ]; then
        audio_map="-map 0:a:$audio_stream"
    else
        audio_map="-map 0:a:?"
    fi
    
    # Handle custom video mapping TODO
    local video_map="-map 0:v:?"

    echo "Running FFMPEG with settings: $vid $cq $speed $pix_fmt audio_stream $audio_stream suffix $output_suffix sub_stream $sub_stream sub_type $sub_type"
    local FFMPEG_CMD="ffmpeg -hwaccel_output_format cuda -i $vid.mkv -c:v h264_nvenc $speed -rc:v vbr $cq $pix_fmt -c:a aac -b:a 128k -ac 2 -vf subtitles=$sub_file $video_map $audio_map $vid$output_suffix.mp4"
    echo $FFMPEG_CMD
    $FFMPEG_CMD
    if [ -n "$sub_stream" ]; then
        rm $sub_file
    fi
}
ffmpeg-sub-mkv-mp4-av1() {
    local vid="$1"
    local cq="-crf 28"
    local speed="-cpu-used 1"
    local tiles=""
    shift
    while [ "$#" != 0 ]; do
        if [ "$1" == "-crf" ]; then
            shift
            cq="-crf $1"
        elif [ "$1" == "-s" ]; then
            shift
            speed="-cpu-used $1"
        elif [ "$1" == "-t" ]; then
            shift
            tiles="-tiles $1"
        fi
        shift
    done
    echo "Running FFMPEG with settings: $vid $crf $speed $tiles"
    ffmpeg -i "$vid.mkv" -c:v libaom-av1 -strict -2 $cq -b:v 0 -row-mt 1 $speed $tiles -c:a aac -b:a 128k -vf subtitles="$vid.mkv" "$vid.mp4"
}

ffmpeg-sub-mkv-mp4-svtav1() {
    local vid="$1"
    local cq="-qp 50"
    local tile_c=""
    local tile_r=""
    local preset="-preset 8"
    shift
    while [ "$#" != 0 ]; do
        if [ "$1" == "-qp" ]; then
            shift
            cq="-qp $1"
        elif [ "$1" == "-tc" ]; then
            shift
            tile_c="-tile_columns $1"
        elif [ "$1" == "-tr" ]; then
            shift
            tile_r="-tile_rows $1"
        elif [ "$1" == "-p" ];  then
            shift
            preset="-preset $1"
        fi
        shift
    done
    echo "Running FFMPEG with settings: $vid $qp $tile_c $tile_r $preset"
    ffmpeg -i "$vid.mkv" -threads 12 -c:v libsvtav1 $preset -rc cqp $cq $tile_c $tile_r -c:a aac -b:a 128k -vf subtitles="$vid.mkv" "$vid.mp4"
}

ffmpeg-get-encoders() {
    for i in encoders decoders filters; do
        echo $i:; ffmpeg -hide_banner -${i} | egrep -i "npp|cuvid|nvenc|cuda"
    done
}

batch-rename-mkv() {
    for f in *; do mv "$f" ./$1`echo "$f" | awk -v pos="$2" '{print $pos}'`.mkv; done
}

