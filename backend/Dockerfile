FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN addgroup --system django \
    && adduser --system --ingroup django django

COPY requirements.txt /app/requirements.txt

RUN pip install --upgrade pip \
    && pip install -r /app/requirements.txt

COPY . /app/

RUN sed -i 's/\r$//' /app/entrypoint.sh \
    && chmod +x /app/entrypoint.sh \
    && chown -R django:django /app

USER django

EXPOSE 8000

ENTRYPOINT ["/app/entrypoint.sh"]