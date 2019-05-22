# wallpaper-scraper
A small script to download all images from a thread/page
for any given board on 4chan.org (default board is /wg/)

## Requirements
**curl** and **jq** and paste

```
Usage: paperscraper.sh
      -l <show list of threads> 
      -u <update catalog and threads> 
      -s <silent mode>
      -p [page number]: <specify page to download>
      -t [thread number]: <thread number to download> 
      -d [path/to/downloads]: <specify directory for downloaded files (defaults to ~/Downloads/paperscraper)> 
      -b [board]: <specify image board (defaults to /wg/)>
      -w [minimum width]: <minimum width for image>
      -h [minimum height]: <minimum height for image>
      -x [maximum width]: <maximum width for image>
      -y [maximum height]: <maximum height for image>
```

This script could be rewritten in Python or Go to get
some nice parallel downloads to make it much faster.

If there are any bugs, please report them here or send a PR.
