# wallpaper-scraper
A small script to download wallpapers from threads on 4chan.org/wg/

## Requirements
**curl** and **jq**

```
Usage: paperscraper.sh
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
```

This script could be rewritten in Python or Go to get
some nice parallel downloads to make it much faster.

If there are any bugs, please report them here or send a PR.
