# syntax=docker/dockerfile:1
# Status: Beta
# GA updates: https://github.com/awsdocs/aws-doc-sdk-examples/issues/4128
FROM maven:latest
COPY . /javav2/
RUN cd /javav2/example_code/cloudwatch && \
    mvn package -Dmaven.spec.skip
CMD ["bash"]
