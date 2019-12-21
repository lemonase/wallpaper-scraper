# wallpaper-scraper

A small bash script to download all images from a thread/page
on any given board on 4chan.org (default board is /wg/)

## Requirements

You will need:
**curl**, **jq**, **cut** and **paste**

```man
Usage: paperscraper.sh [-t thread_number] || [-p page_number] [--options]
  Required arguments (either or)
  -t,--thread                  Thread number to download
  -p,--page                    Page number to download

  Optional arguments
  -b,--board                   Specify image board (/wg/ by default)
  -d,--dir, --download-dir     Destination dir for downloads (~/Downloads/paperscraper by default)
  -minw, --min-width              Minimum width for images
  -minh, --min-height             Minimum height for images
  -maxw, --max-width              Maximum width for images
  -maxh, --max-height             Maximum height for images
  -1080, -1080p, --desktop        Minimum resolution of 1920x1080
  -s,--silent                  Silent mode
  -l,--list                    Outputs a list of threads
  -u,--update                  Updates list of threads
  -h,   --help                    Show this message
```

If there are any bugs, please report them here or send a PR.
