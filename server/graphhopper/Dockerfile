FROM eclipse-temurin:23-jre-alpine

WORKDIR /graphhopper
COPY graphhopper-web-10.0.jar .

VOLUME ["/data"]
EXPOSE 8989
EXPOSE 8990

CMD java -Ddw.graphhopper.datareader.file=/data/$OSM_FILE -jar graphhopper-web-10.0.jar server /data/config.yml