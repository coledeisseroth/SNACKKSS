# SNACKKSS
Automated pipeline to acquire RNA-Seq metadata from the Gene Expression Omnibus, automatically curate potential gene-disruption and drug-treatment studies, and match perturbation signatures to predict regulatory relationships

In order to run this pipeline, you must first acquire (or generate anew) the finalized models trained by the SNACKKSS_NLP pipeline (see the instructions in the "models" directory).

You can build and run a Docker image for this pipeline as follows:
docker build -t snackkss-pipeline .
docker save -o snackkss-pipeline.tar snackkss-pipeline
docker rmi snackkss-pipeline
docker load -i snackkss-pipeline.tar
docker run -v $(pwd)/:/app/ snackkss-pipeline

