# wallpaper-scraper
A small script to download all images from a thread/page
for any given board on 4chan.org (default board is /wg/)

## Requirements
**curl** and **jq** and paste

```
Usage: paperscraper.sh
      -l <show list of threads> 
      -u <update catalog and threads> 
      -p [arg]: <specify page to download>
      -t [arg]: <thread number to download> 
      -d [optional arg]: <specify directory for downloaded files (defaults to ~/Downloads/paperscraper)> 
      -b [optional arg]: <specify image board (defaults to /wg/)>
      -s [optional arg]: <do not output filenames and progress>
      -w [optional arg]: <minimum width for image>
      -h [optional arg]: <minimum height for image>
      -x [optional arg]: <maximum width for image>
      -y [optional arg]: <maximum height for image>
      -h [help]
```

This script could be rewritten in Python or Go to get
some nice parallel downloads to make it much faster.

If there are any bugs, please report them here or send a PR.
