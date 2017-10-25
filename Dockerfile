FROM r351574nc3/c9-alpine:latest

##############
# INSTALL JAVA 
############## 
 
# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

# add a simple script that can auto-detect the appropriate JAVA_HOME value
# based on whether the JDK or only the JRE is installed
RUN { \
		echo '#!/bin/sh'; \
		echo 'set -e'; \
		echo; \
		echo 'dirname "$(dirname "$(readlink -f "$(which javac || which java)")")"'; \
	} > /usr/local/bin/docker-java-home \
	&& chmod +x /usr/local/bin/docker-java-home
ENV JAVA_HOME /usr/lib/jvm/java-1.8-openjdk
ENV PATH $PATH:/usr/lib/jvm/java-1.8-openjdk/jre/bin:/usr/lib/jvm/java-1.8-openjdk/bin

ENV JAVA_VERSION 8u131
ENV JAVA_ALPINE_VERSION 8.131.11-r2

RUN set -x \
	&& apk add --no-cache \
		openjdk8="$JAVA_ALPINE_VERSION" \
&& [ "$JAVA_HOME" = "$(docker-java-home)" ]

##############
# INSTALL GRADLE 
############## 

CMD ["gradle"]

ENV GRADLE_HOME /opt/gradle
ENV GRADLE_VERSION 4.2.1

ARG GRADLE_DOWNLOAD_SHA256=b551cc04f2ca51c78dd14edb060621f0e5439bdfafa6fd167032a09ac708fbc0
RUN set -o errexit -o nounset \
	&& echo "Installing build dependencies" \
	&& apk add --no-cache --virtual .build-deps \
		ca-certificates \
		openssl \
		unzip \
	\
	&& echo "Downloading Gradle" \
	&& wget -O gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
	\
	&& echo "Checking download hash" \
	&& echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum -c - \
	\
	&& echo "Installing Gradle" \
	&& unzip gradle.zip \
	&& rm gradle.zip \
	&& mkdir -p /opt \
	&& mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
	&& ln -s "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
	\
	&& apk del --no-cache .build-deps \
	\
  && echo "Adding gradle user and group" \
	&& addgroup -S -g 1002 gradle \
	&& adduser -D -S -G gradle -u 1002 -s /bin/ash gradle \
	&& mkdir /home/gradle/.gradle \
	&& mkdir /home/gradle/work \
	&& chown -R gradle:gradle /home/gradle $C9_HOME \
  \
	&& echo "Symlinking root Gradle cache to gradle Gradle cache" \
  && ln -s $C9_HOME/c9sdk /home/gradle/.c9 \
	&& ln -s /home/gradle/.gradle /root/.gradle \
  && rm -rf /var/cache/apk/*

RUN apk add --no-cache ca-certificates bash curl make gcc g++ python linux-headers libgcc libstdc++ openssl

# Create Gradle volume
USER gradle
WORKDIR /home/gradle/work
VOLUME ["/home/gradle/.gradle"]

RUN set -o errexit -o nounset \
	&& echo "Testing Gradle installation" \
  && gradle --version
