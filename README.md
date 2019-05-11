# wallpaper-scraper
A small script to download wallpapers from threads on 4chan.org/wg/

## Requirements
**curl** and **jq**

```
Usage: paperscraper.sh
      -l (show list of threads), 
      -u (update catalog and threads), 
      -d <specify directory for files>, 
      -t <thread number to download>, 
      -h [help]
```

## Features to add

- [] Option to download by page
- [] Add filter for image resolution (width and height)

This script could be rewritten in Python or Go to get
some nice parallel downloads to make it much faster.