#!/usr/bin/env python3
from pathlib import Path
import argparse
import io
import json
import requests


class Catalog():
    def __init__(self, board):
        self.board = board
        self.endpoint = "https://a.4cdn.org/" + self.board + "/catalog.json"
        self.path_string = "data/boards/" + self.board + "/"
        self.file_string = self.path_string + "/catalog.json"
        self.path = Path(self.path_string)
        self.file = Path(self.file_string)

    def download_json(self):
        if not self.path.is_dir():
            self.path.mkdir(parents=True)

        with self.file.open('w') as json_file:
            json_data = json.dumps(requests.get(self.endpoint).json())
            json_file.write(json_data)

    def print_catalog(self):
        self.download_json()

        # the catalog json is just an array of pages
        with self.file.open("r") as cat_file:
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


class Thread():
    def __init__(self, board, id):
        self.board = board
        self.id = id
        self.thread_pre = "https://a.4cdn.org/" + self.board + "/thread/"
        self.filename = str(id) + ".json"

        self.endpoint = self.thread_pre + self.filename

        self.path_string = "data/threads/"
        self.path = Path(self.path_string)

        self.file_string = self.path_string + self.filename
        self.file = Path(self.file_string)

        self.images_endpoint = "https://i.4cdn.org/" + self.board + "/"
        self.images_path = Path("data/images/" + str(id))

    def download_json(self):
        if not self.path.is_dir():
            self.path.mkdir(parents=True)
        if not self.images_path.is_dir():
            self.images_path.mkdir(parents=True)

        with self.file.open('w') as json_file:
            json_data = json.dumps(requests.get(self.endpoint).json())
            json_file.write(json_data)

    def download_images(self):
        self.download_json()

        with self.file.open('r', encoding="utf-8") as json_file:
            data = json.load(json_file)
            posts = data["posts"]

            # iterate through posts in the thread
            for post_num in range(len(posts)):
                post = posts[post_num]
                try:
                    # images have these attributes
                    tim = post["tim"]
                    ext = post["ext"]
                    width = post["w"]
                    height = post["h"]
                    image_filename = str(tim) + str(ext)

                    # request image variables
                    image_url = self.images_endpoint + image_filename
                    image_res = requests.get(image_url)
                    image_content = image_res.content

                    # local image variables
                    image_string = str(self.images_path.absolute()) + \
                        "\\" + image_filename
                    image_file = Path(image_string)

                    # write to disk
                    print("Downloading", image_url, "to", image_string)
                    with image_file.open("wb") as im:
                        im.write(image_content)

                except KeyError:
                    # Not all replies are images
                    pass


def get_arguments():
    parser = argparse.ArgumentParser(
        description="Specify board, thread and image criteria")

    parser.add_argument('-b', '--board', nargs=1,
                        type=str, required=True, default='wg',
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

    return parser.parse_args()


def process_arguments(args):
    if args.board:
        board = "".join(args.board)
        catalog = Catalog(board)
        catalog.download_json()

        if args.thread:
            for thread_id in args.thread:
                thread = Thread(board, thread_id)
                thread.download_images()

        if args.print_catalog:
            catalog.print_catalog()

    # TODO implement image size filtering


def main():
    process_arguments(get_arguments())


if __name__ == '__main__':
    main()
