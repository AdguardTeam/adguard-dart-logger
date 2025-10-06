FROM dart:3.9.4-sdk

ARG ONEPUB_TOKEN
ENV ONEPUB_TOKEN=${ONEPUB_TOKEN}

WORKDIR /app
COPY . .

RUN rm -rf .git && \
    dart pub global activate onepub && \
    onepub import && \
    onepub pub private && \
    dart pub publish --dry-run && \
    dart pub publish -f
