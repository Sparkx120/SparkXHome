FROM docker.io/library/archlinux:latest

RUN useradd test -m
RUN usermod --append --groups wheel test

RUN pacman -Syu --noconfirm curl sudo

RUN echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers.d/wheel

USER test
ENV SPARKX_INSTALL_DOCKER_ENV=true

COPY . /home/test/projects/SparkXHome

WORKDIR /home/test/projects/SparkXHome
