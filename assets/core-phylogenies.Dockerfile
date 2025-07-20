FROM python:3.13

RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir biopython==1.85 scipy==1.16.0 dendropy==5.0.8

CMD ["cat", "/etc/os-release"]