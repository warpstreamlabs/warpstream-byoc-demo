FROM openjdk:8-jre-slim

ENV KAFKA_VERSION=3.7.1 \
    SCALA_VERSION=2.13

RUN apt-get update && \
    apt-get install -y wget netcat && \
    wget https://downloads.apache.org/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
    tar -xzf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
    mv kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka && \
    rm kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
    wget https://raw.githubusercontent.com/apache/kafka/${KAFKA_VERSION}/config/tools-log4j.properties -P /opt/kafka/config

ENV PATH="/opt/kafka/bin:${PATH}"

CMD ["bash"]