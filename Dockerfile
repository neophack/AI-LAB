FROM nvcr.io/nvidia/tensorrt:19.02-py3
LABEL maintainer "neoneone  <neoneone@163.com>"

#  https://www.somelatest.com/

ARG DEBIAN_FRONTEND=noninteractive


ENV TZ=Europe/Minsk
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
        cat /usr/local/cuda/version.txt &&\
	cat /usr/include/cudnn.h | grep CUDNN_MAJOR -A 2 &&\
	dpkg -l | grep TensorRT &&\
	echo $(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())")

RUN apt-get -qq update && apt-get install apt-transport-https 
##---------------install prerequisites---------------
RUN echo "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial main">>/etc/apt/sources.list \
    && echo "deb-src http://apt.llvm.org/xenial/ llvm-toolchain-xenial main">>/etc/apt/sources.list 

RUN bash -c "wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key| apt-key add -" 
RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends llvm-8-dev

RUN alias llvm-config="llvm-config-8" && ln -s /usr/bin/llvm-config-8 /usr/bin/llvm-config
ENV LLVM_CONFIG="/usr/bin/llvm-config-8"

RUN apt-get -qq update && apt-get -qq install -y --no-install-recommends \
	protobuf-compiler \
	geany \
	python3 \
	python3-tk \
	python3-pip \
	python3-dev \
	python3-setuptools \
	eog \
	gedit \
	build-essential \
	ssh \
	ca-certificates \
	curl \
	git \
	wget \
	unzip \
	yasm \
	pkg-config \
	libswscale-dev \
	libtbb2 \
	libtbb-dev \
	libjpeg-dev \
	libgflags-dev \
	libgoogle-glog-dev \
	libprotobuf-dev \
	liblmdb-dev \
	libpng-dev \
	libtiff-dev \
	libavformat-dev \
	libpq-dev \
	libgtk2.0-dev \
	libhdf5-dev \
	libcurl4-openssl-dev\
	libprotoc-dev \
	swig\
	qt5-default \
	libboost-all-dev \
	libboost-dev \
	xdg-utils \
	snapd \
	rsync \
	&& rm -rf /var/lib/apt/lists/*



RUN cd /usr/local/bin &&\
	ln -s /usr/bin/python3 python


#---------------Install pip package---------------
RUN cd /usr/local/src \
	&& wget -q  https://bootstrap.pypa.io/3.5/get-pip.py \
	&& python3 get-pip.py \
	&& pip3 install --upgrade pip \
	&& rm -f get-pip.py \
	&& python3 -m pip --version\
	&& pip install --user --upgrade pip

RUN pip3 install --no-cache-dir --upgrade pip

#---------------Install camke with SSL-------------
WORKDIR /
ENV CMAKE_VERSION="3.15.5"
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz && \
        tar zxf cmake-${CMAKE_VERSION}.tar.gz && \
        rm -rf cmake-${CMAKE_VERSION}.tar.gz && \
        cd cmake-${CMAKE_VERSION} && \
        ./bootstrap --system-curl && \
        make -j8 && make install && \
        rm -rf /cmake-${CMAKE_VERSION} 

#---------------Install opencv----------------------
WORKDIR /
ENV OPENCV_VERSION="3.4.8"
RUN wget -O opencv.zip  https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip && \
    wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip && \
    unzip -q opencv.zip && \
    unzip -q opencv_contrib.zip && \
    mkdir /opencv-${OPENCV_VERSION}/cmake_binary && \
    cd /opencv-${OPENCV_VERSION}/cmake_binary && \
    cmake -DBUILD_TIFF=ON \
	-DBUILD_opencv_java=OFF \
	-DWITH_CUDA=ON \
	-DENABLE_FAST_MATH=1 \
	-DCUDA_FAST_MATH=1 \
	-DWITH_CUBLAS=1 \
	-DENABLE_AVX=OFF \
	-DWITH_OPENGL=ON \
	-DWITH_OPENCL=ON \
	-DWITH_IPP=ON \
	-DWITH_TBB=ON \
	-DWITH_EIGEN=ON \
	-DWITH_V4L=ON \
	-DBUILD_TESTS=OFF \
	-DBUILD_PERF_TESTS=OFF \
	-DCMAKE_BUILD_TYPE=RELEASE \
	-DCMAKE_INSTALL_PREFIX=$(python3 -c "import sys; print(sys.prefix)") \
	-DPYTHON_EXECUTABLE=$(which python3) \
	-DPYTHON_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") \
	-DPYTHON_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())") \
	-DINSTALL_PYTHON_EXAMPLES=ON \
	-DINSTALL_C_EXAMPLES=OFF \
	-DOPENCV_ENABLE_NONFREE=ON \
	-DOPENCV_GENERATE_PKGCONFIG=ON \
	-DOPENCV_EXTRA_MODULES_PATH=/opencv_contrib-${OPENCV_VERSION}/modules \
	-DBUILD_EXAMPLES=ON \
	-D CUDA_TOOLKIT_ROOT_DIR= /usr/local/cuda-10.0 \
	-DWITH_QT=ON .. && \
    # chmod +x download_with_curl.sh \
    # && sh ./download_with_curl.sh  && \
    make -j8 \
	&& make install \
	&& rm /opencv.zip \
	&& rm /opencv_contrib.zip \
	&& rm -rf /opencv-${OPENCV_VERSION} \
	&& rm -rf /opencv_contrib-${OPENCV_VERSION}

RUN  ln -s \
	/usr/lib/python3.5/dist-packages/cv2/python-3.5/cv2.cpython-36m-x86_64-linux-gnu.so \
	/usr/local/lib/python3.5/dist-packages/cv2.so

####################################################
# Deep learning frameworks
####################################################

#---------------Install PyTorch---------------------
RUN pip3 install --no-cache-dir torch==1.3.0+cu100 torchvision==0.4.1+cu100 -f https://download.pytorch.org/whl/torch_stable.html

#---------------Install TensorFlow------------------
RUN pip3 install --no-cache-dir tensorflow-gpu==1.14.0 && \
    pip3 install --no-cache-dir tflearn

#---------------Install ONNX------------------------
RUN pip3 install --no-cache-dir onnx onnxmltools onnxruntime-gpu

#---------------Install keras------------------------
RUN pip3 install --no-cache-dir keras

#---------------Install ONNX-TensorRT---------------
# determine DGPU_ARCHS from https://developer.nvidia.com/cuda-gpus
# https://github.com/onnx/onnx-tensorrt
WORKDIR /
RUN	git clone --recursive -b v5.0 https://github.com/onnx/onnx-tensorrt.git &&\
	cd onnx-tensorrt &&\
	mkdir build  &&\
	cd build &&\
	cmake .. -DCUDA_INCLUDE_DIRS=/usr/local/cuda/include -DTENSORRT_ROOT=/usr/src/tensorrt -DGPU_ARCHS="61" &&\
	make -j8 &&\
	make install &&\
	ldconfig && \
	cd .. && \
	python setup.py build &&\
	python setup.py install &&\
	rm -rf ./build/ &&\
	rm -rf  /onnx-tensorrt

#----------------Install TensorBoardX -----------------------
WORKDIR /
RUN git clone https://github.com/lanpa/tensorboardX && cd tensorboardX && python setup.py install && rm -rf /tensorboardX

#---------------Install python requirements---------
COPY requirements.txt /tmp/
RUN pip3 install --no-cache-dir --requirement /tmp/requirements.txt

#---------------Install mxnet-simpledet---------
# download and intall pre-built wheel for CUDA 10.0
RUN pip3 install --no-cache-dir cython && \
    pip3 install --no-cache-dir 'git+https://github.com/RogerChern/cocoapi.git#subdirectory=PythonAPI' 

#---------------Add some envirenement variable-----------

RUN echo 'export LC_ALL=C.UTF-8' >> ~/.bashrc
RUN echo 'export LANG=C.UTF-8' >> ~/.bashrc


#----------------Perform some cleaning-----------------------
RUN (apt-get -qq autoremove -y; \
	apt-get -qq autoclean -y)

#----------------set the working directory-------------------
WORKDIR /workspace

CMD ["jupyter", "notebook", "--allow-root", "--port=8888", "--ip=0.0.0.0", "--no-browser"]
