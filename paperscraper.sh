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

threadfile="$tmp_dir/threads.txt"
viewfile="$tmp_dir/catalog.txt"
dlfile="$tmp_dir/dl.txt"

if [ ! -d "$tmp_dir" ]; then
    mkdir "$tmp_dir"
fi

curl_json(){
    curl -sL "$catalog_url" -o "$catalog_json"
    curl -sL "$threads_url" -o "$threads_json"
}

# TODO Clean up this function 
# TODO Add option to filter for image resolution
curl_thread(){
    thread_dir="$tmp_dir/threads"

    [ -d "$thread_dir" ] || mkdir "$thread_dir" 
    # Gets thread json data
    for arg in $@; do
        url="$thread_pre$arg.json"
        json_file="$thread_dir/$arg.json"

        # Download the thread's json data
        curl "$url" -o "$json_file"

        # Extract data relevant to images into a file
        paste <(jq '.posts[].tim' "$json_file" | sed 's/\s*//g') \
              <(jq '.posts[].ext' "$json_file" | sed 's/\"//g') \
              | sed '/null/d' | tr -d '\t' > "$dlfile"
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

curl_page(){
    for arg in $@; do
        if [ ! -f $catalog_json ]; then
            curl_json
        fi

        (jq '.['$arg'].threads[].no' $catalog_json) > threadfile

        while read line 
        do
            curl_thread $line
        done < threadfile

    done
}

show_thread_list(){
    if [ ! -f $threads_json ] || [ ! -f $catalog_json ]; then
        curl_json
    fi

    numbers=$(jq '.[].threads[] | .no' $catalog_json)
    subjects=$(jq '.[].threads[].sub' $catalog_json)
    comments=$(jq '.[].threads[].com' $catalog_json)
    img_replies=$(jq '.[].threads[].images' $catalog_json)

    paste <(jq '.[] | .threads[] | .no' $catalog_json) \
          <(jq '.[].threads[].sub' $catalog_json | cut -c -50) \
          <(jq '.[].threads[].com' $catalog_json | cut -c -50) \
          <(jq '.[].threads[].images' $catalog_json) > $viewfile
    sed -i 's/\"//g' $viewfile
    column -ts $'\t' $viewfile
}

show_usage(){
cat<<USAGE
Usage $0
      -l (show list of threads), 
      -u (update catalog and threads), 
      -d <specify directory for files>, 
      -p <specify page to download>,
      -t <thread number to download>, 
      -h [help]
USAGE
}

# TODO
# Should probably go back to using while [ "$#" -gt 0 ]; do .. and shift
# to get long options and flexibility ,but I just wanted to try getopts out
while getopts ":p:t:d:ulh" opt; do
    case ${opt} in
        h) show_usage ;;
        u) curl_json ;; # update
        l) show_thread_list ;; # thread list
        t) curl_thread $OPTARG ;;
        p) curl_page $OPTARG ;;
        d) download_dir=$OPTARG ;;
        \?) show_usage; exit 1 ;;
        :) echo "Option $OPTARG requires an argument" 1>&2 ;;
    esac
done


[[ $OPTIND == 1 ]] && show_usage; 
shift $((OPTIND-1))

