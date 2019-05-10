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
thread_pre="https://a.4cdn.org/${board}/thread/"
img_pre="https://i.4cdn.org/${board}/"

tmp_dir="/tmp/paperscraper"
catalog_file="$tmp_dir/catalog.json"
threads_file="$tmp_dir/threads.json"
viewfile="$tmp_dir/catalog.txt"
dlfile="$tmp_dir/dl.txt"

if [ ! -d "$tmp_dir" ]; then
    mkdir "$tmp_dir"
fi

curl_json(){
    curl -sL "$catalog_url" -o "$catalog_file"
    curl -sL "$threads_url" -o "$threads_file"
}

# TODO Clean up this function 
# TODO Add option to filter for image resolution
curl_thread(){
    thread_dir="$tmp_dir/threads"

    # Download the thread.json file to parse
    [ -d "$thread_dir" ] || mkdir "$thread_dir" 
    for arg in $@; do
        url="$thread_pre$arg.json"
        filename="$thread_dir/$arg.json"

        curl "$url" -o "$filename"
        paste <(jq '.posts[].tim' "$filename" | sed 's/\s*//g') <(jq '.posts[].ext' "$filename" | sed 's/\"//g') | sed '/null/d' | tr -d '\t' > "$dlfile"
        sed -i 's|^|https://i.4cdn.org/'$board'/|' "$dlfile"
    done

    # Use this directory if not set
    if [ -z "$download_dir" ]; then
        download_dir="$HOME/Downloads/paperscraper"
    fi
    # If download directory does not exist, make it
    [ -d "$download_dir" ] || mkdir -p "$download_dir"

    
    # Download each file from the list
    while read line
    do
        file_base=$(echo "$line" | cut -d '/' -f 5)
        echo "$download_dir/$file_base"
        curl -# "$line" -o "$download_dir/$file_base"
    done < "$dlfile"
}

show_thread_list(){
    if [ ! -f $threads_file ] || [ ! -f $catalog_file ]; then
        curl_json
    fi

    numbers=$(jq '.[].threads[] | .no' $catalog_file)
    subjects=$(jq '.[].threads[].sub' $catalog_file)
    comments=$(jq '.[].threads[].com' $catalog_file)
    img_replies=$(jq '.[].threads[].images' $catalog_file)

    paste <(jq '.[].threads[] | .no' $catalog_file) <(jq '.[].threads[].sub' $catalog_file | cut -c -50) <(jq '.[].threads[].com' $catalog_file | cut -c -50) <(jq '.[].threads[].images' $catalog_file) > $viewfile 
    sed -i 's/\"//g' $viewfile
    column -ts $'\t' $viewfile
}

show_usage(){
cat<<USAGE
Usage $0
      -l (show list of threads), 
      -u (update catalog and threads), 
      -d <specify directory for files>, 
      -t <thread number to download>, 
      -h [help]
USAGE
}

# TODO
# Should probably go back to using while [ "$#" -gt 0 ]; do .. and shift
# to get long options and flexibility ,but I just wanted to try getopts out
while getopts ":t:d:ulh" opt; do
    case ${opt} in
        h) show_usage ;;
        u) curl_json ;; # update
        l) show_thread_list ;; # thread list
        t) curl_thread $OPTARG ;;
        d) download_dir=$OPTARG ;;
        \?) show_usage; exit 1 ;;
        :) echo "Option $OPTARG requires an argument" 1>&2 ;;
    esac
done


[[ $OPTIND == 1 ]] && show_usage; 
shift $((OPTIND-1))

