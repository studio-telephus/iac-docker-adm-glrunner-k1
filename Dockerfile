FROM gitlab/gitlab-runner:ubuntu-v16.8.0

COPY ./filesystem /.
COPY ./filesystem-shared-ca-certificates /.

ARG _GITLAB_ADDRESS
ENV GITLAB_ADDRESS=${_GITLAB_ADDRESS}

ARG _GITLAB_RUNNER_REGISTRATION_KEY
ENV GITLAB_RUNNER_REGISTRATION_KEY=${_GITLAB_RUNNER_REGISTRATION_KEY}

RUN bash /mnt/pre-install.sh
RUN bash /mnt/setup-ca.sh
RUN bash /mnt/install.sh

EXPOSE 22
