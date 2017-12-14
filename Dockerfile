# s2i-enRoute
# based on: https://github.com/jorgemoralespou/s2i-java
FROM openjdk:alpine
LABEL maintainer="Mario Curcija <mario.curcija@gmail.com>"
RUN apk --no-cache add curl libstdc++ git bash

WORKDIR /tmp

ENV GRADLE_VERSION=4.4
ENV GRADLE_HOME=/opt/gradle
RUN curl -O --location --silent --show-error https://downloads.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
        && mkdir /opt \
        && unzip -q gradle-${GRADLE_VERSION}-bin.zip -d /opt \
        && ln -s ${GRADLE_HOME}-${GRADLE_VERSION} ${GRADLE_HOME} \
        && rm -f gradle-${GRADLE_VERSION}-bin.zip

ENV HOME=/opt/app-root/src

# add user enroute
RUN mkdir -p ${HOME} \
        && addgroup -g 1001 enroute \
        && adduser -u 1001 -h ${HOME} -D -G enroute enroute

RUN chmod -R u+x ${HOME} && \ 
	chgrp -R 0 ${HOME} && \
	chmod -R g=u ${HOME} /etc/passwd 

# ensure openshift deployment directory
RUN mkdir -p /opt/openshift && chown enroute:enroute /opt/openshift

LABEL io.openshift.s2i.scripts-url=image:///usr/local/s2i
COPY ./s2i/bin/ /usr/local/s2i  
COPY ./enroute-workspace/ ${HOME}/enroute-workspace

RUN chown -R enroute:enroute ${HOME}/enroute-workspace
	 
USER 1001
WORKDIR ${HOME}
ENV PATH=${GRADLE_HOME}/bin/:$PATH

ENV BUILDER_VERSION 1.0
LABEL io.k8s.description="Platform for building enRoute fat jar applications using gradle" \
      io.k8s.display-name="enRoute S2I builder 1.0" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,enRoute,gradle,java,microservices,export"

# preload enroute 2.0.0 distro (using minimum enroute-workspace)
RUN gradle --no-daemon -b ${HOME}/enroute-workspace/build.gradle export.debug
RUN rm ${HOME}/enroute-workspace -fr 
# check cache size 
RUN du -xsh ~/.gradle ~/.m2 ~/.bnd 

# Set the default port for applications built using this image
EXPOSE 8080

# Set the default CMD for the image
# CMD ["java","-Djava.security.egd=file:/dev/./urandom","-jar","/opt/openshift/app.jar"]
CMD ["usage"]
