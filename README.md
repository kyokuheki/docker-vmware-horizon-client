# docker-vmware-horizon-client
Dockernized VMware Horizon Client (vmware-view)

## run
```shell
xhost si:localuser:root
docker run -it --rm --name vmware-horizon-client \
  --privileged \
  -e DISPLAY=:0 \
  -e USER=root \
  -e TZ=Asia/Tokyo \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v$HOME/.vmware:/root/.vmware \
  kyokuheki/vmware-horizon-client \
  vmware-view -u USER -p PASS -s broker1.example.com --save -q
```

### run with openconnect

```shell
xhost si:localuser:root
docker run ... --name=openconnect kyokuheki/openconnect
docker run -it --rm --name vmware-horizon-client \
  --privileged \
  --net=container:openconnect \
  -e DISPLAY=:0 \
  -e USER=root \
  -e TZ=Asia/Tokyo \
  -v /tmp/.X11-unix/:/tmp/.X11-unix \
  -v$HOME/.vmware:/root/.vmware \
  kyokuheki/vmware-horizon-client \
  vmware-view -u USER -p PASS -s broker1.example.com --save -q
```

## trusted-brokers
```shell
echo "broker1.example.com" >> trusted-brokers
echo "broker2.example.com" >> trusted-brokers
docker run ... -v trusted-brokers:/root/.vmware/view-trusted-brokers ...
```

## Custom image

```Dockerfile
FROM kyokuheki/vmware-horizon-client
COPY ./view-trusted-brokers /root/.vmware/view-trusted-brokers
COPY ./certificates/* /usr/local/share/ca-certificates
RUN set -x \
 && update-ca-certificates
```

```shell
git clone https://github.com/kyokuheki/docker-vmware-horizon-client.git
cd docker-vmware-horizon-client
cp /path/to/your/certificate_file certificates/
echo "broker1.example.com" >> view-trusted-brokers
echo "broker2.example.com" >> view-trusted-brokers
docker build . -f Dockerfile.custom -t vmware-horizon-client
```

## Dependencies
```
VMware Horizon SmartCard
  libpcsclite1
VMware Horizon(R) Virtualization Pack for Skype for Business
  libusb-1.0-0
VMware Horizon Real-Time Audio-Video
  libpulse0
  libv4l-0
VMware Horizon Multimedia Redirection (MMR)
  libgstreamer1.0-0
  libgstreamer-plugins-base1.0-0
VMware Horizon Scanner Redirection
  libsane
VMware Horizon Client HTML5 Multimedia Redirection
  libnss3
  libnspr4
  libx11-xcb1
  libdrm2
  libgbm1
  libasound2
```
