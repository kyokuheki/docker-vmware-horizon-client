# docker-vmware-horizon-client
Dockernized VMware Horizon Client (vmware-view)

## Run
### Run using Xorg server via UNIX Socket

```shell
docker run -it --rm --name vmware-horizon-client \
  --privileged \
  -e DISPLAY=:0 \
  -e USER \
  -e TZ=Asia/Tokyo \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  --device /dev/snd \
  -e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
  -v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
  -v ~/.config/pulse/cookie:/root/.config/pulse/cookie \
  -v $HOME/.vmware:/root/.vmware \
  kyokuheki/vmware-horizon-client \
  vmware-view -u USER -p PASS -s broker1.example.com --save -q
```

If you get black screen, see [Black screen problem](#black-screen-problem)

### Run using Xorg server via TCP connection

Enable the TCP listen for Xorg server.

```shell
sudo sed -i -e '/^\[security\]/a DisallowTCP=false' /etc/gdm3/custom.conf
awk '/^\[security\]/,/^\[xdmcp\]/' /etc/gdm3/custom.conf
sudo systemctl restart gdm.service
ss -nltpu | grep 6000
```

Run the container.

```shell
# Allow 172.17.0.100 to connect to X
export DISPLAY=:0
xhost +inet:172.17.0.100

# Run the container
docker run -it --rm --name vmware-horizon-client \
  --ip=172.17.0.100 \
  -e DISPLAY=172.17.0.1:0 \
  -e USER \
  -e TZ=Asia/Tokyo \
  --device /dev/snd \
  -e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
  -v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
  -v ~/.config/pulse/cookie:/root/.config/pulse/cookie \
  -v $HOME/.vmware:/root/.vmware \
  kyokuheki/vmware-horizon-client \
  vmware-view -u USER -p PASS -s broker1.example.com --save -q
```

### Use root user
If you want to use `root`, run the following command. You will temporarily allow the root user to access the local user's X session using the `xhost` command.

```shell
# Set DISPLAY env
export DISPLAY=:0

# Allow root to connect to X
xhost si:localuser:root

# Run the container
docker run -it --rm --name vmware-horizon-client \
  -e USER=root \
...
```

### PulseAudio access with UNIX Socket

The following four Docker options are required to connect to the PulseAudio server via UNIX Socket.

1. `--device /dev/snd`: Add a sound device.
2. `-e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native`: Set the UNIX Socket path to the environment variable `PULSE_SERVER`.
3. `-v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native`: Mount the `${XDG_RUNTIME_DIR}` where the UNIX Socket is located.
4. `-v ~/.config/pulse/cookie:/root/.config/pulse/cookie`: Mount the `cookie`.

```shell
docker run ... \
  --device /dev/snd \
  -e PULSE_SERVER=unix:${XDG_RUNTIME_DIR}/pulse/native \
  -v ${XDG_RUNTIME_DIR}/pulse/native:${XDG_RUNTIME_DIR}/pulse/native \
  -v ~/.config/pulse/cookie:/root/.config/pulse/cookie \
...
```

### PulseAudio access with TCP

If you want to connect to the PulseAudio server via TCP, you need to do the following steps. This is useful when the machine that outputs audio and the machine that runs `vmware-view` are different.

Enable TCP listen on the PulseAudio server before starting the Docker container.

```shell
sudo sed -i -e '/^#load-module module-native-protocol-tcp/c load-module module-native-protocol-tcp auth-ip-acl=127.0.0.0/8;172.17.0.0/16' /etc/pulse/default.pa
grep module-native-protocol-tcp /etc/pulse/default.pa
systemctl --user restart pulseaudio.socket pulseaudio.service
pacmd list-modules | grep -A10 -B1 module-native-protocol-tcp
```

The following the Docker options are required to connect to the PulseAudio server via UNIX Socket.

1. `-e PULSE_SERVER=tcp:172.17.0.1`: Set the TCP socket path to the environment variable PULSE_SERVER.

```shell
# Run the container
docker run ... \
  -e PULSE_SERVER=tcp:172.17.0.1 \
```

### Run with openconnect

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

## Black screen problem

After logging in with VMWare Horizon Client, you may face a black screen. 
The following table shows the matrix of screen display and audio output when Ubuntu 20.04 is used as the host OS.

| VMware Horizon Client | X(TCP) / PulseAudio(UNIX) | X(TCP) / PulseAudio(TCP) | X(UNIX) / PulseAudio(UNIX) | X(UNIX) / PulseAudio(TCP) |
| --------------------- | ------------------------- | ------------------------ | -------------------------- | ------------------------- |
| 2103-8.2.0-17742757   | OK                        | OK                       | Black screen               | Black screen              |
| 5.1.0-13956721        | OK                        | OK                       | Black screen               | Black screen              |
| 5.0.0-12557422        | OK                        | OK                       | Choppy sound               | Choppy sound              |
| 4.10.0-11053294       | OK                        | OK                       | Choppy sound               | Choppy sound              |

- If you need audio output, use version 2103 and connect to the Xorg server via TCP.
- If you don't need audio output, you can use version 5.0.0 and connect to the Xorg server via UNIX Socket.

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
