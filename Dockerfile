FROM python:3.10
RUN apt-get update
RUN apt-get install -y wget
WORKDIR /app
RUN pip install transformers[torch]==4.39.3
RUN pip install datasets==2.18.0
RUN pip install torch==2.2.2
RUN pip install evaluate==0.4.3
RUN pip install numpy==1.26.4
RUN pip install biopython==1.85
RUN pip install seqeval==1.2.2
RUN pip install accelerate==0.28.0
COPY docker_setup.sh .

CMD bash docker_setup.sh

