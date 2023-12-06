#!/bin/bash

#
# Foundational Workshop #2 Tasks - Linux Ubuntu 
#
# The following script sets all components for a kubernetes | otel workshop and sets up
# participants to start running Advanced Workshop #1
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
#  - Foundational Workshop #2
#      - downloads | installs | configures HELM
#      - splunk platform - enables | creates a new HEC token
#      - splunk platform - downloads | installs k8s_workshop_app - includes index creation
#      - downloads | configures splunk otel collector 
#          - otel logEngine 
#          - splunk log index
#          - splunk HEC | token configuration
#          - multiline configuration
#          - annotations
#

#
# setup - environment variable setup
#
date_string="$(date)"
echo -n "** $date_string - FW#2 step - os: set our workshop variables"
echo "** $date_string - FW#2 step - os: set our workshop variables" >> ~/debug.txt
export AMI_INDEX="$(hostname | sed -e "s/k8shost//g;")"
export WS_USER=$(echo "user$AMI_INDEX")
export PUBLIC_IP=$(ec2metadata --public-ipv4)
export LOCAL_IP=$(ec2metadata --local-ipv4)
sleep 1
echo " .... done"

# make sure we are in our home directory
date_string="$(date)"
echo -n "** $date_string - FW#2 step - os: change to home directory"
echo "** $date_string - FW#2 step - os: change to home directory" >> ~/debug.txt
cd ~/; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

#
# ----------------
# Dependency: completed execution of setup-for-FW2 script
# 

# start minikube as the splunk user
date_string="$(date)"
echo -n "** $date_string - FW#2 step - minikube: start minikube as the splunk user"
echo "** $date_string - FW#2 step - minikube: start minikube as the splunk user" >> ~/debug.txt
minikubeStatus="$(sudo -H -u splunk bash -c "minikube status" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
minikubeStatus="$(cat /tmp/k8s_output.txt | grep -e "^host" -e "^kubelet" -e "^apiserver" -e "^kubeconfig" | awk '{print $2}' | tr -d '\n')"; sleep 1
if [ $minikubeStatus = "RunningRunningRunningConfigured" ]; then
echo " .... minikube already running ... done"
else
	result="$(sudo -H -u splunk bash -c "minikube start --no-vtx-check --driver=docker --subnet=192.168.49.0/24 --extra-config=apiserver.audit-policy-file=/etc/ssl/certs/audit-policy.yaml --extra-config=apiserver.audit-log-path=-" &> /tmp/k8s_output.txt)"; sleep 1
	cat /tmp/k8s_output.txt >> ~/debug.txt
	result="$(cat /tmp/k8s_output.txt | grep "Done" | awk '{print $2}')"; sleep 1
	if [ $result = "Done!" ]; then
	echo " .... done"
	else
	echo " .... failed"
	fi
fi

# # Install a new cert manager for HELM
# date_string="$(date)"
# echo -n "** $date_string - FW#2 step - helm: Install a new cert manager for HELM"
# result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.1/cert-manager.yaml" 2>&1 | tail -1 | awk '{print $2}')"; sleep 1
# if [ $result = "created" ] || [ $result = "configured" ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
#
# # add a new apt key to Ubuntu to install HELM
# date_string="$(date)"
# echo -n "** $date_string - FW#2 step - helm: add a new apt key and source list to Ubuntu to install HELM"
# result="$(curl https://baltocdn.com/helm/signing.asc 2>&1 | sudo apt-key add - 2> /dev/null | tail -1 | sed -e 's/\r/\n/g;' | tail -1 | awk '{print $1}')"; sleep 1
# if [ $result = "OK" ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # add a new source list to Ubuntu to install HELM
# date_string="$(date)"
# echo -n "** $date_string - FW#2 step - helm: add a new source list to Ubuntu to install HELM"
# echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list > /dev/null 2> /dev/null; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # update ubuntu packages
# date_string="$(date)"
# echo -n "** $date_string - FW#2 step - helm: update ubuntu packages"
# sudo apt-get update > /dev/null 2> /dev/null; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # install HELM
# date_string="$(date)"
# echo -n "** $date_string - FW#2 step - helm: install HELM"
# sudo apt-get install helm -V -y > /dev/null 2> /dev/null; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi














# create the 'splunk_app' directory for the k8s workshop app
date_string="$(date)"
echo -n "** $date_string - FW#2 step - splunk_core: create the 'splunk_app' directory for the k8s workshop app"
echo "** $date_string - FW#2 step - splunk_core: create the 'splunk_app' directory for the k8s workshop app" >> ~/debug.txt
mkdir ~/k8s_workshop/splunk_app; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# download the k8s workshop app from github
date_string="$(date)"
echo -n "** $date_string - FW#2 step - splunk_core: download the k8s workshop app from github"
echo "** $date_string - FW#2 step - splunk_core: download the k8s workshop app from github" >> ~/debug.txt
cd ~/k8s_workshop/splunk_app; sleep 1
result="$(wget https://github.com/gdcosta/k8s_workshop_app/raw/main/k8s_workshop_app.tar.gz &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
if [ $result = 200 ]; then
echo " .... done"
else
echo " .... failed"
fi

# extract the k8s workshop app
date_string="$(date)"
echo -n "** $date_string - FW#2 step - splunk_core: extract the k8s workshop app"
echo "** $date_string - FW#2 step - splunk_core: extract the k8s workshop app" >> ~/debug.txt
cd ~/k8s_workshop/splunk_app; sleep 1
result="$(tar -xzvf ~/k8s_workshop/splunk_app/k8s_workshop_app.tar.gz &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "^tar: Error" | wc -l)"; sleep 1
if [ $result = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi


# update the app.conf file in the k8s workshop app
date_string="$(date)"
echo -n "** $date_string - FW#2 step - splunk_core: update the app.conf file in the k8s workshop app"
echo "** $date_string - FW#2 step - splunk_core: update the app.conf file in the k8s workshop app" >> ~/debug.txt
idValue="$(echo "$WS_USER-_k8s_workshop_app" | sed -e 's/-_k8s_workshop_app/\_k8s_workshop_app/g')"
sudo tee ~/k8s_workshop/splunk_app/k8s_workshop_app/default/app.conf <<EOF >> ~/debug.txt
#
# Splunk app configuration file
#
[default]

[install]
state = enabled

[package]
check_for_updates = false
id = $idValue

[ui]
is_visible = 1
label = $WS_USER - k8s Workshop App

[launcher]
version = 1.0.0
author = $WS_USER
description = Splunk App for k8s workshop knowledge objects

EOF

sleep 1
sudo chown -R ubuntu:docker ~/k8s_workshop; sleep 1
echo " .... done"


# # update the app to reflect the workshop user
# date_string="$(date)"
# echo -n "** $date_string - FW#2 step - splunk_core: update the app to reflect the workshop user"
# cat ~/k8s_workshop/splunk_app/k8s_workshop_app/default/app.conf | sed -e "s/kd - k8s Workshop App/$WS_USER - k8s Workshop App/g;" | sed -e "s/Gerry D\x27Costa/$WS_USER/g;" | sed -e "s/id = k8s_workshop_app/id = $WS_USER-k8s_workshop_app/g;" | sed -e "s/-k8s_workshop_app/_k8s_workshop_app/g;" > ~/k8s_workshop/splunk_app/k8s_workshop_app/default/app.conf.mod; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # update the app to reflect the workshop user - copy over the apps.conf
# date_string="$(date)"
# echo -n "** $date_string - FW#2 step - splunk_core: update the app to reflect the workshop user - copy over the apps.conf"
# mv ~/k8s_workshop/splunk_app/k8s_workshop_app/default/app.conf.mod ~/k8s_workshop/splunk_app/k8s_workshop_app/default/app.conf; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi

# copy the app to the splunk /etc/apps directory
date_string="$(date)"
echo -n "** $date_string - FW#2 step - splunk_core: move the app to the splunk /etc/apps directory"
echo "** $date_string - FW#2 step - splunk_core: move the app to the splunk /etc/apps directory" >> ~/debug.txt
app_name="$(echo $WS_USER-_k8s_workshop_app | sed -e 's/-_k8s_workshop_app/_k8s_workshop_app/g')"
mv ~/k8s_workshop/splunk_app/k8s_workshop_app ~/k8s_workshop/splunk_app/$app_name
sudo cp -rp ~/k8s_workshop/splunk_app/$app_name /opt/splunk/etc/apps; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:splunk /opt/splunk/etc/apps/$app_name; sleep 1
echo " .... done"
else
echo " .... failed"
fi

# remove the k8s workshop tar.gz file
date_string="$(date)"
echo -n "** $date_string - FW#2 step - splunk_core: remove the k8s workshop tar.gz file"
echo "** $date_string - FW#2 step - splunk_core: remove the k8s workshop tar.gz file" >> ~/debug.txt
rm ~/k8s_workshop/splunk_app/k8s_workshop_app.tar.gz; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# copy the k8s_workshop/splunk_app directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - FW#2 step - splunk_core: copy the k8s_workshop/splunk_app directory to the splunk user"
echo "** $date_string - FW#2 step - splunk_core: copy the k8s_workshop/splunk_app directory to the splunk user" >> ~/debug.txt
sudo cp -rf ~/k8s_workshop/splunk_app /home/splunk/k8s_workshop/; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi








# enable HEC in splunk platform
date_string="$(date)"
echo -n "** $date_string - FW#2 step - splunk_core: enable HEC in splunk platform"
echo "** $date_string - FW#2 step - splunk_core: enable HEC in splunk platform" >> ~/debug.txt
sudo mkdir -p /opt/splunk/etc/apps/splunk_httpinput/local; sleep 1
sudo tee /opt/splunk/etc/apps/splunk_httpinput/local/inputs.conf <<EOF >> ~/debug.txt
[http]
disabled = 0
enableSSL = 0
EOF
sleep 1
sudo chown -R splunk:splunk /opt/splunk/etc/apps/splunk_httpinput/local; sleep 1
echo " .... done"


# start the splunk platform to create indexes and register the new app
date_string="$(date)"
echo -n "** $date_string - FW#2 step - splunk_core: start the splunk platform to create indexes and register the new app"
echo "** $date_string - FW#2 step - splunk_core: start the splunk platform to create indexes and register the new app" >> ~/debug.txt
command_str="$(echo '/opt/splunk/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd \!spl8nk*' | sed -e 's/\\\!/\!/g;')"
result="$(sudo -H -u splunk bash -c "$command_str" &> /tmp/k8s_output.txt)"; sleep 5
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "^Waiting for web server" | awk '{print $10}')"; sleep 1
if [ $result = "Done" ]; then
echo " .... done"
else
echo " .... failed"
fi

# create an HTTP event token in splunk platform
date_string="$(date)"
echo -n "** $date_string - FW#2 step - splunk_core: create an HTTP event token in splunk platform"
echo "** $date_string - FW#2 step - splunk_core: create an HTTP event token in splunk platform" >> ~/debug.txt
command_str="$(echo '/opt/splunk/bin/splunk http-event-collector create new-token -uri https://localhost:8089 -description "token for k8s workshop" -disabled 0 -index k8s_ws_logs -indexes k8s_ws_logs,k8s_ws_metrics,k8s_ws_petclinic_logs,k8s_ws_petclinic_metrics,k8s_ws_petclinic_traces -auth admin:\!spl8nk*')"
command_name="$(echo "$WS_USER-_k8s_ws_HEC" | sed -e 's/-_k8s_ws_HEC/_k8s_ws_HEC/g')"
HEC_token="$(sudo -H -u splunk bash -c "$command_str -name $command_name" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
HEC_token="$(cat /tmp/k8s_output.txt | grep "token=" | awk -F\= '{print $2}')"; sleep 1
length_var="$(expr length $HEC_token)"; sleep 1
if [ $length_var = 36 ]; then
echo " .... done"
else
echo " .... failed"
fi








# create the opentelemetry collector directory
date_string="$(date)"
echo -n "** $date_string - FW#2 step - otel: create the opentelemetry collector directory"
echo "** $date_string - FW#2 step - otel: create the opentelemetry collector directory" >> ~/debug.txt
mkdir -p ~/k8s_workshop/k8s_otel; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# download splunk otel collector source from github
date_string="$(date)"
echo -n "** $date_string - FW#2 step - otel: download splunk otel collector source from github"
echo "** $date_string - FW#2 step - otel: download splunk otel collector source from github" >> ~/debug.txt
result="$(git -C ~/k8s_workshop/k8s_otel clone https://github.com/signalfx/splunk-otel-collector-chart.git > /dev/null 2> /dev/null)"
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# make a copy of the original values.yaml file
date_string="$(date)"
echo -n "** $date_string - FW#2 step - otel: make a copy of the original values.yaml file"
echo "** $date_string - FW#2 step - otel: make a copy of the original values.yaml file" >> ~/debug.txt
cp -p ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml.orig; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# update the values.yaml file
date_string="$(date)"
echo -n "** $date_string - FW#2 step - otel: update the values.yaml file"
echo "** $date_string - FW#2 step - otel: update the values.yaml file" >> ~/debug.txt
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml | sed -e "s/clusterName: \"\"/clusterName: \"$WS_USER-minikube-cluster\"/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_1; sleep 1
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_1 | sed -e "s/  endpoint: \"\"/  endpoint: \"http:\/\/$LOCAL_IP:8088\/services\/collector\"/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_2; sleep 1
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_2 | sed -e "s/  token: \"\"/  token: \"$HEC_token\"/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_3; sleep 1
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_3 | sed -e "s/  index: \"main\"/  index: \"k8s_ws_logs\"/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_4; sleep 1
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_4 | sed -e "s/logsEngine: fluentd/logsEngine: otel/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_5; sleep 1
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_5 | sed -e "s/    excludeAgentLogs: true/    excludeAgentLogs: false/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_6; sleep 1
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_6 | sed -e "s/    multilineConfigs: \[\]/    multilineConfigs:\n      - namespaceName:\n          value: default\n        podName:\n          value: $WS_USER-petclinic-otel-deployment-.*\n          useRegexp: true\n        containerName:\n          value: $WS_USER-petclinic-otel-container01\n        firstEntryRegex: ^[^\\\s].*\n/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_7
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_7 | sed -e "s/  fromAnnotations: \[\]/  fromAnnotations:\n    - key_regex: (.*)\n      from: pod\n      tag_name: \"\$\$1\"/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_8
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_8 | sed -e "s/  k8sObjects: \[\]/  k8sObjects:\n    - name: pods\n      mode: pull\n      interval: 60s\n    - name: events\n      mode: watch\n/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_9; sleep 1
rm ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml; sleep 1
mv ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_9 ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml; sleep 1
rm ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_*; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# copy the k8s_workshop/k8s_otel directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - FW#2 step - otel: copy the k8s_workshop/k8s_otel directory to the splunk user"
echo "** $date_string - FW#2 step - otel: copy the k8s_workshop/k8s_otel directory to the splunk user" >> ~/debug.txt
sudo cp -rf ~/k8s_workshop/k8s_otel /home/splunk/k8s_workshop/; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi


# perform a helm dependency build
date_string="$(date)"
echo -n "** $date_string - FW#2 step - otel: perform a helm dependency build"
echo "** $date_string - FW#2 step - otel: perform a helm dependency build" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); cd ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector; helm dependency build" &> /tmp/k8s_output.txt)"; sleep 10
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "Deleting" | awk '{print $1}')"; sleep 1
if [ $result = "Deleting" ]; then
echo " .... done"
else
echo " .... failed"
fi


# install the otel collector using helm
date_string="$(date)"
echo -n "** $date_string - FW#2 step - otel: install the otel collector using helm"
echo "** $date_string - FW#2 step - otel: install the otel collector using helm" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); cd ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector; helm install $WS_USER-k8s-ws -f values.yaml ." &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "STATUS:" | awk '{print $2}')"; sleep 1
if [ $result = "deployed" ]; then
echo " .... done"
else
echo " .... failed"
fi








# create the jmeter load testing directory
date_string="$(date)"
echo -n "** $date_string - FW#2 step - jmeter: create the jmeter load testing directory"
echo "** $date_string - FW#2 step - jmeter: create the jmeter load testing directory" >> ~/debug.txt
mkdir -p ~/k8s_workshop/jmeter; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# download apache jmeter binaries
date_string="$(date)"
echo -n "** $date_string - FW#2 step - jmeter: download apache jmeter binaries"
echo "** $date_string - FW#2 step - jmeter: download apache jmeter binaries" >> ~/debug.txt
cd ~/k8s_workshop/jmeter; sleep 1
result="$(wget --load-cookies /tmp/cookies.txt "https://docs.google.com/uc?export=download&confirm=$(wget --quiet --save-cookies /tmp/cookies.txt --keep-session-cookies --no-check-certificate 'https://docs.google.com/uc?export=download&id=1qqeOFxfjuZPzmJtKtdQazj4PYSo3edop' -O- | sed -rn 's/.*confirm=([0-9A-Za-z_]+).*/\1\n/p')&id=1qqeOFxfjuZPzmJtKtdQazj4PYSo3edop" -O apache-jmeter-5.5-gdcosta.tgz &> /tmp/k8s_output.txt; rm -rf /tmp/cookies.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
if [ $result = 200 ]; then
echo " .... done"
else
echo " .... failed"
fi

# extract the apache jmeter app
date_string="$(date)"
echo -n "** $date_string - FW#2 step - jmeter: extract the apache jmeter app"
echo "** $date_string - FW#2 step - jmeter: extract the apache jmeter app" >> ~/debug.txt
cd ~/k8s_workshop/jmeter; sleep 1
result="$(tar -xzvf apache-jmeter-5.5-gdcosta.tgz 2>&1 | grep "^tar: Error" | wc -l)"; sleep 1
if [ $result = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# download apache jmeter test plan
date_string="$(date)"
echo -n "** $date_string - FW#2 step - jmeter: download apache jmeter test plan"
echo "** $date_string - FW#2 step - jmeter: download apache jmeter test plan" >> ~/debug.txt
cd ~/k8s_workshop/jmeter/apache-jmeter-5.5; sleep 1
result="$(wget https://github.com/gdcosta/jmeter-browser-test/raw/main/petclinic_test_plan.jmx &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
if [ $result = 200 ]; then
echo " .... done"
else
echo " .... failed"
fi

# # make a copy of the original petclinic_test_plan.jmx file
# date_string="$(date)"
# echo -n "** $date_string - FW#2 step - jmeter: make a copy of the original petclinic_test_plan.jmx file"
# cp -p ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx.orig; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # update the petclinic_test_plan.jmx file
# date_string="$(date)"
# echo -n "** $date_string - FW#2 step - jmeter: update the petclinic_test_plan.jmx file"
# cat ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx | sed -e "s/            <stringProp name=\"Argument.value\">localhost<\/stringProp>/            <stringProp name=\"Argument.value\">minikube<\/stringProp>/g;" > ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_1; sleep 1
# cat ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_1 | sed -e "s/            <stringProp name=\"Argument.value\">8080<\/stringProp>/            <stringProp name=\"Argument.value\">30000<\/stringProp>/g;" > ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_2; sleep 1
# cat ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_2 | sed -e "s/          <stringProp name=\"LoopController.loops\">10<\/stringProp>/          <stringProp name=\"LoopController.loops\">500<\/stringProp>/g;" > ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_3; sleep 1
# cat ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_3 | sed -e "s/        <stringProp name=\"ThreadGroup.num_threads\">500<\/stringProp>/        <stringProp name=\"ThreadGroup.num_threads\">5<\/stringProp>/g;" > ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_4; sleep 1
# cat ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_4 | sed -e "s/        <boolProp name=\"ThreadGroup.scheduler\">false<\/boolProp>/        <boolProp name=\"ThreadGroup.scheduler\">true<\/boolProp>/g;" > ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_5; sleep 1
# cat ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_5 | sed -e "s/        <stringProp name=\"ThreadGroup.duration\"><\/stringProp>/        <stringProp name=\"ThreadGroup.duration\">3600<\/stringProp>/g;" > ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_6; sleep 1
# rm ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx; sleep 1
# mv ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_6 ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx; sleep 1
# rm ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_test_plan.jmx_*; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi

# copy the k8s_workshop/jmeter directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - FW#2 step - jmeter: copy the k8s_workshop/jmeter directory to the splunk user"
echo "** $date_string - FW#2 step - jmeter: copy the k8s_workshop/jmeter directory to the splunk user" >> ~/debug.txt
sudo cp -rf ~/k8s_workshop/jmeter /home/splunk/k8s_workshop/; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi






# update the manifest file to use annotations to redirect logs to indexes
date_string="$(date)"
echo -n "** $date_string - FW#2 step - petclinic: update the manifest file to use annotations to redirect logs to indexes"
echo "** $date_string - FW#2 step - petclinic: update the manifest file to use annotations to redirect logs to indexes" >> ~/debug.txt
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
      annotations:
        docker_image_author: "$WS_USER"
        splunk.com/index: "k8s_ws_petclinic_logs"
        splunk.com/sourcetype: "$WS_USER:kube:container:$WS_USER-petclinic-otel-container01"
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
echo -n "** $date_string - FW#2 step - petclinic: copy the petclinic k8s deployment directory to the splunk user"
echo "** $date_string - FW#2 step - petclinic: copy the petclinic k8s deployment directory to the splunk user" >> ~/debug.txt
sudo cp -rf ~/k8s_workshop/petclinic/k8s_deploy /home/splunk/k8s_workshop/petclinic/; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi

# pause for 1 minute(s) to allow petclinic app deletion
date_string="$(date)"
echo -n "** $date_string - FW#2 step - petclinic: pause for 1 minute(s) to allow petclinic app deletion"
echo "** $date_string - FW#2 step - petclinic: pause for 1 minute(s) to allow petclinic app deletion" >> ~/debug.txt
sleep 60
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# delete current petclinic app in kubernetes as the splunk user
date_string="$(date)"
echo -n "** $date_string - FW#2 step - petclinic: delete current petclinic app in kubernetes as the splunk user"
echo "** $date_string - FW#2 step - petclinic: delete current petclinic app in kubernetes as the splunk user" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl delete -f ~/k8s_workshop/petclinic/k8s_deploy/$WS_USER-petclinic-k8s-manifest.yml" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | awk '{print $3}' | tr -d '\n')"; sleep 1
if [ $result = "deleteddeleted" ]; then
echo " .... done"
else
echo " .... failed"
fi

# deploy the petclinic app in kubernetes as the splunk user
date_string="$(date)"
echo -n "** $date_string - FW#2 step - petclinic: deploy the petclinic app in kubernetes as the splunk user"
echo "** $date_string - FW#2 step - petclinic: deploy the petclinic app in kubernetes as the splunk user" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl apply -f ~/k8s_workshop/petclinic/k8s_deploy/$WS_USER-petclinic-k8s-manifest.yml" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | awk '{print $2}' | tr -d '\n')"; sleep 1
if [ $result = "createdcreated" ] || [ $result = "createdunchanged" ] || [ $result = "unchangedcreated" ] || [ $result = "unchangedunchanged" ]; then
echo " .... done"
else
echo " .... failed"
fi

# # stop minikube as the splunk user
# date_string="$(date)"
# echo -n "** $date_string - FW#2 step - minikube: stop minikube as the splunk user"
# result="$(sudo -H -u splunk bash -c "minikube stop" 2>&1 | grep "node stopped" | awk '{print $4}')"; sleep 1
# if [ $result = "stopped." ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi


# # stop the splunk platform
# date_string="$(date)"
# echo -n "** $date_string - FW#2 step - splunk_core: stop the splunk platform"
# command_str="$(echo '/opt/splunk/bin/splunk stop')"
# result="$(sudo -H -u splunk bash -c "$command_str" 2>&1 | grep "^Done" | awk '{print $1}')"; sleep 5
# if [ $result = "Done." ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
