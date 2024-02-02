# iac-docker-adm-glrunner-k1

## LXC server

Init container from base image

    lxc init images:debian/bullseye container-adm-glrunner-k1

Network configuration

    lxc config device override container-adm-glrunner-k1 eth0
    lxc config device set container-adm-glrunner-k1 eth0 ipv4.address 10.0.1.130

Start & enter the container

    lxc start container-adm-glrunner-k1
    lxc exec container-adm-glrunner-k1 -- /bin/bash

## Inside

Basic toolkit

    apt update && apt install -y vim curl wget htop openssh-server gnupg2 netcat lsb-release git

Add ssh key

    mkdir -p $HOME/.ssh
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDz+bA5VtpymU3cwqd1yrbsLNAzEdP5c+IVgb/OHlEzhLj7+ZOlWgWEFkoTTRJO3R1nU19yeMSKyAqG6xU+PWt8zlipgGfINuD168oytTM8UOmX16VZaAoUHFwAB+C7Xd814Os2FB7iXeolQVNRZADWUOF7/XOQVjEpbGVM5InoCvPTWPY9cFgRxJ2qwPZ08f0P6NupymK83LJYj9ELYlMfErxBF2WVObysw9c82oXq1VDLq+/clctVq+EhPkIhdRD1BIqNybQQnfvYnC1jfjHBSGIAfXtvJsjZ8TsHqFyXqOFYkj36/ZZ5GPBpIOsN1JA6NfF080g0Cz3iJohmjZh3 kristoa@telephus" > $HOME/.ssh/authorized_keys

[Optional] If ~/.bash_profile does not exist

    cp /etc/skel/.profile ~/.bash_profile

Append to ~/.bashrc

    if [ -f ~/.glrunnerrc ]; then
    . ~/.glrunnerrc
    fi

Append to ~/.glrunnerrc

    export KUBECONFIG=/root/.kube/kubeconfig

Test your profile

    source ~/.bashrc
    echo $KUBECONFIG

Install K8S admin tools

    git clone https://devops:PJ_4tsyYyWDMTtAZKsDz@gitlab.adm.acme.corp/gitlab/studiofrancium/k8s-linux-amd64-bin.git /opt/k-tools-linux-amd64

Append to ~/.bash_profile

    export KUBE_TOOLS_HOME="/opt/k8s-tools-linux-amd64"
    PATH=$KUBE_TOOLS_HOME/bin:$PATH

Test your K8s binaries

    source ~/.bash_profile
    kubectl version

Check the cluster status

    root@container-adm-glrunner-k1:~# kubestatus 
    k8s-status: context=default, namespace=ciam
    
    NAMESPACE              NAME                                               READY   STATUS      RESTARTS   AGE
    kube-system            helm-install-traefik-7mlqw                         0/1     Completed   0          55d
    metallb-system         controller-6b78bff7d9-kd77c                        1/1     Running     0          32d
    metallb-system         speaker-8f66m                                      1/1     Running     0          32d
    metallb-system         speaker-gc2fc                                      1/1     Running     0          32d
    kubernetes-dashboard   dashboard-metrics-scraper-79c5968bdc-lxhfr         1/1     Running     0          32d
    kube-system            cmp-ingress-nginx-controller-7b8b967f59-dncbl      1/1     Running     0          13d
    kube-system            metrics-server-86cbb8457f-2pmg5                    1/1     Running     0          55d
    kubernetes-dashboard   kubernetes-dashboard-7767bc456c-5c8wk              1/1     Running     0          32d
    kube-system            local-path-provisioner-5ff76fc89d-t87dg            1/1     Running     0          55d
    cert-manager           cert-manager-5d7f97b46d-w9brt                      1/1     Running     0          41m
    cert-manager           cert-manager-webhook-8d7495f4-s7cm2                1/1     Running     0          41m
    cert-manager           cert-manager-cainjector-69d885bf55-csr5s           1/1     Running     0          41m
    secret-agent-system    secret-agent-controller-manager-694f9dbf65-jlrjw   1/1     Running     0          50d
    kube-system            coredns-854c77959c-9rsk9                           1/1     Running     0          55d
    root@container-adm-glrunner-k1:~#

### Install cert-manager
[Medium](https://medium.com/@CarlosJuanGP/help-with-certmanager-on-k8s-444db0e1e877)

Create the namespace for cert-manager:

    kubectl create namespace cert-manager

Add the Jetstack Helm repository:

    helm repo add jetstack https://charts.jetstack.io

Update your local Helm chart repository cache:

    helm repo update

Cert-manager requires a number of CRD resources to be installed into your cluster as part of installation.
This can either be done manually, using kubectl, or using the installCRDs option when installing the Helm chart.

To install the cert-manager Helm chart:

    helm install \
      cert-manager jetstack/cert-manager \
      --namespace cert-manager \
      --create-namespace \
      --version v1.4.0 \
      --set installCRDs=true

Once you’ve installed cert-manager, you can verify it is deployed correctly by checking the cert-manager namespace for running pods:

    kubectl get pods --namespace cert-manager

You should see the cert-manager, cert-manager-cainjector, and cert-manager-webhook pod in a Running state. It may take a minute or so for the TLS assets required for the webhook to function to be provisioned. This may cause the webhook to take a while longer to start for the first time than other pods.

#### Test Issuer Configuration
[docds](https://cert-manager.io/docs/installation/kubernetes/#configuring-your-first-issuer)

The following steps will confirm that cert-manager is set up correctly and able to issue basic certificate types.
Create an Issuer to test the webhook works okay.

    cat > /tmp/test-resources.yaml << EOF
    apiVersion: v1
    kind: Namespace
    metadata:
      name: cert-manager-test
    ---
    apiVersion: cert-manager.io/v1
    kind: Issuer
    metadata:
      name: test-selfsigned
      namespace: cert-manager-test
    spec:
      selfSigned: {}
    ---
    apiVersion: cert-manager.io/v1
    kind: Certificate
    metadata:
      name: selfsigned-cert
      namespace: cert-manager-test
    spec:
      dnsNames:
        - example.com
      secretName: selfsigned-cert-tls
      issuerRef:
        name: test-selfsigned
    EOF

Create the test resources.

    kubectl apply -f /tmp/test-resources.yaml

Check the status of the newly created certificate. You may need to wait a few seconds before cert-manager processes the certificate request.

    kubectl describe certificate -n cert-manager-test

Clean up the test resources.

    kubectl delete -f /tmp/test-resources.yaml

### Install GitLab Runner

[Runner install documentation](https://docs.gitlab.com/runner/install/linux-repository.html)

Add the official GitLab repository

    curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | bash

Disable skel & install

    export GITLAB_RUNNER_DISABLE_SKEL=true; apt-get install gitlab-runner -y

### Deploy the Kubernetes Web UI (Dashboard)

Dashboard is a web-based Kubernetes user interface. You can use Dashboard to deploy containerized applications to a
Kubernetes cluster, troubleshoot your containerized application, and manage the cluster resources. You can use Dashboard
to get an overview of applications running on your cluster, as well as for creating or modifying individual Kubernetes
resources (such as Deployments, Jobs, DaemonSets, etc).

    kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml

### Create dashboard admin user

The Kubernetes dashboard supports a few ways to manage access control. We’ll create an admin user account with full
privileges to modify the cluster and use tokens.

    cat << EOF > /tmp/dashboard-admin.yaml    
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: admin-user
      namespace: kubernetes-dashboard
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: admin-user
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: cluster-admin
    subjects:
    - kind: ServiceAccount
      name: admin-user
      namespace: kubernetes-dashboard
    EOF

Then deploy the admin user role

    kubectl apply -f /tmp/dashboard-admin.yaml

Using this method doesn’t require setting up or memorising passwords, instead, accessing the dashboard will require a
token. Get the admin token using the command below.

    kubectl get secret -n kubernetes-dashboard $(kubectl get serviceaccount admin-user -n kubernetes-dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode

You’ll then see a token like in the example below

    eyJhbGciOiJSUzI1NiIsImtpZCI6IlU1T0otbWM3LWJlNlRua0Z5Rmh5dUp5eXlQT2d1SXZjeGhKYVd3UjJCY2sifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlcm5ldGVzLWRhc2hib2FyZCIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJhZG1pbi11c2VyLXRva2VuLWNrenZnIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6ImFkbWluLXVzZXIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiJmNTg0YzJmOS04OWYyLTRhMTUtYmRkOS1hNjdhODY4YjZlYjIiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZXJuZXRlcy1kYXNoYm9hcmQ6YWRtaW4tdXNlciJ9.fzFpgbcJkbH7mv4XMnc8RjJOWAfbGxXtXmer50_y0rQukKF-oVz62XcyY59bD4dPn9W5MkdzzctbwsTi8PHpPMK5_j_SbGRqnrGC4_SLsNWQQ8QWJi5t0oUHLgS06L8i01mAtIkn3q7UUB5X7MPoAKVg2rBrTiCOwUk7DAVc7pwVdTS3iCV1ywVM02tIjG7zHomLbpuJ97AvxBRi9a9kcTZKkEWceGCXuelo5SNyVyG0MJ3MSmrEvu-Nh2wJugwsKdIG8_PwLcskvHaq0o9epE0IU_N7O491R-PV56Sy0r_7UXRfJQpARKUIT2hCy2u7YFiewhUV6_Xci_lFvOFy0A

The token is created each time the dashboard is deployed and is required to log into the dashboard. Note that the token
will change if the dashboard is stopped and redeployed.

### Create dashboard read-only user

Provide read-only access to your Kubernetes cluster

    cat << EOF > /tmp/dashboard-read-only.yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: read-only-user
      namespace: kubernetes-dashboard
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      annotations:
        rbac.authorization.kubernetes.io/autoupdate: "true"
      labels:
      name: read-only-clusterrole
      namespace: default
    rules:
    - apiGroups:
      - ""
      resources: ["*"]
      verbs:
      - get
      - list
      - watch
    - apiGroups:
      - extensions
      resources: ["*"]
      verbs:
      - get
      - list
      - watch
    - apiGroups:
      - apps
      resources: ["*"]
      verbs:
      - get
      - list
      - watch
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: read-only-binding
    roleRef:
      kind: ClusterRole
      name: read-only-clusterrole
      apiGroup: rbac.authorization.k8s.io
    subjects:
    - kind: ServiceAccount
      name: read-only-user
      namespace: kubernetes-dashboard
    EOF

Deploy the read-only user

    kubectl apply -f /tmp/dashboard-read-only.yaml

Create read-only user token

    kubectl get secret -n kubernetes-dashboard $(kubectl get serviceaccount read-only-user -n kubernetes-dashboard -o jsonpath="{.secrets[0].name}") -o jsonpath="{.data.token}" | base64 --decode

### Accessing the dashboard

Create a proxy service to the localhost

    kubectl proxy

Now, assuming that the SSH tunnel binding to the localhost port 8001 works, 
open in browser: [dashboard](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/)

### Reverse proxy

Create base64 of tls files like so:

    cat /mnt/priv/franciumc/telephus-pki/self-signed/_.acme.com/_.acme.com.cer  | base64 -w0

Then

    cat << EOF > /tmp/secret-tls-wildcard.yaml
    apiVersion: v1
    kind: Secret
    metadata:
        name: secret-tls-wildcard
        namespace: kubernetes-dashboard
        labels:
            strategy: "SelfSigned"
    type: kubernetes.io/tls
    data:
        tls.crt: |-
            LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUVvekNDQTR1Z0F3SUJBZ0lFWUkwZ0pUQU5CZ2txaGtpRzl3MEJBUXNGQURCQ01Rc3dDUVlEVlFRR0V3SkYKUlRFWU1CWUdBMVVFQ2d3UFUzUjFaR2x2SUVaeVlXNWphWFZ0TVJrd0Z3WURWUVFEREJCSlFVMGdRMEVnUVhWMAphRzl5YVhSNU1CNFhEVEl4TURVd01UQTVNekl5TVZvWERUTXhNRFV3TVRBNU16SXlNVm93UkRFTE1Ba0dBMVVFCkJoTUNSVVV4R0RBV0JnTlZCQW9NRDFOMGRXUnBieUJHY21GdVkybDFiVEViTUJrR0ExVUVBd3dTVjI5c1lXNWsKSUVSbGRtVnNiM0J0Wlc1ME1JSUJJakFOQmdrcWhraUc5dzBCQVFFRkFBT0NBUThBTUlJQkNnS0NBUUVBcmNsbApVY2RBSVVSdFI2ZExnMFhrVTcwaTY4S0NNL203RXdUWHJWVW9nRXhhQzNwTURKVUoxcVJVTTM2OVhybWIzZzdpCm90amNnekc4MzlmRk4xempYQlBtMVZmaUpqNUl6V3NlTWJxMWNKQ0ZhbnhhT29YM2xwSE1pdVUramo1STVmc1EKOUM2WTBETHFnTE5LdlNyeElPYk5ET2g2KzBTMzMvWERxK1kyVDEzL0ZFQmE1Sm1jZzlXU3g5ZkVCejc1OG82aApSV0tiKy9YSmJzbVh2RmxmbUxMT2ovRFg2MXNsSHNFOXh0QVZsbkdxNWpuRyt4Q2FGNFdJMWtEREFHTTd2TnFuCjVSZVpMd25DL1EwblVjVkZDOTFvd2FtMmo5TDlqSzJJRlBiLy9EZmRHWU0xb0dXTmwyaGk4ZTFFemRxdHdBaTUKOWZhck8wcUloNURyeS9SdVl3SURBUUFCbzRJQm5UQ0NBWmt3Z2VjR0ExVWRFUVNCM3pDQjNJSVFLaTVrWlhZdQpkMjlzWVc1a0xteGhib0lRS2k1a1pYWXVkMjlzWVc1a0xtOXlaNElOS2k1bGVHRnRjR3hsTG1OdmJZSVFLaTV3CmNtUXVkMjlzWVc1a0xteGhib0lRS2k1d2NtUXVkMjlzWVc1a0xtOXlaNElRS2k1emJtSXVkMjlzWVc1a0xteGgKYm9JUUtpNXpibUl1ZDI5c1lXNWtMbTl5WjRJUUtpNXpkR2N1ZDI5c1lXNWtMbXhoYm9JUUtpNXpkR2N1ZDI5cwpZVzVrTG05eVo0SVFLaTUwYzNRdWQyOXNZVzVrTG14aGJvSVFLaTUwYzNRdWQyOXNZVzVrTG05eVo0SU1LaTUzCmIyeGhibVF1YjNKbmdnbHNiMk5oYkdodmMzUXdDUVlEVlIwVEJBSXdBREFmQmdOVkhTTUVHREFXZ0JUeEJpcFIKRFdYU1JYN2pxTDJXS0M4TkYwdWZwREFkQmdOVkhRNEVGZ1FVaDVUalBwNERkcnJLMGJKVDFxUFU1VUJDZ3EwdwpWUVlEVlIwbEJFNHdUQVlJS3dZQkJRVUhBd0VHQ0NzR0FRVUZCd01DQmdnckJnRUZCUWNEQXdZS0t3WUJCQUdDCk53b0REQVlHQkFDUk53TUFCZ2dyQmdFRkJRY0RCd1lJS3dZQkJRVUhBd2dHQkZVZEpRQXdDd1lEVlIwUEJBUUQKQWdPNE1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQlg4OXdJZVNCYUNGeWdCMFlsNDZObXFvM3lCQzFyL0VhUApRTUh6UVRuMzIxN200Q2dLbTE0anduZU1MVDBGdDV5bDBsY2tqVGtMR1Q4d0IzZjBEdGtOVmdlOENuVEJEMTZ6CmtqSUZIbTk5b0pNZWRCRHpPbnFTT1B6UGRjOFNFczRrdGVpelZnMjZwaUNiYkxsL0RjTHNxZmUxdVlaSEV4MUgKRWFBcUpLZFNkVlNwQVZSYnpkYy96aTZRZ2lqUStFU2I1ZUxHVmR2M21OSmRSUHRHK3BldDlhbVZzZFJWa3VrVQoyK1JrZ1dDelBuckppMmg2ZjdsMzZoOTVXenJ5MlVPb0tPclkxZ0dkRndXRURRT0hYOGhkVXRySGprRHl4ekpNCjhxM1F0dHFWc2JGYVN2dThDd0FoWFBudUl4ZkUvaUw3TnZmeTBIWG44TXZpR0kxcFcraHoKLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
        tls.key: |-
            LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBcmNsbFVjZEFJVVJ0UjZkTGcwWGtVNzBpNjhLQ00vbTdFd1RYclZVb2dFeGFDM3BNCkRKVUoxcVJVTTM2OVhybWIzZzdpb3RqY2d6RzgzOWZGTjF6alhCUG0xVmZpSmo1SXpXc2VNYnExY0pDRmFueGEKT29YM2xwSE1pdVUramo1STVmc1E5QzZZMERMcWdMTkt2U3J4SU9iTkRPaDYrMFMzMy9YRHErWTJUMTMvRkVCYQo1Sm1jZzlXU3g5ZkVCejc1OG82aFJXS2IrL1hKYnNtWHZGbGZtTExPai9EWDYxc2xIc0U5eHRBVmxuR3E1am5HCit4Q2FGNFdJMWtEREFHTTd2TnFuNVJlWkx3bkMvUTBuVWNWRkM5MW93YW0yajlMOWpLMklGUGIvL0RmZEdZTTEKb0dXTmwyaGk4ZTFFemRxdHdBaTU5ZmFyTzBxSWg1RHJ5L1J1WXdJREFRQUJBb0lCQUN1anZCNmFBeitYV0QyNwpBOXBXRGF6OWZLeHBMcHJ3cGdwemw5azkzaXJCZ1ljS1VkaURBSEoyMTNJSzdIREIrU0w4NStwdXZJanhUM1dDClVGTERyNUFxcXpkOWx4dDFYb0MrMmxrd2dtbGUwVEhaUWlzYUF2ODdZM3FwY0ZqMXlRWi9VbFdPOGU2dUtuYmgKRHU2THZ2czlHZGFZOW5Ec1k2UUlxZmNibXgyNG1ZckRHMEJmTkE4NjhiR21nYS90NDlDcHR1NGl0TzJaSUU3TApwWEVpODZabURLRmhYTi9hRzlJQ3dkdnJSMS9tMSt3QVJhbkNyeCtSSnRxWXVmL3dYT1U5MHNWNTBOSHdBbkFKCjRCVTRVN2hZaWdWUEIrVVE4UkJzUnM1UjdkR1diZU9xQWYxYmxkeENZTTJoRVlIM056ZVVkQXJ5SHdhQzNOeHoKQzNOTXVIa0NnWUVBNVlJK2FINmJVVTVFTEk5T3NoVHZTMDB1Rmd0S0xJZXlFY0hJWVpHV0dFVEc1SDA5eE44VgphOWd1SWZQci9wdUUrMTNaK3FYQ0MvaysxQ0h3KytDbjNyZTFJS2s2eldlSTF3eFRtSDhJVmIyODR5SVVEVTJECmdIdm1EMGh1YkF3eDE1RU5kd2N3TmtybXRNdC9BU0pqWTRzOFNoTlBFWEJFcXNYcnViaWFrcFVDZ1lFQXdkaWUKejJ2NXBzZGpEMkUxMzM0ZDZIRTk1R0VCZ1ZxZ3ZmSXFnaDBCWlZSTXI1T3o5UVdwVlBpQjJBbUJQbzBSSHE0Mwoyend0MCttcG5qTDg5ekk4emduUlV6bjhsbFZ6c1ljb3Q0dm9GbEx1QWNhVStUcTAwUGVlemtTb250V0hRRGtrCm9JSVJiMkdvbVlIeVpHbjdGeVBkRW11cXFtbUpnaHp0ZEE2MmR4Y0NnWUVBa1UrVFgrbTVRUk5DeXN1NVViczcKZnZ2UTBCZzUwRlBpQktnaXpOTzJxb3J4T3IycEhEcjZmeHVTcWVDY2JNbmV1cUJEWVJVTjlUTEwrdGU2a2w4OQpLaUE2U0FHZHYydHNFbXcxaVhuMHR3UzQwVDVFWDkvU0FNbHhjZiswR2lqbWJjdmpNSmVXaU9tSGhMVExKdGExCkF0T25TbWRMU29sQWtMZGJkbTFSUUxrQ2dZQVprNEpJcmQ5dnNPa1NFMnB2UlkyZXFLcFk0cSszS0lVQzZ0dk8KOVJMRkV0MVhZUzZpU28vd0JTWGtva1JxUTJTWjNyVEIrV3UyaFNMN0c1RWk4SDd6VkhwSTkrS3ExelYvbSt5MApZd0pKUjhIZGZCMFYwVGdnUmp1dXpZSk9DckJndWVscVFCOGF5aERieURoNkpUMmE3UUZ6Tjc5NTRwamhFUDRICmpSVm9Hd0tCZ0RIc1VyejdtUUh3MGlYYTF1bis2QWJONmUvRWdEdy9WaDh2RW9XZmc2V2Y2U29NRWF0Yyt3NHkKUE8wV241eTljS2JtbDBrYWZxODJaek9QUXdCTmJJYlRUMzlHQnpqSnhjSms1Ym9CNGFYWEtIRGFQamh4TjR1Swp3M3FzSDNPTW1BN3FVOVRRRE9lcE5zb1JEeDVaQ3VoTFpoYTJiL25DcGZQR3JNOUlLMEhHCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
    EOF

Apply

    kubectl apply -f /tmp/secret-tls-wildcard.yaml

Ingress

    cat << EOF > /tmp/dashboard-ingress.yaml
    apiVersion: extensions/v1beta1
    kind: Ingress
    metadata:
      name: dashboard
      namespace: kubernetes-dashboard
      annotations:
        kubernetes.io/ingress.class: nginx
    spec:
      rules:
        - host: dashboard.dev.acme.corp
          http:
            paths:
              - path: /
                backend:
                  serviceName: kubernetes-dashboard
                  servicePort: 80
      tls:
        - hosts:
            - dashboard.dev.acme.corp
          secretName: secret-tls-wildcard
    EOF

Apply

    kubectl apply -f /tmp/dashboard-ingress.yaml


### Raw

    lxc file pull container-k3s-m1/tmp/kubeconfig.local /tmp/kubeconfig.local
    lxc exec container-adm-glrunner-k2 -- bash -c 'mkdir -p /home/gitlab-runner/.kube'
    lxc file push kube_config.yml container-adm-glrunner-k2/home/gitlab-runner/.kube/config
    lxc exec container-adm-glrunner-k2 -- bash -c 'chown gitlab-runner: /home/gitlab-runner/.kube'
    
    chmod go-r ~/.kube/config
    
Then
    
    lxc exec container-adm-glrunner-k2 -- /bin/bash
    kubectl get pods --all-namespaces

## Test private repo

    crictl pull --creds nx-docker-private-read:changeit nexus.adm.acme.corp:18443/iam/i18n-api:latest

https://media.defense.gov/2021/Aug/03/2002820425/-1/-1/1/CTR_KUBERNETES%20HARDENING%20GUIDANCE.PDF
