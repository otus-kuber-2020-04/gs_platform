FROM python:3.7-alpine

WORKDIR /usr/src/web

COPY . .
RUN pip install --no-cache-dir -r requirements.txt &&\
    chmod -R 777 /usr/src/web/

USER 1001
EXPOSE 8000

ENV SERVER_FOLDER="/usr/src/web/app"
CMD [ "python", "http-server.py" ]