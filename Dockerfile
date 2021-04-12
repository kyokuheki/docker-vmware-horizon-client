FROM ubuntu:latest
LABEL maintainer Kenzo Okuda <kyokuheki@gmail.com>

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    USER=root

RUN set -x \
 && apt-get update && apt-get install -y \
    curl \
    iproute2 \
    iputils-ping \
    libcups2 \
    libglib2.0-0 \
    libgtk-3-0 \
    libxkbfile1 \
    libpcsclite1 \
    libusb-1.0-0 \
    libpulse0 \
    libv4l-0 \
    libgstreamer1.0-0 \
    libgstreamer-plugins-base1.0-0 \
    libsane \
    libnss3 \
    libnspr4 \
    libx11-xcb1 \
    libdrm2 \
    libgbm1 \
    libasound2 \
 && apt-get clean && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

RUN set -x \
 && curl -sSLo VMware-Horizon-Client.bundle https://download3.vmware.com/software/view/viewclients/CART22FQ1/VMware-Horizon-Client-2103-8.2.0-17742757.x64.bundle \
 && sh ./VMware-Horizon-Client.bundle --console --eulas-agreed --required \
 && rm -fv VMware-Horizon-Client.bundle

RUN set -x \
 && mkdir -p /root/.vmware \
 && echo 'view.sslVerificationMode = "3"' > /root/.vmware/view-preferences

COPY ./certificates/* /usr/local/share/ca-certificates
RUN set -x \
 && update-ca-certificates

VOLUME /tmp/.X11-unix
ENTRYPOINT ["/usr/bin/vmware-view"]
CMD ["--display=:0"]
