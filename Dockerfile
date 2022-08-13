FROM docker.io/library/archlinux:base-devel

COPY ca.pem /ca.pem
COPY update_package.py /update_package.py
COPY build.py /build.py
COPY deploy.py /deploy.py
COPY entrypoint.sh /entrypoint.sh

RUN echo '[multilib]' >> /etc/pacman.conf && echo 'Include = /etc/pacman.d/mirrorlist' >> /etc/pacman.conf && \
    sed -i 's/ParallelDownloads = 5/ParallelDownloads = 10/g' /etc/pacman.conf && \
    echo 'Server = https://pacman_cache.aurum.lan/$repo/os/$arch' > /etc/pacman.d/mirrorlist && \
    trust anchor /ca.pem && update-ca-trust && rm /ca.pem && \
    pacman-key --init && \
    pacman --noconfirm --needed -Syu git python python-requests wget base-devel rsync openssh && \
    pacman --noconfirm -Scc && \
    chmod +x /update_package.py && \
    chmod +x /build.py && \
    chmod +x /deploy.py && \
    chmod +x /entrypoint.sh && \
    git config --global user.email "kakaoh6@gmail.com" && \
    git config --global user.name "Kay Kaprolat" && \
    useradd --uid 1000 --shell /bin/bash --groups wheel --create-home aur && \
    echo '%wheel ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

USER aur
COPY --chown=aur aurutils /aurutils
RUN cd /aurutils && \
    makepkg -si --noconfirm && \
    sudo rm -rf /aurutils
