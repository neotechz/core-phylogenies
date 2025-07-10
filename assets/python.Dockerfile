FROM python:3.13

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir pandas==2.2.3 matplotlib==3.10.0 biopython==1.85 scipy==1.16.0

CMD ["cat", "/etc/os-release"]