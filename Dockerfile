FROM openjdk:8-jdk

# for ruby
RUN apt-get update
RUN apt-get install -y bundler rbenv
RUN apt-get install -y  ruby-build

RUN apt-get -y install golang
RUN GOPATH="$HOME/go" go get -u github.com/cloudflare/cfssl/cmd/...
RUN GOPATH="$HOME/go" PATH="$GOPATH/bin":$PATH cfssl version

# for verify-frontend/puma 3.6.0 & ruby 2.4.0 on raspberrypi (hopefully)
RUN apt-get -y install libssl1.0-dev
RUN rbenv install 2.4.0

# for verify-service-provider
RUN apt-get install -y lsof

# for passport-verify-stub-relying-party
# this uses nodejs binaries (won't work for armel/raspberrypi)
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
RUN apt-get install -y nodejs node-typescript

# to build nodejs from source - needed for armel/raspberrypi
#WORKDIR /nodejs
#RUN wget https://github.com/nodejs/node/archive/v8.9.3.tar.gz && tar zxf v8.9.3.tar.gz
#WORKDIR /nodejs/node-8.9.3
#RUN ./configure && make && make install

RUN node --version && npm --version

WORKDIR /verify-git-repos

EXPOSE 3200 55500 50110 50240 50220 50160 51100 50120 50210 50130 50140 50400 50300

ADD ./build_libraries.sh ./build_and_start_apps.sh ./check_apps.sh ./

CMD ./build_libraries.sh && ./build_and_start_apps.sh
