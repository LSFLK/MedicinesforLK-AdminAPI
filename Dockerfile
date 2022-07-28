from ballerina/ballerina:latest

COPY . /app
WORKDIR /app
RUN mkdir /home/ballerina/.ballerina

EXPOSE 9090

ENTRYPOINT ["bal", "run"]
