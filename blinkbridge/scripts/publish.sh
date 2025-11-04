#!/bin/bash

stream_name="$1"
first_clip="$2"

if [ -z "$stream_name" ] || [ -z "$first_clip" ]; then
  echo "Usage: ./script.sh stream_name first_clip"
  exit 1
fi

. utils.sh
set_log_level "info"

port=8554

start_stream() {
    local input_file="$1"
    local output_url="$2"

    info "publishing to $output_url"
    
    # Define the ffmpeg arguments in an array
    local ffmpeg_args=(
        -v error
        -hide_banner
        # -r 24
        -fflags +igndts+genpts
        -re
        -stream_loop -1
        -f concat
        -safe 0
        -i "$input_file"
        -flush_packets 0
        -c:v copy
        -c:a copy
        -f rtsp
        # -avoid_negative_ts 1
        # -use_wallclock_as_timestamps 1
        -fps_mode drop
        # -an
        "$output_url"
    )
    
    # Call ffmpeg with the arguments from the array
    ffmpeg "${ffmpeg_args[@]}"
    if [ $? -ne 0 ]; then
        error "ffmpeg failed"
        exit 1
    fi
}

make_concat_files() {
    local stream_name="$1"
    local first_clip="$2"

    local next_concat="${stream_name}_next.concat"
    local concat_file="${stream_name}.concat"

    echo "ffconcat version 1.0" > $concat_file
    echo "file $next_concat" >> $concat_file
    echo "file $next_concat" >> $concat_file

    echo "ffconcat version 1.0" > $next_concat
    echo "file $first_clip" >> $next_concat
    # echo "file $first_clip" >> $next_concat
}

debug "making concat file"
make_concat_files "$stream_name" "$first_clip"

start_stream "${stream_name}.concat" "rtsp://localhost:${port}/${stream_name}"
