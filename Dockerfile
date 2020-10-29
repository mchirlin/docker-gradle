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
    

## FTP Server https://hub.docker.com/r/panubo/vsftpd/

ARG USER_ID=14
ARG GROUP_ID=50

RUN usermod -u ${USER_ID} ftp
RUN groupmod -g ${GROUP_ID} ftp

ENV FTP_USER ftp
ENV FTP_PASS password
ENV PASV_ADDRESS **IPv4**
ENV PASV_ADDR_RESOLVE NO
ENV PASV_ENABLE YES
ENV PASV_MIN_PORT 21100
ENV PASV_MAX_PORT 21110
ENV XFERLOG_STD_FORMAT NO
ENV LOG_STDOUT **Boolean**
ENV FILE_OPEN_MODE 0666
ENV LOCAL_UMASK 077
ENV REVERSE_LOOKUP_ENABLE YES
ENV PASV_PROMISCUOUS NO
ENV PORT_PROMISCUOUS NO

RUN apt-get update \
    && apt-get install -y --no-install-recommends vsftpd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY vsftpd.conf /etc/vsftpd/
COPY vsftpd_virtual /etc/pam.d/
COPY run-vsftpd.sh /usr/sbin/

RUN chmod +x /usr/sbin/run-vsftpd.sh
RUN mkdir -p /home/vsftpd/
RUN chown -R ftp:ftp /home/vsftpd/

VOLUME /home/vsftpd
VOLUME /var/log/vsftpd

EXPOSE 20 21

## SFTP Server

# RUN apt-get update && apt-get install -y \
#	openssh-server \
#	mcrypt \
#	&& mkdir /var/run/sshd \
#	&& chmod 0755 /var/run/sshd \
#	&& mkdir -p /data/incoming \
#	&& apt-get clean \
#	&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
#	&& mkdir /ssh/
  
# ADD start.sh /usr/local/bin/start.sh
# ADD sshd_config /etc/ssh/sshd_config

# VOLUME ["/data/incoming"]
# EXPOSE 22

# CMD ["/bin/bash", "/usr/local/bin/start.sh"]