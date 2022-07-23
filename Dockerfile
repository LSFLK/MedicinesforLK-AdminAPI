from ballerina/ballerina:latest

COPY . /app
WORKDIR /app
RUN mkdir /home/ballerina/.ballerina

EXPOSE 443

ENTRYPOINT ["bal", "run"]
