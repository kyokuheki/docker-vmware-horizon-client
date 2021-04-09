FROM python:slim
LABEL maintainer Kenzo Okuda <kyokuheki@gmail.com>

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    USER=root

RUN set -x \
 && apt-get update && apt-get install -y \
    wget \
    iproute2 \
    iputils-ping \
    libx11-6 \
    libxinerama1 \
    libatk1.0-0 \
    libcairo2 \
    libgdk-pixbuf2.0-0 \
    libgtk2.0-0 \
    libxss1 \
    libxtst6 \
    libpcsclite1 \
    libusb-1.0-0 \
    libpulse0 \
    libv4l-0 \
    libxkbfile1 \
 && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*
# libgstreamer0.10-0 libgstreamer-plugins-base0.10-0

RUN set -x \
 && wget https://download3.vmware.com/software/view/viewclients/CART19FQ4/VMware-Horizon-Client-4.10.0-11053294.x64.bundle \
 && TERM=dumb sh ./VMware-Horizon-Client-4.10.0-11053294.x64.bundle --console --eulas-agreed --required \
 && rm -fv VMware-Horizon-Client-4.10.0-11053294.x64.bundle

RUN set -x \
 && mkdir -p /root/.vmware \
 && echo 'view.sslVerificationMode = "3"' > /root/.vmware/view-preferences

COPY ./certificates/* /usr/local/share/ca-certificates
RUN set -x \
 && update-ca-certificates

VOLUME /tmp/.X11-unix
ENTRYPOINT ["/usr/bin/vmware-view"]
CMD ["--display :0"]
