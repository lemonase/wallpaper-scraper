#!/usr/bin/env python3
from pathlib import Path
import argparse
import io
import json
import requests


class Catalog():
    """
    Holds all the data and regarding catalogs
    """

    def __init__(self, board):
        # required
        self.board = board
        self.endpoint = "https://a.4cdn.org/" + self.board + "/catalog.json"

        # files
        self.path_string = "data/boards/" + self.board + "/"
        self.file_string = self.path_string + "/catalog.json"
        self.path = Path(self.path_string)
        self.file = Path(self.file_string)

    def download_json(self):
        # make the path dir if it doesn't exist
        if not self.path.is_dir():
            self.path.mkdir(parents=True)

        # open a file, send a request for the json and write to the file
        with self.file.open('w') as json_file:
            try:
                json_data = json.dumps(requests.get(self.endpoint).json())
                json_file.write(json_data)
            except json.JSONDecodeError as error:
                print("Error fetching json: ", error)

    def print_catalog(self):
        # first download the json for the catalog
        self.download_json()

        # open the saved json file and load the json
        with self.file.open("r") as catalog_file:
            pages = json.load(catalog_file)

            # the catalog json is just a list of pages
            # so we begin by iterating through the pages
            for page_num in range(len(pages)):
                # get each page
                page = pages[page_num]

                # get the threads on each page
                threads = page["threads"]

                # print the page heading
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
    """
    Holds data and methods regarding threads
    """

    def __init__(self, board, id):
        # required
        self.board = board
        self.id = id
        self.thread_prefix = "https://a.4cdn.org/" + self.board + "/thread/"

        # endpoints
        self.endpoint = self.thread_prefix + self.filename
        self.images_endpoint = "https://i.4cdn.org/" + self.board + "/"

        # paths
        self.path_string = "data/threads/"
        self.path = Path(self.path_string)
        self.images_path = Path("data/images/" + str(id))

        # file
        self.filename = str(id) + ".json"
        self.file_string = self.path_string + self.filename
        self.file = Path(self.file_string)

    def download_json(self):
        # create directories for threads and images if they don't exist
        if not self.path.is_dir():
            self.path.mkdir(parents=True)
        if not self.images_path.is_dir():
            self.images_path.mkdir(parents=True)

        # open file, send request and write data to a file
        with self.file.open('w') as json_file:
            try:
                json_data = json.dumps(requests.get(self.endpoint).json())
                json_file.write(json_data)
            except json.JSONDecodeError as error:
                print("Error fetching json: ", error)


    def download_images(self):
        # download the json for the thread
        self.download_json()

        # open the json file
        with self.file.open('r', encoding="utf-8") as json_file:
            # load into data
            data = json.load(json_file)

            # grab the posts from
            posts = data["posts"]

            # iterate through posts in the thread
            for post_num in range(len(posts)):
                # grab the current post
                post = posts[post_num]

                # try to get these attributes. may throw an error because not
                # all posts or replies have images attached
                try:
                    # images should have these attributes
                    tim = post["tim"]
                    ext = post["ext"]
                    width = post["w"]
                    height = post["h"]

                    # filename consists of "tim.ext"
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
                    with image_file.open("wb") as im_file:
                        im_file.write(image_content)

                except KeyError:
                    pass


def get_arguments():
    # argparse function that takes care of various arguments and options

    parser = argparse.ArgumentParser(
        description="Specify board, thread and image criteria")

    parser.add_argument('-b', '--board', nargs=1,
                        type=str, required=True, default='wg',
                        help="Specify a board (ex: wg)")

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
    # take action from arguments

    # a board must be specified
    if args.board:
        # convert board to a string
        board = "".join(args.board)

        # create catalog object for the board
        catalog = Catalog(board)

        # request the json
        catalog.download_json()

        if args.thread:
            for thread_id in args.thread:
                thread = Thread(board, thread_id)
                thread.download_images()

        if args.print_catalog:
            catalog.print_catalog()
    else:
        print("Error: No board specified")

    # TODO implement image size filtering


def main():
    args = get_arguments()
    process_arguments(args)


if __name__ == '__main__':
    main()
