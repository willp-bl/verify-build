FROM openjdk:8-jdk

#RUN apt-get update
#RUN apt-get install golang-cfssl bundler

ADD ./build_libraries.sh .
ADD ./build_and_start_apps.sh .

CMD ./build_libraries.sh && ./build_and_start_apps.sh
