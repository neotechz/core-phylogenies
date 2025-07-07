#!/usr/bin/env python3

import pandas as pd
import sys

def main():
    fpath = f"{sys.argv[1]}"
    id = fpath.split("/")[-1].rsplit(".", 2)[0]
    
    print(id)

main()