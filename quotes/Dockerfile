FROM clojure:lein-2.9.10
WORKDIR /usr/src/app
COPY . .

RUN make libs
RUN make clean all

ENV APP_PORT 6000

EXPOSE 6000

CMD ["java", "-jar", "/usr/src/app/build/quotes.jar"]