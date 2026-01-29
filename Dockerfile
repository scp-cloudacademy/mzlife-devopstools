FROM jenkins/inbound-agent:latest-jdk17

USER root

# Docker CLI 설치
RUN curl -L0 "https://download.docker.com/linux/static/stable/x86_64/docker-28.0.1.tgz" -o /tmp/docker.tgz && \
    tar --extract \
      --file /tmp/docker.tgz \
      --strip-components 1 \
      --directory /usr/local/bin/ && \
    rm /tmp/docker.tgz

# Docker Buildx 플러그인 복사
COPY --from=docker/buildx-bin /buildx /usr/libexec/docker/cli-plugins/docker-buildx

# 추가 빌드 도구 설치 (Maven, Gradle, kubectl 등)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# kubectl 설치
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Maven 설치
ARG MAVEN_VERSION=3.9.6
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz | tar xzf - -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven && \
    ln -s /opt/maven/bin/mvn /usr/local/bin/mvn

# Gradle 설치
ARG GRADLE_VERSION=8.5
RUN curl -fsSL https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip -o /tmp/gradle.zip && \
    unzip -d /opt /tmp/gradle.zip && \
    ln -s /opt/gradle-${GRADLE_VERSION} /opt/gradle && \
    ln -s /opt/gradle/bin/gradle /usr/local/bin/gradle && \
    rm /tmp/gradle.zip

# SonarQube Scanner 설치
ARG SONAR_SCANNER_VERSION=6.2.1.4610
RUN curl -fsSL https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux-x64.zip -o /tmp/sonar-scanner.zip && \
    unzip -d /opt /tmp/sonar-scanner.zip && \
    ln -s /opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux-x64 /opt/sonar-scanner && \
    ln -s /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner && \
    rm /tmp/sonar-scanner.zip

# 환경 변수 설정
ENV MAVEN_HOME=/opt/maven
ENV GRADLE_HOME=/opt/gradle
ENV SONAR_SCANNER_HOME=/opt/sonar-scanner
ENV PATH="${MAVEN_HOME}/bin:${GRADLE_HOME}/bin:${SONAR_SCANNER_HOME}/bin:${PATH}"

USER jenkins
