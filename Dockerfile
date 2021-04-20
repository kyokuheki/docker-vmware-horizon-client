FROM ubuntu:20.04
LABEL maintainer Kenzo Okuda <kyokuheki@gmail.com>

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    BUNDLE_URL=https://download3.vmware.com/software/view/viewclients/CART22FQ1/VMware-Horizon-Client-2103-8.2.0-17742757.x64.bundle \
    USER=root

RUN set -x \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    iproute2 \
    iputils-ping \
    python3 \
    binutils \
    libcups2 \
    libglib2.0-0 \
    libgtk-3-0 \
    libxtst6 \
    libxkbfile1 \
 && apt-get install -y --no-install-recommends \
    pulseaudio \
    libcanberra-pulse \
    libcanberra-gtk3-module \
    libcanberra-gtk0 \
 && apt-get install -y --no-install-recommends \
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
 && curl -sSLo VMware-Horizon-Client.bundle $BUNDLE_URL \
 && sh ./VMware-Horizon-Client.bundle --console --eulas-agreed --required \
 && rm -fv VMware-Horizon-Client.bundle

RUN set -x \
 && mkdir -p /root/.vmware \
 && echo 'view.sslVerificationMode = "3"' > /root/.vmware/view-preferences

COPY ./certificates/* /usr/local/share/ca-certificates
RUN set -x \
 && update-ca-certificates

VOLUME /tmp/.X11-unix
CMD ["/usr/bin/vmware-view", "--display=:0"]
