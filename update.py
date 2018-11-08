#!/usr/bin/env python

import os
import sys
import glob
import shutil
import argparse
import subprocess
import platform

cwd = os.path.dirname(os.path.abspath(__file__))
gxlua= "script/gxlua"
if not os.path.exists(gxlua):
    cmd = "cd script && git clone git@git.code4.in:mobilegameserver/gxlua.git"
    print(cmd)
    os.system(cmd)

gxlua_chesscard= "script/gxlua_chesscard"
if not os.path.exists(gxlua_chesscard):
    cmd = "cd script && git clone git@git.code4.in:h5doc/gxlua_chesscard.git"
    print(cmd)
    os.system(cmd)

def update():
    cmd = "cd script/gxlua && git pull origin master && cd .."
    print(cmd)
    assert(os.system(cmd) == 0)
    cmd = "cd script/gxlua_chesscard && git pull origin master && cd .."
    print(cmd)
    assert(os.system(cmd) == 0)
    cmd = "git pull"
    print(cmd)
    assert(os.system(cmd) == 0)

update()
