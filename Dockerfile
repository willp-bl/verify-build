FROM openjdk:8-jdk

# for ruby
RUN apt-get update
RUN apt-get install -y bundler rbenv
RUN apt-get install -y  ruby-build

RUN apt-get -y install golang
RUN GOPATH="$HOME/go" go get -u github.com/cloudflare/cfssl/cmd/...
RUN GOPATH="$HOME/go" PATH="$GOPATH/bin":$PATH cfssl version

RUN rbenv install 2.4.0

# for verify-frontend/puma 3.6.0
RUN apt-get -y install libssl1.0-dev

ADD ./build_libraries.sh .
ADD ./build_and_start_apps.sh .

EXPOSE 3200 55500 50110 50240 50220 50160 51100 50120 50210 50130 50140 50400 50300

CMD ./build_libraries.sh && ./build_and_start_apps.sh
