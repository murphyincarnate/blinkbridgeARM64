#!/bin/bash

stream_name="$1"
full_video="$2"

if [ -z "$full_video" ] || [ -z "$stream_name" ]; then
  echo "Usage: $0 stream_name video"
  exit 1
fi

. utils.sh
set_log_level "debug"

last_frame="${stream_name}_still.mp4"
next_concat="${stream_name}_next.concat"

# backup list and enqueue clip
debug "queueing clip"
cp -f ${next_concat} ${next_concat}.prev
echo "ffconcat version 1.0" > ${next_concat}
echo "file $full_video" >> ${next_concat}

# make a frame from the last second of the input video
debug "making last frame clip"
./make_frame.sh "$full_video" "$last_frame" &
pid_make_frame=$!

# wait for the new concat list to be processed
debug "waiting for current clip to finish"
sleep 0.51

debug "waiting last frame to be generated"
wait $pid_make_frame
if [ $? -ne 0 ]; then
    error "failed to extract last frame"
    mv ${next_concat}.prev ${next_concat}
    exit 1
fi

# make new concat list to loop on last frame
echo "ffconcat version 1.0" > ${next_concat}
echo "file $last_frame" >> ${next_concat}

info "made and queued input and last frame"

rm ${next_concat}.prev