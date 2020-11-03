FROM adoptopenjdk:8-jdk-hotspot

CMD ["gradle"]

ENV GRADLE_HOME /opt/gradle

RUN set -o errexit -o nounset \
    && echo "Adding gradle user and group" \
    && groupadd --system --gid 1000 gradle \
    && useradd --system --gid gradle --uid 1000 --shell /bin/bash --create-home gradle \
    && mkdir /home/gradle/.gradle \
    && chown --recursive gradle:gradle /home/gradle \
    \
    && echo "Symlinking root Gradle cache to gradle Gradle cache" \
    && ln -s /home/gradle/.gradle /root/.gradle

VOLUME /home/gradle/.gradle

WORKDIR /home/gradle

RUN apt-get update \
    && apt-get install --yes --no-install-recommends gnupg \
    && key='E1DD270288B4E6030699E45FA1715D88E1DF1F24' \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key" \
    && gpg --batch --armor --export "$key" > /etc/apt/trusted.gpg.d/git-ppa.gpg.asc \
    && gpgconf --kill all \
    && rm -rf "$GNUPGHOME" \
    && echo 'deb http://ppa.launchpad.net/git-core/ppa/ubuntu bionic main' > /etc/apt/sources.list.d/git-core-ppa.list \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
        fontconfig \
        unzip \
        wget \
        \
        bzr \
        git \
        git-lfs \
        mercurial \
        openssh-client \
        subversion \
    && rm -rf /var/lib/apt/lists/*

ENV GRADLE_VERSION 6.7
ARG GRADLE_DOWNLOAD_SHA256=8ad57759019a9233dc7dc4d1a530cefe109dc122000d57f7e623f8cf4ba9dfc4
RUN set -o errexit -o nounset \
    && echo "Downloading Gradle" \
    && wget --no-verbose --output-document=gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    \
    && echo "Checking download hash" \
    && echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum --check - \
    \
    && echo "Installing Gradle" \
    && unzip gradle.zip \
    && rm gradle.zip \
    && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
    && ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
    \
    && echo "Testing Gradle installation" \
    && gradle --version
    
## FTP Server https://hub.docker.com/r/panubo/vsftpd/ https://github.com/panubo/docker-vsftpd/blob/master/Dockerfile

ARG FTP_UID=48
ARG FTP_GID=48
RUN set -x \
  && groupadd -g ${FTP_GID} ftp \
  && useradd --no-create-home --home-dir /srv -s /bin/false --uid ${FTP_UID} --gid ${FTP_GID} -c 'ftp daemon' ftp \
  ;
  
RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends vsftpd db5.3-util whois \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  ;

RUN set -x \
  && mkdir -p /var/run/vsftpd/empty /etc/vsftpd/user_conf /var/ftp /srv \
  && touch /var/log/vsftpd.log \
  && rm -rf /srv/ftp \
  ;

COPY vsftpd*.conf /etc/
COPY vsftpd_virtual /etc/pam.d/
COPY *.sh /

VOLUME ["/etc/vsftpd", "/srv"]

EXPOSE 21 4559 4560 4561 4562 4563 4564

ENTRYPOINT ["/entry.sh"]
CMD ["vsftpd"]

