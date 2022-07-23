from ballerina/ballerina:latest

COPY . /app
WORKDIR /app
RUN mkdir /home/ballerina/.ballerina

EXPOSE 8080

ENTRYPOINT ["bal", "run"]dock