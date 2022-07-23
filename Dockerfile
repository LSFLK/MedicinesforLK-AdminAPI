from ballerina/ballerina:latest

COPY . /app
COPY ./config.example.bal /app/config.bal
WORKDIR /app
RUN mkdir /home/ballerina/.ballerina

EXPOSE 8080

ENTRYPOINT ["bal", "run"]