FROM openjdk:8-jdk
# for raspberrypi3 use the FROM below to use an armhf image; otherwise armel is used and node has no install candidate
#FROM arm32v7/openjdk:8-jdk

# for verify-frontend/puma 3.6.0 & ruby 2.4.0
RUN apt-get update && apt-get install -y bundler rbenv ruby-build libssl1.0-dev && rbenv install 2.4.0

# for pki in verify-local-startup
# golang 1.8+ needed for master branch of cfssl
RUN echo 'deb http://ftp.debian.org/debian stretch-backports main' > /etc/apt/sources.list.d/stretch-backports.list && apt-get update && apt-get -t stretch-backports -y install golang && GOPATH="$HOME/go" go get -u github.com/cloudflare/cfssl/cmd/... && GOPATH="$HOME/go" PATH="$GOPATH/bin":$PATH cfssl version

# for verify-service-provider
RUN apt-get install -y lsof

# for passport-verify-stub-relying-party
RUN curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash - && apt-get install -y nodejs node-typescript && node --version && npm --version

# for stub-idp - note that the database is not accessible from outside this container
# which is good because this command sets the password to password which is generally a
# very bad idea and not recommended
RUN apt-get install -y postgresql postgresql-client && service postgresql start && sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'password';"

# to host the build/runtime workspace
WORKDIR /verify-git-repos

# ensure all the apps can be seen from outside the container, excluding admin ports
EXPOSE 3200 55500 50110 50240 50220 50160 51100 50120 50210 50130 50140 50400 50300

ADD ./build_libraries.sh ./build_and_start_apps.sh ./check_apps.sh ./lib.sh ./
CMD ./build_libraries.sh && ./build_and_start_apps.sh
