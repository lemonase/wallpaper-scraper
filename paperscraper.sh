#!/usr/bin/env bash

[ ! -x "$(command -v jq)" ] && printf "Error: jq is not installed.\\n" >&2
[ ! -x "$(command -v curl)" ] && printf "Error: curl is not installed.\\n" >&2
[ ! -x "$(command -v cut)" ] && printf "Error: cut is not installed.\\n" >&2
[ ! -x "$(command -v paste)" ] && printf "Error: paste is not installed.\\n" >&2

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
  curl -"$curl_opts"L  "$catalog_url" -o "$catalog_json"
  curl -"$curl_opts"L  "$threads_url" -o "$threads_json"
}

curl_thread(){
  # Use this directory if not set
  [ -z "$download_dir" ] && download_dir="$HOME/Downloads/paperscraper"
  [ -d "$download_dir" ] || mkdir -p "$download_dir"
  download_dir=$(echo $download_dir | sed 's:/*$::g')

  # Gets thread json data
  url="$thread_pre$thread_number.json"
  json_file="$thread_dir/$thread_number.json"

  # Download the thread's json data
  [ ! -f "$json_file" ] && curl -"$curl_opts"L "$url" -o "$json_file"

  # Does the image match width/height requirements
  if [ ! -z "$min_width" ]; then
    minw=$(jq --arg minw "$min_width" -c '.posts[].w >= ($minw | tonumber)' "$json_file")
  fi
  if [ ! -z "$max_width" ]; then
    maxw=$(jq --arg maxw "$max_width" -c '.posts[].w <= ($maxw | tonumber)' "$json_file")
  fi
  if [ ! -z "$min_height" ]; then
    minh=$(jq --arg minh "$min_height" -c '.posts[].h >= ($minh | tonumber)' "$json_file")
  fi
  if [ ! -z "$max_height" ]; then
    maxh=$(jq --arg maxh "$max_height" -c '.posts[].h <= ($maxh | tonumber)' "$json_file")
  fi

  # Get the image data we need
  tim=$(jq '.posts[].tim' "$json_file" | sed 's/\s*//g')
  ext=$(jq '.posts[].ext' "$json_file" | sed 's/\"//g')
  w=$(jq '.posts[].w' "$json_file")
  h=$(jq '.posts[].h' "$json_file")

  [[ "$curl_opts" != 's' ]] && curl_opts='#'

  # Download each file from the list
  while read -r line
  do
    file_base=$(echo "$line" | cut -d '/' -f 5)
    filename="$download_dir/$file_base"
    [[ "$curl_opts" != 's' ]] && echo "$filename"
    [ -f "$filename" ] || curl -"$curl_opts"L "$line" -o "$filename"
  done <  <(paste <(echo "$minw" | tr ' ' '\n')\
          <(echo "$maxw" | tr ' ' '\n')\
          <(echo "$minh" | tr ' ' '\n')\
          <(echo "$maxh" | tr ' ' '\n')\
          <(echo "$tim" | tr ' ' '\n')\
          <(echo "$ext" | tr ' ' '\n')\
          <(echo "$w" | tr ' ' '\n')\
          <(echo "$h" | tr ' ' '\n')\
          | sed '/null/d' | sed '/false/d'\
          | cut -f5,6 | sed 's/\s*//g' | sed 's|^|https://i.4cdn.org/'${board}'/|')
}

curl_page(){
  [ -f $catalog_json ] || curl_json

  while read -r line 
  do
    curl_thread "$line"
  done < <(jq '.['$page_number'].threads[].no' "$catalog_json")
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
Usage: paperscraper.sh [-t thread_number] || [-p page_number] [--options]
  Required arguments (either or)
  -t,	--thread                  Thread number to download
  -p,	--page                    Page number to download

  Optional arguments 
  -b,	--board                   Specify image board (/wg/ by default)
  -d,	--dir, --download-dir     Destination dir for downloads (~/Downloads/paperscraper by default)
  -minw, --min-width              Minimum width for images
  -minh, --min-height             Minimum height for images
  -maxw, --max-width              Maximum width for images
  -maxh, --max-height             Maximum height for images
  -1080, -1080p, --desktop        Minimum resolution of 1920x1080
  -s,	--silent                  Silent mode
  -l,	--list                    Outputs a list of threads
  -u,	--update                  Updates list of threads
  -h, --help                      Show this message
USAGE
}

[ "$#" -eq 0 ] && show_usage
while [ "$#" -gt 0 ]; do
  case "$1" in
    -t|--thread) thread_number="$2"; shift 2;;
    -p|--page) page_number="$2"; shift 2;;
    -b|--board) chosen_board="$2";shift 2;;
    -d|--dir|--download-dir) download_dir="$2"; shift 2;;
    -minw|--min-width) min_width="$2"; shift 2;;
    -minh|--min-height) min_height="$2"; shift 2;;
    -maxw|--max-width) max_width="$2"; shift 2;;
    -maxh|--max-height) max_height="$2"; shift 2;;
    -1080|-1080p|--desktop) min_width=1920; min_height=1080; shift;;
    -s|--silent) silent=true; shift ;;
    -u|--update) json=true; shift;; 
    -l|--list) list=true; shift;; 
    -h|--help) show_usage; exit;;
    -*) echo "Unknown option $1"; show_usage; exit 1;;
    *) echo "Unknown option $1"; show_usage; exit 1;;
  esac
done

main(){
  set_board "$chosen_board"
  if [ ! -z "$silent" ]; then
    declare -g curl_opts="s"
  else
    declare -g curl_opts=""
  fi

  [ ! -z "$json" ] && curl_json
  [ ! -z "$list" ] && show_thread_list
  [ ! -z "$thread_number" ] && curl_thread "$thread_number"
  [ ! -z "$page_number" ] && curl_page "$page_number"
}

main

