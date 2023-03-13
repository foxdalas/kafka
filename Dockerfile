FROM openjdk:17-slim-buster AS build

ENV CRUISE_CONTROL_VERSION=2.5.113

WORKDIR /build

RUN apt-get update && apt-get install -y git
RUN git clone https://github.com/linkedin/cruise-control.git && \
		cd cruise-control && \
		git checkout $CRUISE_CONTROL_VERSION && \
		./gradlew jar
RUN mv /build/cruise-control/cruise-control-metrics-reporter/build/libs/cruise-control-metrics-reporter-$CRUISE_CONTROL_VERSION.jar /build/cruise-control-metrics-reporter.jar 
 

FROM openjdk:17-slim-buster

ENV KAFKA_VERSION=3.4.0 SCALA_VERSION=2.13 KAFKA_FS_JCA=0.0.2 JMX_PROMETHEUS=0.17.2


ARG TARGETARCH

RUN apt-get update && apt-get install -y curl gnupg dirmngr ca-certificates netcat-openbsd --no-install-recommends


RUN mkdir -p /opt/jmx-exporter; \
	curl -o /opt/jmx-exporter/jmx_prometheus_httpserver.jar https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_httpserver/$JMX_PROMETHEUS/jmx_prometheus_httpserver-$JMX_PROMETHEUS.jar; \
	curl -o /opt/jmx-exporter/jmx_prometheus_javaagent.jar  https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/$JMX_PROMETHEUS/jmx_prometheus_javaagent-$JMX_PROMETHEUS.jar


RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl"; \
	curl -LO "https://dl.k8s.io/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl.sha256"; \
	echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check ;\
	rm kubectl.sha256; \
	mv kubectl /usr/bin/; \
	chmod +x /usr/bin/kubectl

RUN curl -f -sLS -o KEYS https://www.apache.org/dist/kafka/KEYS; \
		gpg --import KEYS && rm KEYS; \
		SCALA_BINARY_VERSION=$(echo $SCALA_VERSION | cut -f 1-2 -d '.'); \
		mkdir -p /opt/kafka; \
		curl -f -sLS -o kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz.asc https://www.apache.org/dist/kafka/$KAFKA_VERSION/kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz.asc; \
  		curl -f -sLS -o kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz "https://www-eu.apache.org/dist/kafka/$KAFKA_VERSION/kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz"; \
  		gpg --verify kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz.asc kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz; \
  		tar xzf kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz --strip-components=1 -C /opt/kafka; \
  		rm kafka_$SCALA_BINARY_VERSION-$KAFKA_VERSION.tgz; \
  		rm -rf /opt/kafka/site-docs


RUN curl -f -sLS -o /opt/kafka/libs/kafka-fs-jca-current.jar https://github.com/tufitko/kafka-fs-jca/releases/download/v$KAFKA_FS_JCA/kafka-fs-jca-current.jar

RUN apt-get purge -y --auto-remove curl gnupg dirmngr; \
	rm -rf /var/lib/apt/lists; \
	rm -rf /var/log/dpkg.log /var/log/alternatives.log /var/log/apt /root/.gnupg

WORKDIR /opt/kafka

COPY --from=build /build/cruise-control-metrics-reporter.jar /opt/kafka/libs/
COPY docker-help.sh /usr/local/bin/docker-help

ENTRYPOINT ["docker-help"]
