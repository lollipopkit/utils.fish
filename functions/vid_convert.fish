# vid_convert - Convert video files between common formats using ffmpeg
#
# Requires: ffmpeg (install via `brew install ffmpeg` on macOS or
#           `sudo apt install ffmpeg` on Debian/Ubuntu).
# Usage: vid_convert <input_video> <format>
# Supported formats: h264, hevc, mov, mkv, webm, avi

function vid_convert -d "Convert video to a target format with ffmpeg"
    set -l supported_formats h264 hevc mov mkv webm avi
    set -l format_list (string join ' ' $supported_formats)

    if test (count $argv) -eq 0
        echo "Usage: vid_convert <input_video> <format>"
        echo "Supported formats: $format_list"
        echo ""
        echo "Examples:"
        echo "  vid_convert clip.mp4 h264"
        echo "  vid_convert ~/Movies/raw.mov webm"
        return 1
    end

    switch $argv[1]
        case -h --help
            echo "Usage: vid_convert <input_video> <format>"
            echo "Supported formats: $format_list"
            echo ""
            echo "Examples:"
            echo "  vid_convert clip.mp4 h264"
            echo "  vid_convert ~/Movies/raw.mov webm"
            return 0
    end

    if test (count $argv) -lt 2
        echo "vid_convert: missing required arguments" >&2
        echo "Usage: vid_convert <input_video> <format>"
        echo "Supported formats: $format_list"
        return 1
    end

    if not type -q ffmpeg
        echo "vid_convert: ffmpeg not found. Install with 'brew install ffmpeg' (macOS) or 'sudo apt install ffmpeg' (Linux)." >&2
        return 127
    end

    set -l input $argv[1]
    if not test -f "$input"
        echo "vid_convert: '$input' does not exist" >&2
        return 1
    end

    set -l format (string lower $argv[2])
    if not contains -- $format $supported_formats
        echo "vid_convert: unsupported format '$format'" >&2
        echo "Supported formats: $format_list"
        return 1
    end

    set -l base (string replace -r '\\.[^./]+$' '' "$input")
    if test "$base" = "$input"
        set base "$input"
    end

    set -l output ""
    set -l video_args
    set -l audio_args
    set -l extra_args
    set -l os_name (uname)

    switch $format
        case h264
            set output "$base.h264.mp4"
            switch $os_name
                case Darwin
                    set video_args -c:v h264_videotoolbox -b:v 5M
                case '*'
                    set video_args -c:v libx264 -preset medium -crf 20
            end
            set audio_args -c:a aac -b:a 192k
        case hevc
            set output "$base.hevc.mp4"
            switch $os_name
                case Darwin
                    set video_args -c:v hevc_videotoolbox -b:v 5M
                case '*'
                    set video_args -c:v libx265 -preset medium -crf 24
            end
            set audio_args -c:a aac -b:a 192k
        case mov
            set output "$base.mov"
            set video_args -c:v prores_ks -profile:v 3
            set audio_args -c:a pcm_s16le
        case mkv
            set output "$base.mkv"
            switch $os_name
                case Darwin
                    set video_args -c:v h264_videotoolbox -b:v 5M
                case '*'
                    set video_args -c:v libx264 -preset medium -crf 20
            end
            set audio_args -c:a aac -b:a 192k
        case webm
            set output "$base.webm"
            set video_args -c:v libvpx-vp9 -b:v 2M -row-mt 1 -deadline good -cpu-used 1
            set audio_args -c:a libopus -b:a 128k
            set extra_args -tile-columns 2 -frame-parallel 1
        case avi
            set output "$base.avi"
            set video_args -c:v mpeg4 -qscale:v 2
            set audio_args -c:a libmp3lame -b:a 192k
    end

    if test -z "$output"
        echo "vid_convert: failed to determine output path" >&2
        return 1
    end

    echo "Converting '$input' -> '$output' ($format)"
    command ffmpeg -hide_banner -y -i "$input" $video_args $audio_args $extra_args "$output"
    set -l status_code $status

    if test $status_code -eq 0
        echo "vid_convert: conversion complete"
    else
        echo "vid_convert: ffmpeg exited with status $status_code" >&2
    end

    return $status_code
end
