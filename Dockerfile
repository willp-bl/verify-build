FROM openjdk:8-jdk

ADD ./build_libraries.sh .
ADD ./build_and_start_apps.sh .

CMD ./build_libraries.sh && ./build_and_start_apps.sh
