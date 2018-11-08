#!/usr/bin/env python

import os
import time
import os.path
import shutil
import urllib2
import platform
import subprocess

if platform.system() == "Windows":

    def download(url, name):
        print("download %s %s" % (name, url))
        data = urllib2.urlopen(url).read()
        with open(name, "wb") as fp:
            fp.write(data)

    def local_version(name):
        v = subprocess.check_output([name, "-v"])
        print("local version: %s" % v)
        return v

    def remote_version():
        v = urllib2.urlopen("http://git.code4.in/mobilegameserver/unilight-binary/raw/master/version?v=" + time.strftime('%y%m%d%H%M%S')).read()
        print("remote version: %s" % v)
        return v.strip()

    def sync_self():
        assert(os.system("git pull") == 0)

    def sync_gxlua():
        if not os.path.exists("script/gxlua"):
            cmd = "git clone git@git.code4.in:mobilegameserver/gxlua.git script/gxlua"
            print(cmd)
            assert(os.system(cmd) == 0)
        else:
            os.chdir("script/gxlua")
            assert(os.system("git pull origin master") == 0)
            os.chdir("../../")

    def sync_common():
        if not os.path.exists("common"):
            cmd = "git clone git@git.code4.in:mobilegameserver/[TEMPLATE]common.git common"
            print(cmd)
            assert(os.system(cmd) == 0)
        else:
            os.chdir("common")
            assert(os.system("git pull origin master") == 0)
            os.chdir("../")
        
        # table build
        os.chdir("common/table")
        assert(os.system("make.bat continue") == 0)
        os.chdir("../../")

        # table copy
        if os.path.exists("table"):
            os.chdir("table")
            assert(os.system("del /S /Q *.*") == 0)
            os.chdir("../")
        else:
            assert(os.system("md table") == 0)
        assert(os.system("copy /Y common\\table\\*.lua table") == 0)


    if not os.path.exists("unilight.exe") or local_version("unilight.exe").find(remote_version()) == -1:
        download("http://git.code4.in/mobilegameserver/unilight-binary/raw/master/unilight-windows?v=" + time.strftime('%y%m%d%H%M%S'), "unilight.exe")

    sync_self()
    sync_gxlua()
    #sync_common()
