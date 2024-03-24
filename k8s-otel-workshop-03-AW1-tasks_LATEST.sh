#!/bin/bash

#
# Advanced Workshop #1 Tasks - Linux Ubuntu
#
# The following script sets all components for a kubernetes | otel workshop and sets up
# participants to start running Advanced Workshop #2
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
#  - Advanced Workshop #1
#      - turn on metrics collection
#      - enable JVM metrics collection
#      - turn on trace collection
#      - create a trace | apm dashboard
#      - redirect logs using the HELM manifest file
#

# Global variables
export WORKSHOP_NUM="AW#1"

#
# setup - environment variable setup
#
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - os: set our workshop variables"
echo "** $date_string - $WORKSHOP_NUM step - os: set our workshop variables" >> ~/debug.txt
export AMI_INDEX="$(hostname | sed -e "s/k8shost//g;")"
export WS_USER=$(echo "user$AMI_INDEX")
export PUBLIC_IP=$(ec2metadata --public-ipv4)
export LOCAL_IP=$(ec2metadata --local-ipv4)
sleep 1
echo " .... done"

# make sure we are in our home directory
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - os: change to home directory"
echo "** $date_string - $WORKSHOP_NUM step - os: change to home directory" >> ~/debug.txt
cd ~/; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

#
# ----------------
# Dependency: completed execution of setup-for-AW1 script
# 

# start the splunk platform
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: start the splunk platform as the splunk user"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: start the splunk platform as the splunk user" >> ~/debug.txt
splunkStatus="$(sudo -H -u splunk bash -c "/opt/splunk/bin/splunk status" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
splunkStatus="$(cat /tmp/k8s_output.txt | grep "splunkd" | awk '{print $3}')"; sleep 1
if [ $splunkStatus = "running" ]; then
echo " .... splunk already running ... done"
else
	command_str="$(echo '/opt/splunk/bin/splunk start')"
	result="$(sudo -H -u splunk bash -c "$command_str" &> /tmp/k8s_output.txt)"; sleep 5
	cat /tmp/k8s_output.txt >> ~/debug.txt
	result="$(cat /tmp/k8s_output.txt | grep "^Waiting for web server" | awk '{print $10}')"; sleep 1
	if [ $result = "Done" ]; then
	echo " .... done"
	else
	echo " .... failed"
	fi
fi

# start minikube as the splunk user
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - minikube: start minikube as the splunk user"
echo "** $date_string - $WORKSHOP_NUM step - minikube: start minikube as the splunk user" >> ~/debug.txt
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




# update the values.yaml file for metrics collection
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - otel: update the values.yaml file for metrics collection"
echo "** $date_string - $WORKSHOP_NUM step - otel: update the values.yaml file for metrics collection" >> ~/debug.txt
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml | sed -e "s/  metricsIndex: \"\"/  metricsIndex: \"k8s_ws_metrics\"/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_1; sleep 1
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_1 | sed -e "s/  metricsEnabled: false/  metricsEnabled: true/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_2; sleep 1
rm ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml; sleep 1
mv ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_2 ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml; sleep 1
rm ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_*; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# update the values.yaml file for trace collection
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - otel: update the values.yaml file for trace collection"
echo "** $date_string - $WORKSHOP_NUM step - otel: update the values.yaml file for trace collection" >> ~/debug.txt
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml | sed -e "s/  tracesIndex: \"\"/  tracesIndex: \"k8s_ws_petclinic_traces\"/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_1; sleep 1
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_1 | sed -e "s/  tracesEnabled: false/  tracesEnabled: true/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_2; sleep 1
rm ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml; sleep 1
mv ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_2 ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml; sleep 1
rm ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_*; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# copy the k8s_workshop and petclinic directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - otel: copy the k8s_otel directory to the splunk user"
echo "** $date_string - $WORKSHOP_NUM step - otel: copy the k8s_otel directory to the splunk user" >> ~/debug.txt
rm -rf /home/splunk/k8s_workshop/k8s_otel; sleep 1
sudo cp -rf ~/k8s_workshop/k8s_otel /home/splunk/k8s_workshop/k8s_otel; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi

# perform a helm dependency update
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - otel: perform a helm dependency update"
echo "** $date_string - $WORKSHOP_NUM step - otel: perform a helm dependency update" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); cd ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector; helm dependency update" &> /tmp/k8s_output.txt)"; sleep 10
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "Deleting" | awk '{print $1}')"; sleep 1
if [ $result = "Deleting" ]; then
echo " .... done"
else
echo " .... failed"
fi

# upgrade the otel collector using helm
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - otel: upgrade the otel collector using helm"
echo "** $date_string - $WORKSHOP_NUM step - otel: upgrade the otel collector using helm" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); cd ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector; helm upgrade $WS_USER-k8s-ws -f values.yaml ." &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "STATUS:" | awk '{print $2}')"; sleep 1
if [ $result = "deployed" ]; then
echo " .... done"
else
echo " .... failed"
fi








# delete current petclinic app in kubernetes as the splunk user
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: delete current petclinic app in kubernetes as the splunk user"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: delete current petclinic app in kubernetes as the splunk user" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl delete -f ~/k8s_workshop/petclinic/k8s_deploy/$WS_USER-petclinic-k8s-manifest.yml" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | awk '{print $3}' | tr -d '\n')"; sleep 1
if [ $result = "deleteddeleted" ]; then
echo " .... done"
else
echo " .... failed"
fi

# make the directory for JVM auto instrumentation library
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - otel: make the directory for JVM auto instrumentation library"
echo "** $date_string - $WORKSHOP_NUM step - otel: make the directory for JVM auto instrumentation library" >> ~/debug.txt
if [ -d ~/k8s_workshop/petclinic/spring-petclinic/target/splunk ]
then
	echo -n " ... directory already exists"; sleep 1
else
	mkdir -p ~/k8s_workshop/petclinic/spring-petclinic/target/splunk; sleep 1
fi
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# download the latest splunk otel JVM auto instrumentation library
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - otel: download the latest splunk otel JVM auto instrumentation library"
echo "** $date_string - $WORKSHOP_NUM step - otel: download the latest splunk otel JVM auto instrumentation library" >> ~/debug.txt
if [ -f ~/k8s_workshop/petclinic/spring-petclinic/target/splunk/splunk-otel-javaagent.jar ]
then
	echo -n " ... file already exists"; sleep 1; echo " .... done"
else
	result="$(curl -L https://github.com/signalfx/splunk-otel-java/releases/latest/download/splunk-otel-javaagent.jar -o ~/k8s_workshop/petclinic/spring-petclinic/target/splunk/splunk-otel-javaagent.jar &> /tmp/k8s_output.txt)"
	cat /tmp/k8s_output.txt >> ~/debug.txt
	result="$(cat /tmp/k8s_output.txt | tail -1 | sed -e 's/\r/\n/g;' | tail -1 | awk '{print $3}')"; sleep 1
	if [ $result = 100 ]; then
	echo " .... done"
	else
	echo " .... failed"
	fi
fi

# create dockerfile in petclinic target directory
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: create dockerfile in petclinic target directory"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: create dockerfile in petclinic target directory" >> ~/debug.txt
sudo tee ~/k8s_workshop/petclinic/spring-petclinic/target/Dockerfile <<EOF >> ~/debug.txt
# syntax=docker/dockerfile:1

FROM eclipse-temurin:17-jdk-jammy

WORKDIR /app

COPY * ./

COPY ./splunk/splunk-otel-javaagent.jar ./

ENV OTEL_EXPORTER_OTLP_ENDPOINT="http://minikube:4317"

ENV OTEL_SERVICE_NAME="$WS_USER-k8s-petClinic-service"
ENV OTEL_RESOURCE_ATTRIBUTES="deployment.environment=$WS_USER-k8s-petclinic-deployment-env"

CMD ["java", "-javaagent:./splunk-otel-javaagent.jar", "-Dsplunk.metrics.enabled=true", "-Dsplunk.metrics.endpoint=http://minikube:9943", "-jar", "spring-petclinic-3.0.0-SNAPSHOT.jar"]
EOF
sleep 1
sudo chown -R ubuntu:docker ~/k8s_workshop; sleep 1
echo " .... done"

# copy the k8s_workshop and petclinic directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: copy the k8s_workshop and petclinic directory to the splunk user"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: copy the k8s_workshop and petclinic directory to the splunk user" >> ~/debug.txt
sudo rm -rf /home/splunk/k8s_workshop/petclinic/*
sudo cp -rf ~/k8s_workshop/petclinic/* /home/splunk/k8s_workshop/petclinic; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi

# pause for 1 minute(s) to allow petclinic container deletion
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: pause for 1 minute(s) to allow petclinic container deletion"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: pause for 1 minute(s) to allow petclinic container deletion" >> ~/debug.txt
sleep 60
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# delete the old container from the minikube docker registry
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: delete the old container from the minikube docker registry"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: delete the old container from the minikube docker registry" >> ~/debug.txt
container_id="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); docker images" 2>&1 | grep "petclinic-otel" | awk '{print $3}')"; sleep 1
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); docker rmi -f $container_id" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "Untagged:" | awk '{print $1}')"; sleep 1
if [ $result = "Untagged:" ]; then
echo " .... done"
else
echo " .... failed"
fi

# build the petclinic docker image into the minikube docker registry
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: build the petclinic docker image into the minikube docker registry"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: build the petclinic docker image into the minikube docker registry" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); cd ~/k8s_workshop/petclinic/spring-petclinic/target; docker build --tag $WS_USER/petclinic-otel:v1 ." &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "Successfully built" | awk '{print $2}')"; sleep 1
if [ $result = "built" ]; then
echo " .... done"
else
echo " .... failed"
fi

# deploy the petclinic app in kubernetes as the splunk user
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: deploy the petclinic app in kubernetes as the splunk user"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: deploy the petclinic app in kubernetes as the splunk user" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl apply -f ~/k8s_workshop/petclinic/k8s_deploy/$WS_USER-petclinic-k8s-manifest.yml" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | awk '{print $2}' | tr -d '\n')"; sleep 1
if [ $result = "createdcreated" ] || [ $result = "createdunchanged" ] || [ $result = "unchangedcreated" ] || [ $result = "unchangedunchanged" ]; then
echo " .... done"
else
echo " .... failed"
fi













# update the app.conf file in the k8s workshop app
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: update the app.conf file in the k8s workshop app"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: update the app.conf file in the k8s workshop app" >> ~/debug.txt
idValue="$(echo "$WS_USER-_k8s_workshop_app" | sed -e 's/-_k8s_workshop_app/\_k8s_workshop_app/g')"
app_name="$(echo $WS_USER-_k8s_workshop_app | sed -e 's/-_k8s_workshop_app/_k8s_workshop_app/g')"
sudo tee ~/k8s_workshop/splunk_app/$app_name/default/app.conf <<EOF >> ~/debug.txt
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
version = 3.0.0
author = $WS_USER
description = Splunk App for k8s workshop knowledge objects

EOF

sleep 1
sudo chown -R ubuntu:docker ~/k8s_workshop; sleep 1
echo " .... done"


# update indexes.conf file to added three additional indexes
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: update indexes.conf file to added three additional indexes"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: update indexes.conf file to added three additional indexes" >> ~/debug.txt

idValue="$(echo "$WS_USER-_k8s_workshop_app" | sed -e 's/-_k8s_workshop_app/\_k8s_workshop_app/g')"
app_name="$(echo $WS_USER-_k8s_workshop_app | sed -e 's/-_k8s_workshop_app/_k8s_workshop_app/g')"

sudo tee -a ~/k8s_workshop/splunk_app/$app_name/local/indexes.conf <<EOF >> ~/debug.txt

[k8s_ws_petclinic_traces]
coldPath = \$SPLUNK_DB/k8s_ws_petclinic_traces/colddb
enableDataIntegrityControl = 0
enableTsidxReduction = 0
homePath = \$SPLUNK_DB/k8s_ws_petclinic_traces/db
maxTotalDataSizeMB = 1024
thawedPath = \$SPLUNK_DB/k8s_ws_petclinic_traces/thaweddb
frozenTimePeriodInSecs = 432000

[k8s_ws_metrics]
coldPath = \$SPLUNK_DB/k8s_ws_metrics/colddb
datatype = metric
enableDataIntegrityControl = 0
enableTsidxReduction = 0
homePath = \$SPLUNK_DB/k8s_ws_metrics/db
maxTotalDataSizeMB = 1024
metric.timestampResolution = ms
thawedPath = \$SPLUNK_DB/k8s_ws_metrics/thaweddb
frozenTimePeriodInSecs = 432000

[k8s_ws_petclinic_metrics]
coldPath = \$SPLUNK_DB/k8s_ws_petclinic_metrics/colddb
datatype = metric
enableDataIntegrityControl = 0
enableTsidxReduction = 0
homePath = \$SPLUNK_DB/k8s_ws_petclinic_metrics/db
maxTotalDataSizeMB = 1024
metric.timestampResolution = ms
thawedPath = \$SPLUNK_DB/k8s_ws_petclinic_metrics/thaweddb
frozenTimePeriodInSecs = 432000
EOF
sleep 1
sudo chown -R ubuntu:docker ~/k8s_workshop; sleep 1
echo " .... done"



# create a props.conf file for the k8s workshop app for index redirection
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: create a props.conf file for the k8s workshop app for index redirection"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: create a props.conf file for the k8s workshop app for index redirection" >> ~/debug.txt
prop1="$(echo "TRANSFORMS-$WS_USER-_changeidxandst = $WS_USER-_change_st,$WS_USER-_change_idx" | sed -e 's/-_changeidxandst/\_changeidxandst/g' | sed -e 's/-_change_st,/\_change_st,/g' | sed -e 's/-_change_idx/\_change_idx/g')"
prop2="$(echo "TRANSFORMS-$WS_USER-_changemetricidx = $WS_USER-_change_metric_idx" | sed -e 's/-_changemetricidx/\_changemetricidx/g' | sed -e 's/-_change_metric_idx/\_change_metric_idx,/g')"
app_name="$(echo $WS_USER-_k8s_workshop_app | sed -e 's/-_k8s_workshop_app/_k8s_workshop_app/g')"
sudo tee ~/k8s_workshop/splunk_app/$app_name/local/props.conf <<EOF >> ~/debug.txt
[httpevent]
$prop1
$prop2
EOF
sleep 1
sudo chown -R ubuntu:docker ~/k8s_workshop; sleep 1
echo " .... done"

# create a transforms.conf file for the k8s workshop app for index redirection
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: create a transforms.conf file for the k8s workshop app for index redirection"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: create a transforms.conf file for the k8s workshop app for index redirection" >> ~/debug.txt
stanza1="$(echo "[$WS_USER-_change_st]" | sed -e 's/-_change_st/\_change_st/g')"
stanza2="$(echo "[$WS_USER-_change_idx]" | sed -e 's/-_change_idx/\_change_idx/g')"
stanza3="$(echo "[$WS_USER-_change_metric_idx]" | sed -e 's/-_change_metric_idx/\_change_metric_idx/g')"
sudo tee ~/k8s_workshop/splunk_app/$app_name/local/transforms.conf <<EOF >> ~/debug.txt
# Use the splunk documentation for transforms.conf to learn more about what
# index-time transformations are available, for SOURCE_KEY such as “field:”, 
# “MetaData:” and “_raw”.
#
# Keep in mind that if you are making changes to MetaData information for the
# following - Host, Source and Sourcetype - you’ll have to ensure you have the correct
# prefix for the FORMAT command. (i.e. MetaData:Sourcetype -> prefix sourcetype::)
#
# https://docs.splunk.com/Documentation/Splunk/latest/Admin/Transformsconf
#
$stanza1
SOURCE_KEY = field:k8s.pod.labels.app
REGEX = $WS_USER-petclinic-otel-app
DEST_KEY = MetaData:Sourcetype
FORMAT = sourcetype::k8s:traces:$WS_USER-petclinic-app

$stanza2
SOURCE_KEY = field:k8s.pod.labels.app
REGEX = $WS_USER-petclinic-otel-app
DEST_KEY = _MetaData:Index
FORMAT = k8s_ws_petclinic_traces

$stanza3
SOURCE_KEY = field:deployment_environment
REGEX = $WS_USER-k8s-petclinic-deployment-env
DEST_KEY = _MetaData:Index
FORMAT = k8s_ws_petclinic_metrics
EOF
sleep 1
sudo chown -R ubuntu:docker ~/k8s_workshop; sleep 1
echo " .... done"


# tar and compress k8s workshop app
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: tar and compress k8s workshop app"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: tar and compress k8s workshop app" >> ~/debug.txt
app_name="$(echo $WS_USER-_k8s_workshop_app | sed -e 's/-_k8s_workshop_app/_k8s_workshop_app/g')"
cd ~/k8s_workshop/splunk_app; sleep 1
result="$(tar -czvf ~/k8s_workshop/splunk_app/$app_name.tar.gz $app_name/ &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "^tar: Error" | wc -l)"; sleep 1
if [ $result = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# copy the k8s splunk app directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: copy the k8s splunk app directory to the splunk user"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: copy the k8s splunk app directory to the splunk user" >> ~/debug.txt
sudo cp -rf ~/k8s_workshop/splunk_app /home/splunk/k8s_workshop; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi

# upgrade k8s workshop app
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: upgrade k8s workshop app"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: upgrade k8s workshop app" >> ~/debug.txt
app_name="$(echo $WS_USER-_k8s_workshop_app | sed -e 's/-_k8s_workshop_app/_k8s_workshop_app/g')"
command_str="$(echo "/opt/splunk/bin/splunk install app ~/k8s_workshop/splunk_app/$app_name.tar.gz -update 1 -auth admin:\!spl8nk*")"
result="$(sudo -H -u splunk bash -c "$command_str" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "^App" | awk '{print $3}')"; sleep 1
if [ $result = "installed" ]; then
echo " .... done"
else
echo " .... failed"
fi









# create the splunk_dashboard directory
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: create the splunk_dashboard directory"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: create the splunk_dashboard directory" >> ~/debug.txt
mkdir -p ~/k8s_workshop/splunk_dashboard; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# download the splunk apm trace dashboard
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: download the splunk apm trace dashboard"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: download the splunk apm trace dashboard" >> ~/debug.txt
cd ~/k8s_workshop/splunk_dashboard; sleep 1
result="$(wget https://github.com/gdcosta/splunk-apm-dashboard/raw/main/apm_traces_4.0.0.xml &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
if [ $result = 200 ]; then
echo " .... done"
else
echo " .... failed"
fi

# create a new splunk dashboard template via rest api
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: create a new splunk dashboard template via rest api"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: create a new splunk dashboard template via rest api" >> ~/debug.txt
app_name="$(echo "$WS_USER-_k8s_workshop_app" | sed -e 's/-_k8s_workshop_app/_k8s_workshop_app/g')"; sleep 1
dash_name="$(echo "$WS_USER-_apm_dashboard" | sed -e 's/-_apm_dashboard/_apm_dashboard/g')"; sleep 1
result="$(curl -k -u admin:\!spl8nk* https://$LOCAL_IP:8089/servicesNS/admin/$app_name/data/ui/views -d "name=$dash_name&eai:data=<dashboard><label>the_new_label</label></dashboard>" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "    <title>" | awk -F\> '{print $2}' | awk -F\< '{print $1}')"; sleep 1
if [ $result = "$dash_name" ]; then
echo " .... done"
else
echo " .... failed"
fi

# update splunk dashboard template permissions via rest api
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: update splunk dashboard template permissions via rest api"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: update splunk dashboard template permissions via rest api" >> ~/debug.txt
app_name="$(echo "$WS_USER-_k8s_workshop_app" | sed -e 's/-_k8s_workshop_app/_k8s_workshop_app/g')"; sleep 1
dash_name="$(echo "$WS_USER-_apm_dashboard" | sed -e 's/-_apm_dashboard/_apm_dashboard/g')"; sleep 1
result="$(curl -k -u admin:\!spl8nk* https://$LOCAL_IP:8089/servicesNS/admin/$app_name/data/ui/views/$dash_name/acl -d owner=admin -d perms.read=* -d sharing=app -d perms.write=admin,power &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "    <title>" | awk -F\> '{print $2}' | awk -F\< '{print $1}')"; sleep 1
if [ $result = "$dash_name" ]; then
echo " .... done"
else
echo " .... failed"
fi

# update the physical dashboard xml file
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: update the physical dashboard xml file"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: update the physical dashboard xml file" >> ~/debug.txt
app_name="$(echo "$WS_USER-_k8s_workshop_app" | sed -e 's/-_k8s_workshop_app/_k8s_workshop_app/g')"; sleep 1
dash_name="$(echo "$WS_USER-_apm_dashboard" | sed -e 's/-_apm_dashboard/_apm_dashboard/g')"; sleep 1
cd ~/k8s_workshop/splunk_dashboard; sleep 1
cat ~/k8s_workshop/splunk_dashboard/apm_traces_4.0.0.xml | sudo tee /opt/splunk/etc/apps/$app_name/local/data/ui/views/$dash_name.xml > /dev/null 2> /dev/null; sleep 1
if [ $? = 0 ]; then
sudo chown splunk:docker /opt/splunk/etc/apps/$app_name/local/data/ui/views/$dash_name.xml; sleep 1
echo " .... done"
else
echo " .... failed"
fi





# download the splunk metrics dashboard
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: download the splunk metrics dashboard"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: download the splunk metrics dashboard" >> ~/debug.txt
cd ~/k8s_workshop/splunk_dashboard; sleep 1
result="$(wget https://github.com/gdcosta/splunk-apm-dashboard/raw/main/k8s_metrics_dashboard.xml &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
if [ $result = 200 ]; then
echo " .... done"
else
echo " .... failed"
fi

# create a new splunk dashboard template via rest api
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: create a new splunk dashboard template via rest api"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: create a new splunk dashboard template via rest api" >> ~/debug.txt
app_name="$(echo "$WS_USER-_k8s_workshop_app" | sed -e 's/-_k8s_workshop_app/_k8s_workshop_app/g')"; sleep 1
dash_name="$(echo "$WS_USER-_k8s_metrics_dashboard" | sed -e 's/-_k8s_metrics_dashboard/_k8s_metrics_dashboard/g')"; sleep 1
result="$(curl -k -u admin:\!spl8nk* https://$LOCAL_IP:8089/servicesNS/admin/$app_name/data/ui/views -d "name=$dash_name&eai:data=<dashboard><label>the_new_label</label></dashboard>" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "    <title>" | awk -F\> '{print $2}' | awk -F\< '{print $1}')"; sleep 1
if [ $result = "$dash_name" ]; then
echo " .... done"
else
echo " .... failed"
fi

# update splunk dashboard template permissions via rest api
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: update splunk dashboard template permissions via rest api"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: update splunk dashboard template permissions via rest api" >> ~/debug.txt
app_name="$(echo "$WS_USER-_k8s_workshop_app" | sed -e 's/-_k8s_workshop_app/_k8s_workshop_app/g')"; sleep 1
dash_name="$(echo "$WS_USER-_k8s_metrics_dashboard" | sed -e 's/-_k8s_metrics_dashboard/_k8s_metrics_dashboard/g')"; sleep 1
result="$(curl -k -u admin:\!spl8nk* https://$LOCAL_IP:8089/servicesNS/admin/$app_name/data/ui/views/$dash_name/acl -d owner=admin -d perms.read=* -d sharing=app -d perms.write=admin,power &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "    <title>" | awk -F\> '{print $2}' | awk -F\< '{print $1}')"; sleep 1
if [ $result = "$dash_name" ]; then
echo " .... done"
else
echo " .... failed"
fi

# update the physical dashboard xml file
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: update the physical dashboard xml file"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: update the physical dashboard xml file" >> ~/debug.txt
app_name="$(echo "$WS_USER-_k8s_workshop_app" | sed -e 's/-_k8s_workshop_app/_k8s_workshop_app/g')"; sleep 1
dash_name="$(echo "$WS_USER-_k8s_metrics_dashboard" | sed -e 's/-_k8s_metrics_dashboard/_k8s_metrics_dashboard/g')"; sleep 1
cd ~/k8s_workshop/splunk_dashboard; sleep 1
cat ~/k8s_workshop/splunk_dashboard/k8s_metrics_dashboard.xml | sudo tee /opt/splunk/etc/apps/$app_name/local/data/ui/views/$dash_name.xml > /dev/null 2> /dev/null; sleep 1
if [ $? = 0 ]; then
sudo chown splunk:docker /opt/splunk/etc/apps/$app_name/local/data/ui/views/$dash_name.xml; sleep 1
echo " .... done"
else
echo " .... failed"
fi









# restart the splunk platform to load new dashboard
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: restart the splunk platform to load new dashboard"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: restart the splunk platform to load new dashboard" >> ~/debug.txt
command_str="$(echo '/opt/splunk/bin/splunk restart')"
result="$(sudo -H -u splunk bash -c "$command_str" &> /tmp/k8s_output.txt)"; sleep 5
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "^Waiting for web server" | awk '{print $10}')"; sleep 1
if [ $result = "Done" ]; then
echo " .... done"
else
echo " .... failed"
fi

# copy the k8s_workshop and petclinic directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: copy the k8s_workshop and petclinic directory to the splunk user"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: copy the k8s_workshop and petclinic directory to the splunk user" >> ~/debug.txt
sudo cp -rf ~/k8s_workshop/splunk_dashboard /home/splunk/k8s_workshop; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi

