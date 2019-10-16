#!/usr/bin/env python3
import argparse
import io
import json
from pathlib import Path
import requests


class Endpoints():
    def __init__(self, board):
        self.board = board
        self.api_endpoint = "https://a.4cdn.org/" + self.board + "/"
        self.image_endpoint = "https://i.4cdn.org/" + self.board + "/"
        self.catalog_json_endpoint = api_endpoint + "catalog.json"
        self.thread_json_endpoint = api_endpoint + "threads.json"
        self.thread_endpoint = api_endpoint + "thread/"

    def set_board(self, board):
        self.board = board


class Paths():
    def __init__(self):
        # declare path variables
        self.thread_dir = Path("data/threads/")
        self.images_dir = Path("data/images/")
        self.catalog_json_file = Path("data/catalog.json")
        self.threads_json_file = Path("data/threads.json")

    def make_dirs(self):
        if not self.thread_dir.is_dir():
            self.thread_dir.mkdir(parents=True)

        if not self.images_dir.is_dir():
            self.images_dir.mkdir(parents=True)


class Catalog():
    def __init__(self):
        pass


class Thread():
    def __init__(self):
        pass

# TODO restructure the rest of the functions into classes


def download_catalog_json():
    with catalog_json_file.open("w") as json_file:
        catalog_json = json.dumps(
            requests.get(catalog_json_endpoint).json())
        json_file.write(catalog_json)

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


def print_catalog(board):
    # download catalog json
    download_catalog_json()

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


def process_arguments():
    parser = argparse.ArgumentParser(
        description="Specify board, thread and image criteria")

    parser.add_argument('-b', '--board', nargs=1,
                        type=str, required=False, default='wg',
                        help="Specify a board")

    parser.add_argument('-p', '--print-catalog', action='store_true',
                        help="Print out the catalog for a board")

    parser.add_argument('-t', '--thread', nargs=1, type=int,
                        required=False, help="Specify a thread number")

    parser.add_argument('-minw', '--min-width', nargs=1, type=int,
                        help="Specify the minimum width of the image")

    parser.add_argument('-maxw', '--max-width', nargs=1, type=int,
                        help="Specify the maximum width of the image")

    parser.add_argument('-minh', '--min-height', nargs=1, type=int,
                        help="Specify the minimum height of the image")

    parser.add_argument('-maxh', '--max-height', nargs=1, type=int,
                        help="Specify the maximum height of the image")

    args = parser.parse_args()

    if args.board:
        set_endpoints(args.board)

    if args.print_catalog:
        print_catalog(args.board)

    if args.thread:
        download_thread_images(args.thread)

    print(board)


def main():
    process_arguments()
    # print_catalog()
    # download_thread_images(7454599)


if __name__ == '__main__':
    main()
