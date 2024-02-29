#!/bin/bash

#
# Advanced Workshop #2 Tasks - Linux Ubuntu
#
# The following script installs and configures all workshop components for a 
# kubernetes | otel | splunk platform configuration.
# 
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
#  - Advanced Workshop #2
#      - Configure metrics and traces to send to Splunk Observability Cloud
#      - Configure app and otel collector to collect always-on profiling
#      - Configure Splunk RUM capabilities to Splunk Observability Cloud
#

# Global variables
export WORKSHOP_NUM="AW#2"

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
# Dependency: completed execution of setup-for-AW2 script
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







# checking Splunk Observability Cloud environment variables
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - observability: checking Splunk Observability Cloud environment variables"
echo "** $date_string - $WORKSHOP_NUM step - observability: checking Splunk Observability Cloud environment variables" >> ~/debug.txt
if [ -z "$observability_realm" ]; then
echo " ... \$observability_realm environment variable is not set ... exiting"
exit 1
else
	if [ -z "$observability_token" ]; then
	echo " ... \$observability_token environment variable is not set ... exiting"
	exit 1
	else
		if [ -z "$observability_rumToken" ]; then
		echo " ... \$observability_rumToken environment variable is not set ... exiting"
		exit 1
		fi
	fi
fi
sleep 1
echo " .... done"

# update the values.yaml file to configure otel collector to send data to Splunk Observability Cloud
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - otel: update the values.yaml file to configure otel collector to send data to Splunk Observability Cloud"
echo "** $date_string - $WORKSHOP_NUM step - otel: update the values.yaml file to configure otel collector to send data to Splunk Observability Cloud" >> ~/debug.txt
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml | sed -e "s/  realm: \"\"/  realm: \"$observability_realm\"/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_1; sleep 1
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_1 | sed -e "s/  accessToken: \"\"/  accessToken: \"$observability_token\"/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_2; sleep 1
rm ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml; sleep 1
mv ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_2 ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml; sleep 1
rm ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_*; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# update the values.yaml file to configure AlwaysOn Profiling
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - otel: update the values.yaml file to configure AlwaysOn Profiling"
echo "** $date_string - $WORKSHOP_NUM step - otel: update the values.yaml file to configure AlwaysOn Profiling" >> ~/debug.txt
cat ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml | sed -e "s/  profilingEnabled: false/  profilingEnabled: true/g;" > ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_1; sleep 1
rm ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml; sleep 1
mv ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml_1 ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector/values.yaml; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# copy the otel config directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - otel: copy the otel config directory to the splunk user"
echo "** $date_string - $WORKSHOP_NUM step - otel: copy the otel config directory to the splunk user" >> ~/debug.txt
sudo rm -rf /home/splunk/k8s_workshop/k8s_otel; sleep 1
sudo cp -rf ~/k8s_workshop/k8s_otel /home/splunk/k8s_workshop; sleep 1
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
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); cd ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector; helm upgrade $WS_USER-k8s-ws -f values.yaml ." &> /tmp/k8s_output.txt)"; sleep 5
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

CMD ["java", "-javaagent:./splunk-otel-javaagent.jar", "-Dsplunk.profiler.enabled=true", "-Dsplunk.metrics.enabled=true", "-Dsplunk.metrics.endpoint=http://minikube:9943", "-jar", "spring-petclinic-3.0.0-SNAPSHOT.jar"]
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


# LOG OBSERVER: update logging format in application.properties file of the petclinic source to include trace and span info
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: update logging format in application.properties file of the petclinic source to include trace and span info"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: update logging format in application.properties file of the petclinic source to include trace and span info" >> ~/debug.txt
sudo tee ~/k8s_workshop/petclinic/spring-petclinic/src/main/resources/application.properties <<EOF >> ~/debug.txt
# database init, supports mysql too
database=h2
spring.sql.init.schema-locations=classpath*:db/${database}/schema.sql
spring.sql.init.data-locations=classpath*:db/${database}/data.sql

# Web
spring.thymeleaf.mode=HTML

# JPA
spring.jpa.hibernate.ddl-auto=none
spring.jpa.open-in-view=true

# Internationalization
spring.messages.basename=messages/messages

# Actuator
management.endpoints.web.exposure.include=*

# Logging
logging.level.org.springframework=INFO
#
# uncomment the next two lines
logging.level.org.springframework.web=DEBUG
logging.level.org.springframework.context.annotation=TRACE
#
# Add this logging pattern to output trace info collected via auto-instrumentation
logging.pattern.console = %d{yyyy-MM-dd HH:mm:ss.SSS} - [%thread] - severity=%-5level, - %logger{36} - %msg trace_id=%X{trace_id} span_id=%X{span_id} trace_flags=%X{trace_flags} service=%property{otel.resource.service.name} deploy_env=%property{otel.resource.deployment.environment} %n

# Maximum time static resources should be cached
spring.web.resources.cache.cachecontrol.max-age=12h
EOF
sleep 1
sudo chown -R ubuntu:docker ~/k8s_workshop; sleep 1
echo " .... done"

# # LOG OBSERVER: use MAVEN to build a new petclinic package
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: use MAVEN to build a new petclinic package"
# echo "** $date_string - $WORKSHOP_NUM step - petclinic: use MAVEN to build a new petclinic package" >> ~/debug.txt
# cd ~/k8s_workshop/petclinic/spring-petclinic
# result="$(./mvnw package &> /tmp/k8s_output.txt)"; sleep 1
# cat /tmp/k8s_output.txt >> ~/debug.txt
# result="$(cat /tmp/k8s_output.txt | grep "BUILD SUCCESS" | awk '{print $3}')"; sleep 1
# if [ $result = "SUCCESS" ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# 
# 
# # LOG OBSERVER: delete current petclinic app in kubernetes as the splunk user
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: delete current petclinic app in kubernetes as the splunk user"
# echo "** $date_string - $WORKSHOP_NUM step - petclinic: delete current petclinic app in kubernetes as the splunk user" >> ~/debug.txt
# result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl delete -f ~/k8s_workshop/petclinic/k8s_deploy/$WS_USER-petclinic-k8s-manifest.yml" &> /tmp/k8s_output.txt)"; sleep 1
# cat /tmp/k8s_output.txt >> ~/debug.txt
# result="$(cat /tmp/k8s_output.txt | awk '{print $3}' | tr -d '\n')"; sleep 1
# if [ $result = "deleteddeleted" ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# 
# # LOG OBSERVER: copy the k8s_workshop and petclinic directory to the splunk user
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: copy the k8s_workshop and petclinic directory to the splunk user"
# echo "** $date_string - $WORKSHOP_NUM step - petclinic: copy the k8s_workshop and petclinic directory to the splunk user" >> ~/debug.txt
# sudo rm -rf /home/splunk/k8s_workshop/petclinic/*
# sudo cp -rf ~/k8s_workshop/petclinic/* /home/splunk/k8s_workshop/petclinic; sleep 1
# if [ $? = 0 ]; then
# sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# 
# # LOG OBSERVER: pause for 1 minute(s) to allow petclinic container deletion
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: pause for 1 minute(s) to allow petclinic container deletion"
# echo "** $date_string - $WORKSHOP_NUM step - petclinic: pause for 1 minute(s) to allow petclinic container deletion" >> ~/debug.txt
# sleep 60
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# 
# # LOG OBSERVER: delete the old container from the minikube docker registry
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: delete the old container from the minikube docker registry"
# echo "** $date_string - $WORKSHOP_NUM step - petclinic: delete the old container from the minikube docker registry" >> ~/debug.txt
# container_id="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); docker images" 2>&1 | grep "petclinic-otel" | awk '{print $3}')"; sleep 1
# result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); docker rmi -f $container_id" &> /tmp/k8s_output.txt)"; sleep 1
# cat /tmp/k8s_output.txt >> ~/debug.txt
# result="$(cat /tmp/k8s_output.txt | grep "Untagged:" | awk '{print $1}')"; sleep 1
# if [ $result = "Untagged:" ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# 
# # LOG OBSERVER: build the petclinic docker image into the minikube docker registry
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: build the petclinic docker image into the minikube docker registry"
# echo "** $date_string - $WORKSHOP_NUM step - petclinic: build the petclinic docker image into the minikube docker registry" >> ~/debug.txt
# result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); cd ~/k8s_workshop/petclinic/spring-petclinic/target; docker build --tag $WS_USER/petclinic-otel:v1 ." &> /tmp/k8s_output.txt)"; sleep 1
# cat /tmp/k8s_output.txt >> ~/debug.txt
# result="$(cat /tmp/k8s_output.txt | grep "Successfully built" | awk '{print $2}')"; sleep 1
# if [ $result = "built" ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# 
# # LOG OBSERVER: deploy the petclinic app in kubernetes as the splunk user
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: deploy the petclinic app in kubernetes as the splunk user"
# echo "** $date_string - $WORKSHOP_NUM step - petclinic: deploy the petclinic app in kubernetes as the splunk user" >> ~/debug.txt
# result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl apply -f ~/k8s_workshop/petclinic/k8s_deploy/$WS_USER-petclinic-k8s-manifest.yml" &> /tmp/k8s_output.txt)"; sleep 1
# cat /tmp/k8s_output.txt >> ~/debug.txt
# result="$(cat /tmp/k8s_output.txt | awk '{print $2}' | tr -d '\n')"; sleep 1
# if [ $result = "createdcreated" ] || [ $result = "createdunchanged" ] || [ $result = "unchangedcreated" ] || [ $result = "unchangedunchanged" ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi

# LOG OBSERVER: enable authentication tokens in splunk enterprise
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - core: enable authentication tokens in splunk enterprise"
echo "** $date_string - $WORKSHOP_NUM step - core: enable authentication tokens in splunk enterprise" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "curl -k -u admin:\!spl8nk* https://localhost:8089/services/admin/token-auth/tokens_auth -d disabled=false" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "disabled" | awk -F\< '{print $2}' | awk -F\> '{print $2}')"; sleep 1
if [ $result = "0" ]; then
echo " .... done"
else
echo " .... failed"
fi

# LOG OBSERVER: create log observer connect role in splunk enterprise
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - core: create log observer connect role in splunk enterprise"
echo "** $date_string - $WORKSHOP_NUM step - core: create log observer connect role in splunk enterprise" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "curl -k -u admin:\!spl8nk* https://localhost:8089/services/authorization/roles -d name=logobserver-connect-role -d cumulativeRTSrchJobsQuota=0 -d cumulativeSrchJobsQuota=40 -d rtSrchJobsQuota=0 -d srchDiskQuota=1000 -d srchJobsQuota=40 -d srchTimeEarliest=7776000 -d srchTimeWin=2592000 -d capabilities=edit_tokens_own -d capabilities=list_tokens_own -d capabilities=search -d srchIndexesAllowed=k8s_ws_logs -d srchIndexesAllowed=k8s_ws_petclinic_logs" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "\<id\>" | grep "logobserver-connect-role" | awk -F\< '{print $2}' | awk -F\> '{print $2}' | awk -F\/ '{print $NF}')"; sleep 1
if [ -z $result ]; then
echo " .... failed"
else
echo " .... done"
fi

# LOG OBSERVER: create log observer connect system account in splunk enterprise
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - core: create log observer connect system account in splunk enterprise"
echo "** $date_string - $WORKSHOP_NUM step - core: create log observer connect system account in splunk enterprise" >> ~/debug.txt
result="$(sudo -H -u splunk bash -c "curl -k -u admin:\!spl8nk* https://localhost:8089/services/authentication/users -d name=logobserver-connect-user -d password=\!spl8nk* -d roles=logobserver-connect-role -d force-change-pass=false -d realname=\"Log Observer Connect\"" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "\<id\>" | grep "logobserver-connect-user" | awk -F\< '{print $2}' | awk -F\> '{print $2}' | awk -F\/ '{print $NF}')"; sleep 1
if [ -z $result ]; then 
echo " .... failed"; 
else 
echo " .... done"; 
fi


# LOG OBSERVER: update server.conf file in splunk enterprise to use ssl certs
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - core: update server.conf file in splunk enterprise to use ssl certs"
echo "** $date_string - $WORKSHOP_NUM step - core: update server.conf file in splunk enterprise to use ssl certs" >> ~/debug.txt
newServerName="$(curl https://ipinfo.io/ip 2>/dev/null | nslookup | grep "name = " | awk '{print $4}' | sed -e 's/\.$//' | sed "s/\./_/" | awk -F_ '{print "'$(hostname)'."$2}')"
cat /opt/splunk/etc/system/local/server.conf | sed -e "s/^serverName = k8.*/serverName = $newServerName/" > /opt/splunk/etc/system/local/server.conf_1; sleep 1
cat /opt/splunk/etc/system/local/server.conf_1 | sed -e "s/^sslPassword = .*$/serverCert = \/opt\/splunk\/etc\/auth\/sloccerts\/myFinalCert.pem\nrequireClientCert = false\ncliVerifyServerName = false/" > /opt/splunk/etc/system/local/server.conf_2; sleep 1
mv /opt/splunk/etc/system/local/server.conf_2 /opt/splunk/etc/system/local/server.conf; sleep 1
rm /opt/splunk/etc/system/local/server.conf_*;
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# LOG OBSERVER: restart the splunk platform to load server.conf file
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: restart the splunk platform to load server.conf file"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: restart the splunk platform to load server.conf file" >> ~/debug.txt
command_str="$(echo '/opt/splunk/bin/splunk restart')"
result="$(sudo -H -u splunk bash -c "$command_str" &> /tmp/k8s_output.txt)"; sleep 5
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "^Waiting for web server" | awk '{print $10}')"; sleep 1
if [ $result = "Done" ]; then
echo " .... done"
else
echo " .... failed"
fi





# RUM: make a copy of the original layout.html file from the petclinic app
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: make a copy of the original layout.html file from the petclinic app"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: make a copy of the original layout.html file from the petclinic app" >> ~/debug.txt
cp -p ~/k8s_workshop/petclinic/spring-petclinic/src/main/resources/templates/fragments/layout.html ~/k8s_workshop/petclinic/spring-petclinic/src/main/resources/templates/fragments/layout.html.orig; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# RUM: update the layout.html files from the petclinic app to enable splunk observability rum capabilities
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: update the layout.html files from the petclinic app to enable splunk observability rum capabilities"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: update the layout.html files from the petclinic app to enable splunk observability rum capabilities" >> ~/debug.txt
cat ~/k8s_workshop/petclinic/spring-petclinic/src/main/resources/templates/fragments/layout.html | sed -e "s/<head>/<head>\n\n  <script src=\"https:\/\/cdn.signalfx.com\/o11y-gdi-rum\/latest\/splunk-otel-web.js\" crossorigin=\"anonymous\"><\/script>\n  <script>\n    SplunkRum.init({\n      beaconUrl: \"https:\/\/rum-ingest.$observability_realm.signalfx.com\/v1\/rum\",\n      rumAuth: \"$observability_rumToken\",\n      app: \"$WS_USER-k8s-petClinic-service\",\n      environment: \"$WS_USER-k8s-petclinic-deployment-env\"\n      });\n  <\/script>/g" > ~/k8s_workshop/petclinic/spring-petclinic/src/main/resources/templates/fragments/layout.html_1
rm ~/k8s_workshop/petclinic/spring-petclinic/src/main/resources/templates/fragments/layout.html; sleep 1
mv ~/k8s_workshop/petclinic/spring-petclinic/src/main/resources/templates/fragments/layout.html_1 ~/k8s_workshop/petclinic/spring-petclinic/src/main/resources/templates/fragments/layout.html; sleep 1
chmod 755 ~/k8s_workshop/petclinic/spring-petclinic/src/main/resources/templates/fragments/layout.html; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# RUM: use MAVEN to build a new petclinic package
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: use MAVEN to build a new petclinic package"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: use MAVEN to build a new petclinic package" >> ~/debug.txt
cd ~/k8s_workshop/petclinic/spring-petclinic
result="$(./mvnw package &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "BUILD SUCCESS" | awk '{print $3}')"; sleep 1
if [ $result = "SUCCESS" ]; then
echo " .... done"
else
echo " .... failed"
fi

# RUM: delete current petclinic app in kubernetes as the splunk user
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

# RUM: copy the petclinic app directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: copy the petclinic app directory to the splunk user"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: copy the petclinic app directory to the splunk user" >> ~/debug.txt
sudo cp -rf ~/k8s_workshop/petclinic /home/splunk/k8s_workshop; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi


# RUM: delete the old container from the minikube docker registry
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: delete the old container from the minikube docker registry"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: delete the old container from the minikube docker registry" >> ~/debug.txt
container_id="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); docker images" 2>&1 | grep "petclinic-otel" | awk '{print $3}')"; sleep 1
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); docker rmi -f $container_id" &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "Untagged:" | awk '{print $1}')"; sleep 1
if [ $result = "Untagged:" ]; then
echo " .... done"
else
echo " .... failed"
fi


# RUM: build the petclinic docker image into the minikube docker registry
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: build the petclinic docker image into the minikube docker registry"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: build the petclinic docker image into the minikube docker registry" >> ~/debug.txt
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

# # stop minikube as the splunk user
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - minikube: stop minikube as the splunk user"
# result="$(sudo -H -u splunk bash -c "minikube stop" 2>&1 | grep "node stopped" | awk '{print $4}')"; sleep 1
# if [ $result = "stopped." ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi

# # download jmeter libraries for browser tests - cmdrunner-2.3.jar
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: download jmeter libraries for browser tests - cmdrunner-2.3.jar"
# cd ~/k8s_workshop/jmeter/apache-jmeter-5.5/lib; sleep 1
# result="$(wget https://repo1.maven.org/maven2/kg/apc/cmdrunner/2.3/cmdrunner-2.3.jar 2>&1 | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
# if [ $result = 200 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # download jmeter libraries for browser tests - selenium-devtools-v113-4.9.1.jar
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: download jmeter libraries for browser tests - selenium-devtools-v113-4.9.1.jar"
# cd ~/k8s_workshop/jmeter/apache-jmeter-5.5/lib; sleep 1
# result="$(wget https://repo1.maven.org/maven2/org/seleniumhq/selenium/selenium-devtools-v113/4.9.1/selenium-devtools-v113-4.9.1.jar 2>&1 | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
# if [ $result = 200 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # download jmeter libraries for browser tests - selenium-manager-4.8.3.jar
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: download jmeter libraries for browser tests - selenium-manager-4.8.3.jar"
# cd ~/k8s_workshop/jmeter/apache-jmeter-5.5/lib; sleep 1
# result="$(wget https://repo1.maven.org/maven2/org/seleniumhq/selenium/selenium-manager/4.8.3/selenium-manager-4.8.3.jar 2>&1 | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
# if [ $result = 200 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # download jmeter libraries for browser tests - jmeter-plugins-manager-1.9.jar
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: download jmeter libraries for browser tests - jmeter-plugins-manager-1.9.jar"
# cd ~/k8s_workshop/jmeter/apache-jmeter-5.5/lib/ext; sleep 1
# result="$(wget https://repo1.maven.org/maven2/kg/apc/jmeter-plugins-manager/1.9/jmeter-plugins-manager-1.9.jar 2>&1 | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
# if [ $result = 200 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # build Plugins Manager
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: build Plugins Manager"
# cd ~/k8s_workshop/jmeter/apache-jmeter-5.5; sleep 1
# java -cp lib/ext/jmeter-plugins-manager-1.9.jar org.jmeterplugins.repository.PluginManagerCMDInstaller; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # install selenium WebDriver via jmeter Plugins Manager
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: install selenium WebDriver via jmeter Plugins Manager"
# cd ~/k8s_workshop/jmeter/apache-jmeter-5.5/bin; sleep 1
# ; sleep 1
# result="$(./PluginsManagerCMD.sh install jpgc-webdriver 2>&1 | grep "Starting JMeter Plugins modifications" | awk '{print $5}')"; sleep 1
# if [ $result = "Starting" ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # make the directory for all chrome related downloads
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: make the directory for all chrome related downloads"
# mkdir -p ~/k8s_workshop/jmeter/chrome; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # download chrome driver
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: download chrome driver"
# cd ~/k8s_workshop/jmeter/chrome; sleep 1
# result="$(wget https://chromedriver.storage.googleapis.com/113.0.5672.63/chromedriver_linux64.zip 2>&1 | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
# if [ $result = 200 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # unzip chrome driver
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: unzip chrome driver"
# cd ~/k8s_workshop/jmeter/chrome; sleep 1
# result="$(unzip chromedriver_linux64.zip 2>&1 | grep "inflating: chromedriver" | awk '{print $2}')"; sleep 1
# if [ $result = "chromedriver" ]; then
# rm -f ~/k8s_workshop/jmeter/chrome/LICENSE.chromedriver
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # move chromedriver to /usr/local/bin
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: move chromedriver to /usr/local/bin"
# cd ~/k8s_workshop/jmeter/chrome; sleep 1
# chmod 755 ./chromedriver; sleep 1
# sudo mv ./chromedriver /usr/local/bin/chromedriver; sleep 1
# sudo chown splunk:splunk /usr/local/bin/chromedriver; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi

# # RUM: move chromedriver to /usr/local/bin
# date_string="$(date)"
# echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: RUM: move chromedriver to /usr/local/bin"
# cd ~/k8s_workshop/jmeter/apache-jmeter-5.5/bin; sleep 1
# sudo mv ./chromedriver /usr/local/bin/chromedriver; sleep 1
# sudo chown splunk:splunk /usr/local/bin/chromedriver; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi

# RUM: download jmeter browser test plan - developed by gerry dcosta
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - splunk_core: RUM: download jmeter browser test plan - developed by gerry dcosta"
echo "** $date_string - $WORKSHOP_NUM step - splunk_core: RUM: download jmeter browser test plan - developed by gerry dcosta" >> ~/debug.txt
cd ~/k8s_workshop/jmeter/apache-jmeter-5.5/; sleep 1
result="$(wget https://raw.githubusercontent.com/gdcosta/jmeter-browser-test/main/petclinic_browser_test.jmx &> /tmp/k8s_output.txt)"; sleep 1
cat /tmp/k8s_output.txt >> ~/debug.txt
result="$(cat /tmp/k8s_output.txt | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
if [ $result = 200 ]; then
echo " .... done"
else
echo " .... failed"
fi

# RUM: update the petclinic_browser_test.jmx file
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - jmeter: RUM: update the petclinic_browser_test.jmx file"
echo "** $date_string - $WORKSHOP_NUM step - jmeter: RUM: update the petclinic_browser_test.jmx file" >> ~/debug.txt
cat ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_browser_test.jmx | sed -e "s/            <stringProp name=\"Argument.value\">\${__P(url,http:\/\/<UBUNTU_EXTERNAL_IP>)}<\/stringProp>/            <stringProp name=\"Argument.value\">\${__P(url,http:\/\/$LOCAL_IP)}<\/stringProp>/g;" >  ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_browser_test.jmx_1; sleep 1
rm ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_browser_test.jmx; sleep 1
mv ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_browser_test.jmx_1 ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_browser_test.jmx; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# RUM: copy the jmeter app directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: copy the jmeter app directory to the splunk user"
echo "** $date_string - $WORKSHOP_NUM step - petclinic: RUM: copy the jmeter app directory to the splunk user" >> ~/debug.txt
sudo rm -rf /home/splunk/k8s_workshop/jmeter/apache-jmeter-5.5; sleep 1
sudo cp -rf ~/k8s_workshop/jmeter/apache-jmeter-5.5 /home/splunk/k8s_workshop/jmeter; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi
