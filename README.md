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

### run with PulseAudio

#### PulseAudio access with socks

```shell
# Allow root to connect to X
export DISPLAY=:0
xhost si:localuser:root

# Run the container
docker run -it --rm --name vmware-horizon-client \
  --privileged \
  -e DISPLAY=:0 \
  -e USER=root \
  -e TZ=Asia/Tokyo \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v$HOME/.vmware:/root/.vmware \
  --device /dev/snd \
  -e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
  -v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
  -v ~/.config/pulse/cookie:/root/.config/pulse/cookie \
  kyokuheki/vmware-horizon-client \
  vmware-view -u USER -p PASS -s broker1.example.com --save -q
```

#### PulseAudio access with tcp

```shell
# Enabling TCP listen with PulseAudio
sudo sed -i -e '/^#load-module module-native-protocol-tcp/c load-module module-native-protocol-tcp auth-ip-acl=127.0.0.0/8;172.17.0.0/16' /etc/pulse/default.pa
grep module-native-protocol-tcp /etc/pulse/default.pa
systemctl --user restart pulseaudio.socket pulseaudio.service
pacmd list-modules | grep -A10 -B1 module-native-protocol-tcp

# Allow root to connect to X
export DISPLAY=:0
xhost si:localuser:root

# Run the container
docker run -it --rm --name vmware-horizon-client \
  --privileged \
  -e DISPLAY=:0 \
  -e USER=root \
  -e TZ=Asia/Tokyo \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v$HOME/.vmware:/root/.vmware \
  -ePULSE_SERVER=tcp:172.17.0.1 \
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
