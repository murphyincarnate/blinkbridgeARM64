#!/bin/bash

# Usage: ./script.sh input_video.mp4 output_video.mp4

input_video="$1"
output_video="$2"

. utils.sh
set_log_level "debug"

output_duration=0.5  # Duration of the output clip

# Check if input and output files are provided
if [ -z "$input_video" ] || [ -z "$output_video" ]; then
  echo "Usage: ./script.sh input_video.mp4 output_video.mp4"
  exit 1
fi

# Function to extract parameters using ffprobe
extract_parameters() {
  local video_file=$1
  local ffprobe_params=(
    -hide_banner
    -v error
    -show_entries
    stream=codec_name,pix_fmt,width,height,bit_rate,r_frame_rate,color_space,color_transfer,color_primaries,time_base,profile,level,color_range,channels,channel_layout,sample_rate
    -of default=noprint_wrappers=1
    "$video_file"
  )
  
  params=$(ffprobe "${ffprobe_params[@]}" 2>&1)
  if [ $? -ne 0 ]; then
    error "ffprobe failed to extract parameters."
    exit 1
  fi
}

# Function to parse parameters into an associative array
declare -A codec_params
parse_parameters() {
  local current_codec_name=""
  while read -r line; do
    key=$(echo "$line" | cut -d'=' -f1)
    value=$(echo "$line" | cut -d'=' -f2)
    if [[ $key == "codec_name" ]]; then
      current_codec_name="$value"
    fi
    codec_params["${current_codec_name}_$key"]="$value"
  done <<< "$params"
}

# Function to print video and audio parameters using a loop
print_parameters() {
  debug "parameters:"
  for key in "${!codec_params[@]}"; do
    debug "   $key: ${codec_params[$key]}"
  done
}

# Function to extract the last frame
extract_last_frame() {
  local random_filename=$(mktemp last_frame_XXXXXX.jpg)
  local ffmpeg_params=(
    -hide_banner
    -y
    -v error
    -sseof -1
    -i "$input_video"
    -update 1
    -pix_fmt yuv420p
    -q:v 1
    "$random_filename"
  )

  ffmpeg "${ffmpeg_params[@]}" 2>&1
  if [ $? -ne 0 ]; then
    error "ffmpeg failed to extract the last frame."
    exit 1
  fi
  
  echo "$random_filename"
}

# Function to create a new video with dummy audio using the last frame
create_video() {
  local last_frame_filename=$(extract_last_frame)
  local time_base_denominator=$(echo "${codec_params[h264_time_base]}" | cut -d'/' -f2)
  local fps_value=$(echo "${codec_params[h264_r_frame_rate]}" | awk -F '/' '{ print $1 / $2 }')
  
  local ffmpeg_params=(
    -hide_banner
    -y
    -v error
    -loop 1
    -i "$last_frame_filename"
    -f lavfi
    -i "anullsrc=channel_layout=${codec_params[aac_channels]}:sample_rate=${codec_params[aac_sample_rate]}"
    -c:v "${codec_params[h264_codec_name]}"
    -pix_fmt "${codec_params[h264_pix_fmt]}"
    -t "$output_duration"
    -vf "scale=${codec_params[h264_width]}:${codec_params[h264_height]},fps=$fps_value"
    -b:v "${codec_params[h264_bit_rate]}"
    -profile:v "${codec_params[h264_profile]}"
    -level:v "${codec_params[h264_level]}"
    -colorspace "${codec_params[h264_color_space]}"
    -color_trc "${codec_params[h264_color_transfer]}"
    -color_primaries "${codec_params[h264_color_primaries]}"
    -color_range "${codec_params[h264_color_range]}"
    # -movflags faststart
    -video_track_timescale "$time_base_denominator"
    -fps_mode passthrough
    -c:a aac
    -ar "${codec_params[aac_sample_rate]}"
    -ac "${codec_params[aac_channels]}"
    "$output_video"
  )

  ffmpeg "${ffmpeg_params[@]}" 2>&1
  if [ $? -ne 0 ]; then
    error "ffmpeg failed to create the video."
    exit 1
  fi

  # Remove the temporary last frame file
  rm "$last_frame_filename"
}

# Main script execution
debug "getting video parameters"
extract_parameters "$input_video"
parse_parameters
print_parameters

debug "extracting last frame and generating video clip"
create_video