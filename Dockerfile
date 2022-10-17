FROM python:3

COPY front-end /usr/src/app/front-end
COPY scripts /opt

RUN sed -i 's/\r$//' /opt/init.sh  && chmod +x /opt/init.sh
RUN chmod +x /usr/src/app/front-end/public/serve.py

ENV GID 1000
ENV UID 1000

EXPOSE 8000

#CMD ["python3 ./front-end/public/serve.py"]
CMD ["/bin/bash", "-c", "/opt/init.sh"]