FROM public.ecr.aws/amazonlinux/amazonlinux:2023.4.20240319.1

LABEL org.opencontainers.image.url=https://github.com/SonarSource/docker-sonarqube

ENV LANG='en_US.UTF-8' \
  LANGUAGE='en_US:en' \
  LC_ALL='en_US.UTF-8'

# SonarQube setup
ARG SONARQUBE_VERSION=9.9.4.87374
ARG SONARQUBE_ZIP_URL=https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip
ENV JAVA_HOME="/opt/java17" \
    SONARQUBE_HOME=/opt/sonarqube \
    SONAR_VERSION="${SONARQUBE_VERSION}" \
    SQ_DATA_DIR="/opt/sonarqube/data" \
    SQ_EXTENSIONS_DIR="/opt/sonarqube/extensions" \
    SQ_LOGS_DIR="/opt/sonarqube/logs" \
    SQ_TEMP_DIR="/opt/sonarqube/temp"

RUN set -eux; \
  dnf install -y shadow-utils java-17-amazon-corretto-devel gnupg unzip tar gzip bash ; \
  curl -L -o dejavu-fonts.zip https://sourceforge.net/projects/dejavu/files/dejavu/2.37/dejavu-fonts-ttf-2.37.zip ; \
  unzip -q dejavu-fonts.zip -d /usr/share/fonts/ ; \
  rm dejavu-fonts.zip; \
  groupadd --system --gid 1000 sonarqube; \
  useradd --system --uid 1000 --gid sonarqube sonarqube; \
  mkdir -p /opt/java17 ; \
  cp -r /usr/lib/jvm/java-17-amazon-corretto.x86_64/* /opt/java17; \
  echo "networkaddress.cache.ttl=5" >> "${JAVA_HOME}/conf/security/java.security"; \
  sed --in-place --expression="s?securerandom.source=file:/dev/random?securerandom.source=file:/dev/urandom?g" "${JAVA_HOME}/conf/security/java.security"; \
  #rpm --import https://binaries.sonarsource.com/signatures/sonarqube/sonarqube-pgpkeys.ringsrc; \
  mkdir --parents /opt; \
  cd /opt; \
  curl --fail --location --output sonarqube.zip --silent --show-error "${SONARQUBE_ZIP_URL}"; \
  curl --fail --location --output sonarqube.zip.asc --silent --show-error "${SONARQUBE_ZIP_URL}.asc"; \
  unzip -q sonarqube.zip; \
  mv "sonarqube-${SONARQUBE_VERSION}" sonarqube; \
  rm sonarqube.zip*; \
  rm -rf ${SONARQUBE_HOME}/bin/*; \
  ln -s "${SONARQUBE_HOME}/lib/sonar-application-${SONARQUBE_VERSION}.jar" "${SONARQUBE_HOME}/lib/sonarqube.jar"; \
  chmod -R 555 ${SONARQUBE_HOME}; \
  chmod -R ugo+wrX "${SQ_DATA_DIR}" "${SQ_EXTENSIONS_DIR}" "${SQ_LOGS_DIR}" "${SQ_TEMP_DIR}"; \
  #dnf remove -y gnupg unzip tar gzip ; \
  dnf clean all; \
  rm -rf /var/cache/yum;


COPY entrypoint.sh ${SONARQUBE_HOME}/docker/

WORKDIR ${SONARQUBE_HOME}
RUN chmod +x ${SONARQUBE_HOME}/docker/entrypoint.sh; \
    chmod -R ugo+wrX "${SQ_DATA_DIR}" "${SQ_EXTENSIONS_DIR}" "${SQ_LOGS_DIR}" "${SQ_TEMP_DIR}"
EXPOSE 9000

USER sonarqube
STOPSIGNAL SIGINT

ENTRYPOINT ["/opt/sonarqube/docker/entrypoint.sh"]