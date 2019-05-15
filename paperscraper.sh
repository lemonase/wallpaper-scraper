#!/usr/bin/env bash

if ! [ -x "$(command -v jq)" ]; then
  printf "Error: jq is not installed.\n" >&2
fi
if ! [ -x "$(command -v curl)" ]; then
  printf "Error: curl is not installed.\n" >&2
fi

set_board(){
  if [ ! -z "$1" ]; then
    declare -g board="$1"
  else
    declare -g board="wg" 
  fi

  declare -g catalog_url="https://a.4cdn.org/${board}/catalog.json"
  declare -g threads_url="https://a.4cdn.org/${board}/threads.json"
  declare -g page_pre="https://a.4cdn.org/${board}/"
  declare -g thread_pre="https://a.4cdn.org/${board}/thread/"
  declare -g img_pre="https://i.4cdn.org/${board}/"

  declare -g tmp_dir="/tmp/paperscraper"
  [ -d "$tmp_dir" ] || mkdir "$tmp_dir"
  declare -g catalog_json="${tmp_dir}/${board}/catalog.json"
  declare -g threads_json="${tmp_dir}/${board}/threads.json"

  declare -g thread_dir="${tmp_dir}/${board}/threads"
  [ -d "$thread_dir" ] || mkdir -p "$thread_dir" 
}

curl_json(){
  curl -L "$catalog_url" -o "$catalog_json"
  curl -L "$threads_url" -o "$threads_json"
}

# TODO Clean up this function 
# TODO Add option to filter for image resolution
curl_thread(){
  # Use this directory if not set
  [ -z "$download_dir" ] && download_dir="$HOME/Downloads/paperscraper"
  [ -d "$download_dir" ] || mkdir -p "$download_dir"
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
          | cut -f5,6 | sed 's/\s*//g' | sed 's|^|https://i.4cdn.org/'${board}'/|')
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
  echo $threads_json

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
      -l <show list of threads> 
      -u <update catalog and threads> 
      -p [arg]: <specify page to download>
      -t [arg]: <thread number to download> 
      -d [optional arg]: <specify directory for downloaded files (defaults to ~/Downloads/paperscraper)> 
      -b [optional arg]: <specify image board (defaults to /wg/)>
      -w [optional arg]: <minimum width for image>
      -h [optional arg]: <minimum height for image>
      -x [optional arg]: <maximum width for image>
      -y [optional arg]: <maximum height for image>
      -h [help]
USAGE
}

# TODO
# Should probably go back to using while [ "$#" -gt 0 ]; do .. and shift
# to get long options and flexibility, but I just wanted to try getopts out
while getopts ":d:w:h:x:y:t:p:b:ul" opt; do
  case "${opt}" in
    d) download_dir="${OPTARG}" ;;
    w) min_width="${OPTARG}" ;;
    h) min_height="${OPTARG}" ;;
    x) max_width="${OPTARG}" ;;
    y) max_height="${OPTARG}" ;;
    t) thread_number="${OPTARG}" ;;
    p) page_number="${OPTARG}" ;;
    b) bd="${OPTARG}" ;;
    u) json=true ;; 
    l) list=true ;; 
    \?) show_usage; exit 1 ;;
    :) echo "Option $OPTARG requires an argument" 1>&2 ;;
  esac
done

[[ $OPTIND == 1 ]] && show_usage; 
shift $((OPTIND-1))

main(){
  set_board "$bd"
  [ ! -z "$json" ] && curl_json
  [ ! -z "$list" ] && show_thread_list
  [ ! -z $thread_number ] && curl_thread "$thread_number"
  [ ! -z $page_number ] && curl_page "$page_number"
}

main

