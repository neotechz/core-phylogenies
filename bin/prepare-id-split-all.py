#!/usr/bin/env python3

import pandas as pd
import sys

def main():
    fpath = f"{sys.argv[1]}"
    id = fpath.split("/")[-1].rsplit(".", 2)[0]
    
    if "_" in id:
        id = id.split("_")[0]
    elif "-" in id:
        id = id.split("-")[0]
    else:
        id = id

    print(id)

main()