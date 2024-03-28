
#FROM amazonlinux:2023
FROM public.ecr.aws/amazonlinux/amazonlinux:2023.4.20240319.1

LABEL org.opencontainers.image.url=https://github.com/SonarSource/docker-sonarqube

ENV LANG='en_US.UTF-8' \
  LANGUAGE='en_US:en' \
  LC_ALL='en_US.UTF-8'

#
# SonarQube setup
#
ARG SONARQUBE_VERSION=9.9.4.87374
ARG SONARQUBE_ZIP_URL=https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip
ENV SONARQUBE_HOME=/opt/sonarqube \
  SONAR_VERSION="${SONARQUBE_VERSION}" \
  SQ_DATA_DIR="/opt/sonarqube/data" \
  SQ_EXTENSIONS_DIR="/opt/sonarqube/extensions" \
  SQ_LOGS_DIR="/opt/sonarqube/logs" \
  SQ_TEMP_DIR="/opt/sonarqube/temp"

RUN set -eux; \
  groupadd --system --gid 1000 sonarqube; \
  useradd --system --uid 1000 --gid sonarqube sonarqube; \
  # Verify Java installation
  java -version; \
  curl --fail --location --output sonarqube.zip --silent --show-error "${SONARQUBE_ZIP_URL}"; \
  curl --fail --location --output sonarqube.zip.asc --silent --show-error "${SONARQUBE_ZIP_URL}.asc"; \
  gpg --batch --verify sonarqube.zip.asc sonarqube.zip; \
  unzip -q sonarqube.zip; \
  mv "sonarqube-${SONARQUBE_VERSION}" sonarqube; \
  rm sonarqube.zip*; \
  rm -rf ${SONARQUBE_HOME}/bin/*; \
  ln -s "${SONARQUBE_HOME}/lib/sonar-application-${SONARQUBE_VERSION}.jar" "${SONARQUBE_HOME}/lib/sonarqube.jar"; \
  chmod -R 555 ${SONARQUBE_HOME}; \
  chmod -R ugo+wrX "${SQ_DATA_DIR}" "${SQ_EXTENSIONS_DIR}" "${SQ_LOGS_DIR}" "${SQ_TEMP_DIR}"; \

COPY entrypoint.sh ${SONARQUBE_HOME}/docker/

WORKDIR ${SONARQUBE_HOME}
EXPOSE 9000

USER sonarqube
STOPSIGNAL SIGINT

ENTRYPOINT ["/opt/sonarqube/docker/entrypoint.sh"]

