import io
import json
from pathlib import Path
import requests

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
images_dir = Path("data/images/")


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


def download_thread_images(thread_number):
    thread_file = get_thread_file(thread_number)

    # download the thread json if not already
    if not thread_file.is_file():
        download_thread_json(thread_number)

    # read saved json for the thread
    with thread_file.open("r", encoding="utf-8") as thread:
        json_data = json.load(thread)
        posts = json_data["posts"]

        # iterate through posts in the thread
        for post_num in range(len(posts)):
            post = posts[post_num]
            try:
                # images have these attributes
                tim = post["tim"]
                ext = post["ext"]
                width = post["w"]
                height = post["h"]

                # request image variables
                image_url = image_endpoint + str(tim) + str(ext)
                image_res = requests.get(image_url)
                image_content = image_res.content

                # local image variables
                image_string = str(images_dir.absolute()) + \
                    "\\" + str(tim) + str(ext)
                image_file = Path(image_string)

                # write to disk
                print("Downloading to", image_string)
                with image_file.open("wb") as im:
                    im.write(image_content)

            except KeyError:
                # Not all replies are images
                pass


def print_catalog():
    # the catalog json is just an array of pages
    with catalog_json_file.open("r") as cat_file:
        pages = json.load(cat_file)

        # iterate through the pages
        for page_num in range(len(pages)):
            # get page and threads from that page
            page = pages[page_num]
            threads = page["threads"]
            print("*** PAGE ", page_num + 1, "***")

            # iterate through the threads on each page
            for thread_num in range(len(threads)):
                # get each thread
                thread = threads[thread_num]

                # print the thread number
                num = thread["no"]
                print("---", "Thread:", num, "---")

                # not all threads have a subject or comment
                try:
                    subject = thread["sub"]
                    comment = thread["com"]

                    print("Sub:", subject)
                    print("Comment:", comment)
                except KeyError:
                    print("N/A")


# TODO allow arguments like width, height, and location

def main():
    make_dirs()
    print_catalog()
    # download_thread_images(7454599)


main()
