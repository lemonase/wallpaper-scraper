import json
from pathlib import Path
import pprint
import requests

# declare api variables
board = "wg"
api_endpoint = "https://a.4cdn.org/" + board + "/"
catalog_endpoint = api_endpoint + "catalog.json"
thread_endpoint = api_endpoint + "threads.json"

# declare path variables
data_dir = Path("data")
catalog_file = Path("data/catalog.json")


def download_json():
    # make data dir if no dir
    if not data_dir.is_dir():
        data_dir.mkdir()

    # open file to write if there is no file
    if not catalog_file.is_file():
        with catalog_file.open("w") as cat_file:
            # send requests for catalog json
            catalog_json = json.dumps(requests.get(catalog_endpoint).json())
            # write catalog file
            cat_file.write(catalog_json)


def get_threads():
    pass


def get_page():
    pass


def get_img():
    pass


def print_catalog():
    # open catalog json file. it is basically an array
    # of the pages that are shown on 4ch
    with catalog_file.open("r") as cf:
        pages = json.load(cf)
        # iterate through the pages
        for page_num in range(len(pages)):
            page = pages[page_num]
            threads = page["threads"]
            print("--- PAGE ", page_num + 1, "---")
            # iterate through the threads on each page
            for thread_num in range(len(threads)):
                thread = threads[thread_num]
                # not all threads have a title
                # hence the try block
                try:
                    title = thread["com"]
                    print("  ", title)
                except:
                    print("   No title")


def main():
    download_json()
    print_catalog()


main()
