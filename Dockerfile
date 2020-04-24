FROM ubuntu:18.04

MAINTAINER Kenny Westerman <kewesterman@mgh.harvard.edu>

RUN apt-get update && apt-get -y install wget libatlas-base-dev && \
	wget https://www.well.ox.ac.uk/~gav/resources/qctool_v2.0.1-Ubuntu16.04-x86_64.tgz && \
	tar zxvf qctool_v2.0.1-Ubuntu16.04-x86_64.tgz
ENV QCTOOL=/qctool_v2.0.1-Ubuntu16.04-x86_64/qctool

RUN apt-get update && apt-get install -y cmake python python-pip git libz-dev && \
	pip install cget && \
	git clone https://github.com/Santy-8128/DosageConvertor && \
	cd DosageConvertor && \
	./install.sh
ENV DosageConvertor=/DosageConvertor/release-build/DosageConvertor

COPY opt/mmap.2018_04_07_13_28.intel /
ENV MMAP=/mmap.2018_04_07_13_28.intel

RUN apt-get update && apt-get install unzip
RUN wget http://s3.amazonaws.com/plink2-assets/alpha2/plink2_linux_x86_64.zip \
	&& unzip plink2_linux_x86_64.zip
ENV PLINK2=/plink2
