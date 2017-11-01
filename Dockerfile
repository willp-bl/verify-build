FROM openjdk:8-jdk

ADD build_msa.sh .
ADD build_vsp.sh .

CMD ./build_vsp.sh && ./build_msa.sh
