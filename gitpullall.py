#!/usr/bin/env python 
import os
import sys 
import glob
import shutil
import argparse
import subprocess
import platform


cmd = "cd script/gxlua && git pull"
print(cmd)
assert(os.system(cmd) == 0)

cmd = "cd script/gxlua_chesscard && git pull"
print(cmd)
assert(os.system(cmd) == 0)

cmd = "git pull"
print(cmd)
assert(os.system(cmd) == 0)
