from pathlib import Path
import json
import requests
from PIL import Image

# declare api variables
board = "wg"
api_endpoint = "https://a.4cdn.org/" + board + "/"
catalog_json_endpoint = api_endpoint + "catalog.json"
thread_json_endpoint = api_endpoint + "threads.json"
thread_endpoint = api_endpoint + "thread/"
image_endpoint = "https://i.4cdn.org/" + board + "/"


# declare path variables
data_dir = Path("data")
thread_dir = Path("data/threads/")
catalog_json_file = Path("data/catalog.json")
threads_json_file = Path("data/threads.json")
images_dir = Path("data/images")


def make_dirs():
    # create data_dir
    if not data_dir.is_dir():
        data_dir.mkdir()

    # create thread directory
    if not thread_dir.is_dir():
        thread_dir.mkdir()

    # create images dir
    if not images_dir.is_dir():
        images_dir.mkdir()


def download_catalog_json():
    # open and download catalog and json files if they don't exist
    if not catalog_json_file.is_file():
        with catalog_json_file.open("w") as json_file:
            catalog_json = json.dumps(
                requests.get(catalog_json_endpoint).json())
            json_file.write(catalog_json)
    if not threads_json_file.is_file():
        with threads_json_file.open("w") as json_file:
            threads_json = json.dumps(
                requests.get(thread_json_endpoint).json())
            json_file.write(threads_json)


def get_thread_string(thread_number):
    return "data/threads/" + str(thread_number) + ".json"


def get_thread_file(thread_number):
    return Path(get_thread_string(thread_number))


def get_thread_url(thread_number):
    return thread_endpoint + str(thread_number) + ".json"


def download_thread_json(thread_number):
    thread_file = get_thread_file(thread_number)
    thread_url = get_thread_url(thread_number)

    # create file if it doesn't exist
    if not thread_file.is_file():
        with thread_file.open("w") as thread_file:
            # send request and turn into serialized json
            thread_json = json.dumps(requests.get(thread_url).json())
            # write to a file
            thread_file.write(thread_json)


def download_images(thread_number):
    thread_file = get_thread_file(thread_number)

    # download the thread json if not already
    if not thread_file.is_file():
        download_thread_json(thread_number)

    # TODO implement the rest of this


def print_catalog():
    # open catalog json file. it is basically an array
    # of the pages that are shown on 4ch
    with catalog_json_file.open("r") as cf:
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
                    num = thread["no"]
                    title = thread["com"]
                    print(num, "  ", title)
                except:
                    print("No title")


def main():
    make_dirs()
    download_catalog_json()
    # print_catalog()


main()
