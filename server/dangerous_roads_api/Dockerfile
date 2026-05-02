FROM python:3.13.3-alpine

RUN apk add --no-cache \
    build-base \
    gdal-dev \
    geos-dev \
    proj-dev \
    libjpeg-turbo-dev \
    zlib-dev \
    freetype-dev \
    libpng-dev \
    musl-dev \
    linux-headers \
    python3-dev \
    py3-pip \
    py3-setuptools \
    py3-wheel

WORKDIR /app

RUN mkdir sessions

COPY requirements.txt /app
RUN pip install -r requirements.txt
RUN rm requirements.txt

RUN mkdir /app/data
COPY regensburg_dangerous_streets /app/data

COPY geo.py /app
COPY api.py /app
EXPOSE 80

CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:80", "api:app"]