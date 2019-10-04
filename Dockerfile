FROM uwgac/topmed-master

MAINTAINER Kenny Westerman <kewesterman@mgh.harvard.edu>

RUN curl -O https://www.well.ox.ac.uk/~gav/resources/qctool_v2.0.1-Ubuntu16.04-x86_64.tgz \
	&& tar zxvf qctool_v2.0.1-Ubuntu16.04-x86_64.tgz
ENV QCTOOL=/qctool_v2.0.1-Ubuntu16.04-x86_64/qctool

#RUN curl -O https://bitbucket.org/gavinband/qctool/get/c9c3c313141e.zip \
#	&& unzip c9c3c313141e.zip \
#	&& cd gavinband-qctool-c9c3c313141e \
#	&& python2.7 ./waf-1.5.18 configure \
#	&& python2.7 ./waf-1.5.18

RUN apt-get update && apt-get install -y cmake \
	&& pip install cget \
	&& git clone https://github.com/Santy-8128/DosageConvertor \
	&& cd DosageConvertor \
	&& ./install.sh
ENV DosageConvertor=/DosageConvertor/release-build/DosageConvertor

#RUN curl -Ok https://watson.hgen.pitt.edu/pub/mega2/mega2_v6.0.0_src.tar.gz \
#	&& tar zxvf mega2_v6.0.0_src.tar.gz \
#	&& R -e 'BiocManager::install("genetics")' \
#	&& R -e 'BiocManager::install("nplplot")' \
#	&& cd mega2_v6.0.0_src \
#	&& ./install.sh

COPY mmap.2018_04_07_13_28.intel /
ENV MMAP=/mmap.2018_04_07_13_28.intel
