# openwrt-auto

Openwrt action for Ebang EBAZ4205,EBAZ4203... with anti-gfw tools built-in. 

[Releases Download](https://github.com/Elrori/openwrt-auto/releases)(LuCi Chinese). Note: you need to copy system.bit to SDCard FAT partition manually.

To build a stable version of ebaz4205/ebaz4203-openwrt, pls run make-ebaz420x-v4.14.sh manually.

Ubuntu dependency：

```
sudo apt update
sudo apt install build-essential ccache ecj fastjar file g++ gawk \
gettext git java-propose-classpath libelf-dev libncurses5-dev \
libncursesw5-dev libssl-dev python python2.7-dev python3 unzip wget \
python3-distutils python3-setuptools rsync subversion swig time \
xsltproc zlib1g-dev
```

[Related articles](https://blog.csdn.net/z951573431/article/details/123819564)(zh_cn)
