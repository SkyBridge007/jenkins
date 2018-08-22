FROM jenkins/jenkins:2.89.3
USER root


RUN apt-get update && \
apt-get install -qy \
  apt-utils \
  libyaml-dev \
  build-essential \
  python-dev \
  libxml2-dev \
  libxslt-dev \
  libffi-dev \
  libssl-dev \
  default-libmysqlclient-dev \
  python-mysqldb \
  python-pip \
  libjpeg-dev \
  zlib1g-dev \
  libblas-dev\
  liblapack-dev \
  libatlas-base-dev \
  apt-transport-https \
  ca-certificates \
  wget \
  software-properties-common \
  zip \
  unzip \
  gfortran && \
rm -rf /var/lib/apt/lists/*

# Install docker
RUN wget https://download.docker.com/linux/debian/gpg && \
    apt-key add gpg && \
    echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee -a /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -qy docker-ce

# Install compose
RUN curl -L https://github.com/docker/compose/releases/download/1.8.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose

# Install maven3
RUN wget http://mirrors.tuna.tsinghua.edu.cn/apache/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz && \
    tar -zxvf apache-maven-3.5.4-bin.tar.gz && \
    mv apache-maven-3.5.4 /usr/local/maven && \
    rm -fr apache-maven-3.5.4-bin.tar.gz

ENV MAVEN_HOME /usr/local/maven

# Install node8
RUN wget https://nodejs.org/dist/v8.11.3/node-v8.11.3-linux-x64.tar.xz && \
    xz -d node-v8.11.3-linux-x64.tar.xz && tar xvf node-v8.11.3-linux-x64.tar && \
    mv node-v8.11.3-linux-x64 /usr/local/node && \
    rm -fr node-v8.11.3-linux-x64.tar    

# Install gradle
RUN wget https://downloads.gradle.org/distributions/gradle-4.9-bin.zip && \
    unzip gradle-4.9-bin.zip && \
    mv gradle-4.9 /usr/local/gradle && \
    rm -fr gradle-4.9-bin.zip

# Install Android-SDK-Tools
RUN wget https://dl.google.com/android/repository/sdk-tools-linux-4333796.zip && \
    unzip sdk-tools-linux-4333796.zip && \
    mkdir -p /usr/local/android-sdk && \
    mv tools /usr/local/android-sdk/ && \
    rm -fr sdk-tools-linux-4333796.zip && \
    cd /usr/local/android-sdk/tools/bin && \
    yes | ./sdkmanager "build-tools;27.0.2" && \
    yes | ./sdkmanager "build-tools;27.0.3" && \
    yes | ./sdkmanager "platforms;android-26" && \
    yes | ./sdkmanager "platforms;android-27" && \
    yes | ./sdkmanager "platform-tools" && \
    chown jenkins.jenkins -R /usr/local/android-sdk

ENV ANDROID_HOME /usr/local/android-sdk
ENV PATH $PATH:$MAVEN_HOME/bin:/usr/local/node/bin:/usr/local/gradle/bin:$ANDROID_HOME/tools/bin

RUN npm install -g nrm && chown -R 1000.1000 /usr/local/node
RUN pip install cffi --upgrade
RUN pip install pip2pi ansible==2.0


COPY executors.groovy /usr/share/jenkins/ref/init.groovy.d/executors.groovy
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# add the jenkins user to the docker group so that sudo is not required to run docker commands
RUN groupmod -g 1026 docker && gpasswd -a jenkins docker
USER jenkins
