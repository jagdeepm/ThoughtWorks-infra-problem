FROM clojure:lein-2.9.10
WORKDIR /usr/src/app
COPY . .

RUN make libs
RUN make clean all

ENV APP_PORT 5656
ENV STATIC_URL http://localhost:8000
ENV QUOTE_SERVICE_URL http://localhost:6000
ENV NEWSFEED_SERVICE_URL http://localhost:6500
ENV NEWSFEED_SERVICE_TOKEN 1&eWbYXNWG1w1^YGKDPxAWJ@^et^&kX

EXPOSE 5656

CMD ["java", "-jar", "/usr/src/app/build/front-end.jar"]