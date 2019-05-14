#!/usr/bin/env bash

if ! [ -x "$(command -v jq)" ]; then
    printf "Error: jq is not installed.\n" >&2
fi
if ! [ -x "$(command -v curl)" ]; then
    printf "Error: curl is not installed.\n" >&2
fi

board="wg"
catalog_url="https://a.4cdn.org/${board}/catalog.json"
threads_url="https://a.4cdn.org/${board}/threads.json"
page_pre="https://a.4cdn.org/${board}/"
thread_pre="https://a.4cdn.org/${board}/thread/"
img_pre="https://i.4cdn.org/${board}/"

tmp_dir="/tmp/paperscraper"
catalog_json="$tmp_dir/catalog.json"
threads_json="$tmp_dir/threads.json"
[ -d "$tmp_dir" ] || mkdir "$tmp_dir"

curl_json(){
    curl -sL "$catalog_url" -o "$catalog_json"
    curl -sL "$threads_url" -o "$threads_json"
}

# TODO Clean up this function 
# TODO Add option to filter for image resolution
curl_thread(){
    thread_dir="$tmp_dir/threads"
    [ -d "$thread_dir" ] || mkdir "$thread_dir" 

    # Use this directory if not set
    [ -z "$download_dir" ] && download_dir="$HOME/Downloads/paperscraper"
    [ -d "$download_dir" ] || mkdir -pv "$download_dir"
    download_dir=$(echo $download_dir | sed 's:/*$::g')

    # Gets thread json data
    url="$thread_pre$thread_number.json"
    json_file="$thread_dir/$thread_number.json"

    # Download the thread's json data
    if [ ! -f "$json_file" ]; then
        curl "$url" -o "$json_file"
    fi

    if [ ! -z $min_width ]; then
        minw=$(jq --arg minw "$min_width" -c '.posts[].w >= ($minw | tonumber)' $json_file)
    fi
    if [ ! -z $max_width ]; then
        maxw=$(jq --arg maxw "$max_width" -c '.posts[].w <= ($maxw | tonumber)' $json_file)
    fi
    if [ ! -z $min_height ]; then
        minh=$(jq --arg minh "$min_height" -c '.posts[].h >= ($minh | tonumber)' $json_file)
    fi
    if [ ! -z $max_height ]; then
        maxh=$(jq --arg maxh "$max_height" -c '.posts[].h <= ($maxh | tonumber)' $json_file)
    fi

    tim=$(jq '.posts[].tim' "$json_file" | sed 's/\s*//g')
    ext=$(jq '.posts[].ext' "$json_file" | sed 's/\"//g')
    w=$(jq '.posts[].w' "$json_file")
    h=$(jq '.posts[].h' "$json_file")

    # Download each file from the list
    while read line
    do
        file_base=$(echo "$line" | cut -d '/' -f 5)
        filename="$download_dir/$file_base"
        echo "$filename"
        [ -f "$filename" ] || curl -# "$line" -o "$filename"
    done <  <(paste <(echo $minw | tr ' ' '\n')\
            <(echo $maxw | tr ' ' '\n')\
            <(echo $minh | tr ' ' '\n')\
            <(echo $maxh | tr ' ' '\n')\
            <(echo "$tim" | tr ' ' '\n')\
            <(echo "$ext" | tr ' ' '\n')\
            <(echo "$w" | tr ' ' '\n')\
            <(echo "$h" | tr ' ' '\n')\
            | sed '/null/d' | sed '/false/d'\
            | cut -f5,6 | sed 's/\s*//g' | sed 's|^|https://i.4cdn.org/'$board'/|')
}

curl_page(){
    [ -f $catalog_json ] || curl_json

    while read line 
    do
        curl_thread $line
    done < <(jq '.['$page_number'].threads[].no' $catalog_json)
}

show_thread_list(){
    if [ ! -f $threads_json ] || [ ! -f $catalog_json ]; then
        curl_json
    fi

    numbers=$(jq '.[].threads[] | .no' $catalog_json)
    subjects=$(jq '.[].threads[].sub' $catalog_json | cut -c -50)
    comments=$(jq '.[].threads[].com' $catalog_json | cut -c -50)
    img_replies=$(jq '.[].threads[].images' $catalog_json)

    result=$(paste <(echo "$numbers") <(echo "$subjects") <(echo "$comments") <(echo "$img_replies") | column -ts $'\t')
    echo "$result"
}

show_usage(){
cat<<USAGE
Usage $0
      -l [show list of threads], 
      -u [update catalog and threads], 
      -d <specify directory for downloaded files>, 
      -p <specify page to download>,
      -t <thread number to download>, 
      -w <minimum width for wallpaper>,
      -h <minimum height for wallpaper>,
      -x <maximum width for wallpaper>,
      -y <maximum height for wallpaper>,
      -h [help]
USAGE
}

# TODO
# Should probably go back to using while [ "$#" -gt 0 ]; do .. and shift
# to get long options and flexibility, but I just wanted to try getopts out
while getopts ":d:w:h:x:y:t:p:ul" opt; do
    case "${opt}" in
        d) declare -g download_dir="${OPTARG}" ;;
        w) declare -ig min_width="${OPTARG}" ;;
        h) declare -ig min_height="${OPTARG}" ;;
        x) declare -ig max_width="${OPTARG}" ;;
        y) declare -ig max_height="${OPTARG}" ;;
        t) declare -ig thread_number="${OPTARG}" ;;
        p) declare -ig page_number="${OPTARG}" ;;
        u) curl_json ;; 
        l) show_thread_list ;; 
        \?) show_usage; exit 1 ;;
        :) echo "Option $OPTARG requires an argument" 1>&2 ;;
    esac
done

[[ $OPTIND == 1 ]] && show_usage; 
shift $((OPTIND-1))

if [ ! -z $thread_number ]; then
    curl_thread "$thread_number"
fi

if [ ! -z $page_number ]; then
    curl_page "$page_number"
fi

