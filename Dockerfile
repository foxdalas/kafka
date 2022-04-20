FROM openjdk:17-slim-buster

ENV KAFKA_VERSION=3.1.0 SCALA_VERSION=2.13

RUN apt-get update && apt-get install -y curl gnupg dirmngr ca-certificates netcat-openbsd --no-install-recommends
RUN curl -f -sLS -o KEYS https://www.apache.org/dist/kafka/KEYS; \
		gpg --import KEYS && rm KEYS; \
		SCALA_BINARY_VERSION=$(echo $SCALA_VERSION | cut -f 1-2 -d '.'); \
		mkdir -p /opt/kafka; \
		curl -f -sLS -o kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz.asc https://www.apache.org/dist/kafka/$KAFKA_VERSION/kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz.asc; \
  		curl -f -sLS -o kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz "https://www-eu.apache.org/dist/kafka/$KAFKA_VERSION/kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz"; \
  		gpg --verify kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz.asc kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz; \
  		tar xzf kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz --strip-components=1 -C /opt/kafka; \
  		rm kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz; \
  		rm -rf /opt/kafka/site-docs; \
  		apt-get purge -y --auto-remove curl gnupg dirmngr; \
  		rm -rf /var/lib/apt/lists; \
  		rm -rf /var/log/dpkg.log /var/log/alternatives.log /var/log/apt /root/.gnupg

 WORKDIR /opt/kafka

COPY docker-help.sh /usr/local/bin/docker-help
ENTRYPOINT ["docker-help"]