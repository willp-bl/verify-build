FROM openjdk:8-jdk
# for raspberrypi3 use the FROM below to use an armhf image; otherwise armel is used and node has no install candidate
#FROM arm32v7/openjdk:8-jdk

# for verify-frontend/puma 3.6.0 & ruby 2.4.0
RUN apt-get update && apt-get install -y bundler rbenv ruby-build libssl1.0-dev && rbenv install 2.4.0

# for pki in verify-local-startup
RUN apt-get -y install golang && GOPATH="$HOME/go" go get -u github.com/cloudflare/cfssl/cmd/... && GOPATH="$HOME/go" PATH="$GOPATH/bin":$PATH cfssl version

# for verify-service-provider
RUN apt-get install -y lsof

# for passport-verify-stub-relying-party
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && apt-get install -y nodejs node-typescript && node --version && npm --version

# to host the build/runtime workspace
WORKDIR /verify-git-repos

# ensure all the apps can be seen from outside the container, excluding admin ports
EXPOSE 3200 55500 50110 50240 50220 50160 51100 50120 50210 50130 50140 50400 50300

ADD ./build_libraries.sh ./build_and_start_apps.sh ./check_apps.sh ./lib.sh ./
CMD ./build_libraries.sh && ./build_and_start_apps.sh
