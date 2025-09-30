FROM ubuntu:latest

COPY entrypoint.sh /entrypoint.sh

RUN apt update && \
    apt install -y ca-certificates git libatomic1 cron curl adb && \
    update-ca-certificates && \
    rm -rf /var/lib/apt/lists/* && \
    chmod +x /entrypoint.sh
    
WORKDIR /root

CMD ["/entrypoint.sh"]
