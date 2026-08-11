#!/usr/bin/env python3

import argparse


def remove_data(data, remove_head, remove_tail):
    length = len(data)

    if remove_head + remove_tail >= length:
        raise ValueError("remove size exceeds image size")

    end = length - remove_tail if remove_tail else length

    return data[remove_head:end]


def main():
    parser = argparse.ArgumentParser(
        description="Remove head/tail data from binary image"
    )

    parser.add_argument(
        "input",
        help="input bin file"
    )

    parser.add_argument(
        "output",
        help="output bin file"
    )

    parser.add_argument(
        "--head",
        type=lambda x: int(x, 0),
        default=0,
        help="remove head bytes (hex allowed, e.g. 0xc0)"
    )

    parser.add_argument(
        "--tail",
        type=lambda x: int(x, 0),
        default=0,
        help="remove tail bytes (hex allowed, e.g. 0x100)"
    )

    args = parser.parse_args()

    with open(args.input, "rb") as f:
        data = f.read()

    new_image = remove_data(
        data,
        args.head,
        args.tail
    )

    with open(args.output, "wb") as f:
        f.write(new_image)

    print("Input :", args.input)
    print("Size  :", len(data), "bytes")
    print("Remove head:", hex(args.head))
    print("Remove tail:", hex(args.tail))
    print("Output:", args.output)
    print("Size  :", len(new_image), "bytes")


if __name__ == "__main__":
    main()