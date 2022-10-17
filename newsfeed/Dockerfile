FROM clojure:lein-2.9.10
WORKDIR /usr/src/app
COPY . .

RUN make libs
RUN make clean all

ENV APP_PORT 6500

EXPOSE 6500

CMD ["java", "-jar", "/usr/src/app/build/newsfeed.jar"]