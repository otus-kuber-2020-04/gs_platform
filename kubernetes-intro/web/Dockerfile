FROM python:3.7-alpine

WORKDIR /usr/src/app

COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

USER 1001
EXPOSE 8000

CMD [ "python", "http-server.py" ]