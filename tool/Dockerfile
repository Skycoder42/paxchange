FROM archlinux:base-devel

WORKDIR /app
ENTRYPOINT [ "dart", "test", "-P", "integration" ]

RUN pacman -Sy --noconfirm dart rsync
RUN dart --disable-analytics

COPY pubspec.yaml /app/pubspec.yaml
COPY pubspec.lock /app/pubspec.lock
RUN dart pub get
COPY . /app
RUN dart pub get
RUN dart run test --help > /dev/null
