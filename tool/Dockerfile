FROM archlinux:base-devel
ARG DART_VERSION

WORKDIR /app
ENTRYPOINT [ "dart", "test", "-P", "integration" ]

RUN pacman -Sy --noconfirm unzip alpm rsync bitwarden-cli wget hurl

RUN curl -fLo /tmp/dart.zip https://storage.googleapis.com/dart-archive/channels/stable/release/$DART_VERSION/sdk/dartsdk-linux-x64-release.zip \
  && unzip /tmp/dart.zip -d /opt/ \
  && rm /tmp/dart.zip
ENV PATH="$PATH:/opt/dart-sdk/bin"
RUN dart --disable-analytics

COPY pubspec.yaml /app/pubspec.yaml
COPY pubspec.lock /app/pubspec.lock
COPY dart_test.yaml /app/dart_test.yaml
RUN dart pub get --enforce-lockfile
RUN dart run test --help > /dev/null
