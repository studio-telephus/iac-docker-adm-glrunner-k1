FROM gitlab/gitlab-runner:ubuntu-v16.8.0

COPY ./filesystem /.
COPY ./filesystem-shared-ca-certificates /.

RUN bash /mnt/pre-install.sh
RUN bash /mnt/setup-ca.sh
RUN bash /mnt/install-tools.sh
