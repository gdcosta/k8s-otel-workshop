#!/bin/bash

#
# Foundational Workshop #1 Tasks - Linux Ubuntu 
#
# The following script sets all components for a kubernetes | otel workshop and sets up
# participants to start running Foundational Workshop #2
#
# author:  Gerry D'Costa
# title:   Staff Solutions Engineer, Splunk
#
# version: 1.0.0
#
# What this script does:
#  - Foundational Workshop #1
#      - sets up all environment variables - public_ip, hostname, etc
#      - downloads | installs minikube
#      - downloads | installs kubectl
#      - configures docker for the splunk user
#      - downloads | build | containerizes the petclinic java application
#

#
# setup - environment variable setup
#
date_string="$(date)"
echo -n "** $date_string - FW#1 step - os: set our workshop variables"
echo "** $date_string - FW#1 step - os: set our workshop variables" >> ~/debug.txt
export AMI_INDEX="$(hostname | sed -e "s/k8host//g;")"
export WS_USER=$(echo "user$AMI_INDEX")
export PUBLIC_IP=$(ec2metadata --public-ipv4)
sleep 1
echo " .... done"

# make sure we are in our home directory
date_string="$(date)"
echo -n "** $date_string - FW#1 step - os: change to home directory"
echo "** $date_string - FW#1 step - os: change to home directory" >> ~/debug.txt
cd ~/; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# # download minikube executable
# date_string="$(date)"
# echo -n "** $date_string - FW#1 step - minikube: download binary"
# result="$(wget https://github.com/kubernetes/minikube/releases/download/v1.29.0/minikube-linux-amd64 2>&1 | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
# if [ $result = 200 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # change permissions and move to /usr/local/bin
# date_string="$(date)"
# echo -n "** $date_string - FW#1 step - minkube: change permissions - move to /usr/local/bin"
# chmod 755 ./minikube-linux-amd64; sleep 1
# sudo mv ./minikube-linux-amd64 /usr/local/bin/minikube; sleep 1
# sudo chown splunk:splunk /usr/local/bin/minikube; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi

# # download kubectl executable
# date_string="$(date)"
# echo -n "** $date_string - FW#1 step - kubectl: download binary"
# result="$(curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl 2>&1 | tail -1 | sed -e 's/\r/\n/g;' | tail -1 | awk '{print $3}')"
# if [ $result = 100 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # change permissions and move to /usr/local/bin
# date_string="$(date)"
# echo -n "** $date_string - FW#1 step - kubectl: change permissions - move to /usr/local/bin"
# chmod 755 ./kubectl; sleep 1
# sudo mv ./kubectl /usr/local/bin/kubectl; sleep 1
# sudo chown splunk:splunk /usr/local/bin/kubectl; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi

# add docker group
date_string="$(date)"
echo -n "** $date_string - FW#1 step - docker: add docker group - "
echo "** $date_string - FW#1 step - docker: add docker group - " >> ~/debug.txt
result="$(sudo groupadd docker &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(sudo cat /tmp/k8s_output.txt | sed -e 's/\n//g;')"; sleep 1
echo -n "$result"
echo " .... done"

# add splunk user to docker group
date_string="$(date)"
echo -n "** $date_string - FW#1 step - docker: add splunk user to docker group - "
echo "** $date_string - FW#1 step - docker: add splunk user to docker group - " >> ~/debug.txt
sudo usermod -aG docker splunk; sleep 1
sudo usermod -aG docker ubuntu; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# add minikube and newgrp docker command in bash .profile
date_string="$(date)"
echo -n "** $date_string - FW#1 step - minikube: add minikube and newgrp docker command in bash .profile"
echo "** $date_string - FW#1 step - minikube: add minikube and newgrp docker command in bash .profile" >> ~/debug.txt
sudo printf "\n# added - splunk k8s workshop: minikube\neval \$(minikube -p minikube docker-env)\n\n# added - splunk k8s workshop: docker\nnewgrp docker\n" | sudo tee --append /home/splunk/.profile &>> ~/debug.txt; sleep 1
echo " .... done"

# create an audit policy for minikube k8s environment
date_string="$(date)"
echo -n "** $date_string - FW#1 step - minikube: create an audit policy for minikube k8s environment"
echo "** $date_string - FW#1 step - minikube: create an audit policy for minikube k8s environment" >> ~/debug.txt
sudo mkdir -p /home/splunk/.minikube/files/etc/ssl/certs
sudo tee /home/splunk/.minikube/files/etc/ssl/certs/audit-policy.yaml <<EOF >> ~/debug.txt
# Log all requests at the Metadata level.
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
EOF
sleep 1
sudo chown -R splunk:docker /home/splunk/.minikube; sleep 1
echo " .... done"

# add minikube hostname in /etc/hosts file
date_string="$(date)"
echo -n "** $date_string - FW#1 step - minikube: add minikube hostname in /etc/hosts file"
echo "** $date_string - FW#1 step - minikube: add minikube hostname in /etc/hosts file" >> ~/debug.txt
echo -e "192.168.49.2\tminikube" | sudo tee --append /etc/hosts &>> ~/debug.txt; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# create the k8s_workshop and petclinic app directories
date_string="$(date)"
echo -n "** $date_string - FW#1 step - petclinic: create the k8s_workshop and petclinic app directories"
echo "** $date_string - FW#1 step - petclinic: create the k8s_workshop and petclinic app directories" >> ~/debug.txt
mkdir -p ~/k8s_workshop/petclinic; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# download petclinic source from github
date_string="$(date)"
echo -n "** $date_string - FW#1 step - petclinic: download petclinic source from github"
echo "** $date_string - FW#1 step - petclinic: download petclinic source from github" >> ~/debug.txt
result="$(git -C ~/k8s_workshop/petclinic clone --branch springboot3 https://github.com/spring-projects/spring-petclinic.git &>> ~/debug.txt)"
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# use MAVEN to build a new petclinic package
date_string="$(date)"
echo -n "** $date_string - FW#1 step - petclinic: use MAVEN to build a new petclinic package"
echo "** $date_string - FW#1 step - petclinic: use MAVEN to build a new petclinic package" >> ~/debug.txt
cd ~/k8s_workshop/petclinic/spring-petclinic
result="$(./mvnw package &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "BUILD SUCCESS" | awk '{print $3}')"; sleep 1
if [ $result = "SUCCESS" ]; then
echo " .... done"
else
echo " .... failed"
fi

# create dockerfile in petclinic target directory
date_string="$(date)"
echo -n "** $date_string - FW#1 step - petclinic: create dockerfile in petclinic target directory"
echo "** $date_string - FW#1 step - petclinic: create dockerfile in petclinic target directory" >> ~/debug.txt
sudo tee ~/k8s_workshop/petclinic/spring-petclinic/target/Dockerfile <<EOF >> ~/debug.txt
# syntax=docker/dockerfile:1

FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

COPY * ./

CMD ["java", "-jar", "spring-petclinic-3.0.0-SNAPSHOT.jar"]
EOF
sleep 1
sudo chown -R ubuntu:docker ~/k8s_workshop; sleep 1
echo " .... done"

# copy the k8s_workshop and petclinic directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - FW#1 step - petclinic: copy the k8s_workshop and petclinic directory to the splunk user"
echo "** $date_string - FW#1 step - petclinic: copy the k8s_workshop and petclinic directory to the splunk user" >> ~/debug.txt
sudo cp -rf ~/k8s_workshop /home/splunk; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi

# pause for 1 minute(s) before minikube start
date_string="$(date)"
echo -n "** $date_string - FW#1 step - minikube: pause for 1 minute(s) before minikube start"
echo "** $date_string - FW#1 step - minikube: pause for 1 minute(s) before minikube start" >> ~/debug.txt
sleep 60
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# start minikube as the splunk user
date_string="$(date)"
echo -n "** $date_string - FW#1 step - minikube: start minikube as the splunk user"; sleep 2
echo "** $date_string - FW#1 step - minikube: start minikube as the splunk user" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "minikube start --no-vtx-check --driver=docker --subnet=192.168.49.0/24 --extra-config=apiserver.audit-policy-file=/etc/ssl/certs/audit-policy.yaml --extra-config=apiserver.audit-log-path=-" &> /tmp/k8s_output.txt)"; sleep 2
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "Done" | awk '{print $2}')"; sleep 1
if [ $result = "Done!" ]; then
echo " .... done"
else
echo " .... failed"
fi

# pause for 30 second(s) after minikube start
date_string="$(date)"
echo -n "** $date_string - FW#1 step - minikube: pause for 30 second(s) after minikube start"
echo "** $date_string - FW#1 step - minikube: pause for 30 second(s) after minikube start" >> ~/debug.txt
sleep 30
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# Install a new cert manager for HELM
date_string="$(date)"
echo -n "** $date_string - FW#1 step - minikube: Install a new cert manager for HELM"
echo "** $date_string - FW#1 step - minikube: Install a new cert manager for HELM" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | tail -1 | awk '{print $2}')"; sleep 1
if [ $result = "created" ] || [ $result = "configured" ]; then
echo " .... done"
else
echo " .... failed"
fi

# pause for 30 second(s) after cert manager install
date_string="$(date)"
echo -n "** $date_string - FW#1 step - minikube: pause for 30 second(s) after cert manager install"
echo "** $date_string - FW#1 step - minikube: pause for 30 second(s) after cert manager install" >> ~/debug.txt
sleep 30
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# build the petclinic docker image into the minikube docker registry
date_string="$(date)"
echo -n "** $date_string - FW#1 step - petclinic: build the petclinic docker image into the minikube docker registry"
echo "** $date_string - FW#1 step - petclinic: build the petclinic docker image into the minikube docker registry" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); cd ~/k8s_workshop/petclinic/spring-petclinic/target; docker build --tag $WS_USER/petclinic-otel:v1 ." &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "Successfully built" | awk '{print $2}')"; sleep 1
if [ $result = "built" ]; then
echo " .... done"
else
echo " .... failed"
fi

# create the petclinic k8s_deploy directories
date_string="$(date)"
echo -n "** $date_string - FW#1 step - petclinic: create the petclinic k8s_deploy directories"
echo "** $date_string - FW#1 step - petclinic: create the petclinic k8s_deploy directories" >> ~/debug.txt
mkdir -p ~/k8s_workshop/petclinic/k8s_deploy; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# create the manifest file used to deploy the petclinic app into kubernetes
date_string="$(date)"
echo -n "** $date_string - FW#1 step - petclinic: create the manifest file used to deploy the petclinic app into kubernetes"
echo "** $date_string - FW#1 step - petclinic: create the manifest file used to deploy the petclinic app into kubernetes" >> ~/debug.txt
sudo tee ~/k8s_workshop/petclinic/k8s_deploy/$WS_USER-petclinic-k8s-manifest.yml <<EOF >> ~/debug.txt
apiVersion: v1
kind: Service
metadata:
  name: $WS_USER-petclinic-srv
spec:
  selector:
    app: $WS_USER-petclinic-otel-app
  ports:
  - protocol: TCP
    port: 8080
    nodePort: 30000
  type: NodePort
---
apiVersion: apps/v1
kind: Deployment
metadata:
   name: $WS_USER-petclinic-otel-deployment
   labels:
      app: $WS_USER-petclinic-otel-app
spec:
  selector:
    matchLabels:
      app: $WS_USER-petclinic-otel-app
  template:
    metadata:
      labels:
        app: $WS_USER-petclinic-otel-app
    spec:
      containers:
      - name: $WS_USER-petclinic-otel-container01
        image: $WS_USER/petclinic-otel:v1
        ports:
        - containerPort: 8080
EOF
sleep 1
sudo chown -R ubuntu:docker ~/k8s_workshop; sleep 1
echo " .... done"

# copy the petclinic k8s deployment directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - FW#1 step - petclinic: copy the petclinic k8s deployment directory to the splunk user"
echo "** $date_string - FW#1 step - petclinic: copy the petclinic k8s deployment directory to the splunk user" >> ~/debug.txt
sudo cp -rf ~/k8s_workshop/petclinic/k8s_deploy /home/splunk/k8s_workshop/petclinic/; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi

# pause for 1 minute(s) to allow petclinic deployment
date_string="$(date)"
echo -n "** $date_string - FW#1 step - patclinic: pause for 1 minute(s) to allow petclinic deployment"
echo "** $date_string - FW#1 step - patclinic: pause for 1 minute(s) to allow petclinic deployment" >> ~/debug.txt
sleep 60
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# deploy the petclinic app as the splunk user
date_string="$(date)"
echo -n "** $date_string - FW#1 step - petclinic: deploy the petclinic app in kubernetes"
echo "** $date_string - FW#1 step - petclinic: deploy the petclinic app in kubernetes" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl apply -f ~/k8s_workshop/petclinic/k8s_deploy/$WS_USER-petclinic-k8s-manifest.yml" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | awk '{print $2}' | tr -d '\n')"; sleep 1
if [ $result = "createdcreated" ] || [ $result = "createdunchanged" ] || [ $result = "unchangedcreated" ] || [ $result = "unchangedunchanged" ]; then
echo " .... done"
else
echo " .... failed"
fi
