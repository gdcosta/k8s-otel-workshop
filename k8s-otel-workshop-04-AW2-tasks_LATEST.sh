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

#
# setup - environment variable setup
#
date_string="$(date)"
echo -n "** $date_string - AW#2 step - os: set our workshop variables"
export AMI_INDEX="$(hostname | sed -e "s/k8host//g;")"
export WS_USER=$(echo "user$AMI_INDEX")
export PUBLIC_IP=$(ec2metadata --public-ipv4)
sleep 1
echo " .... done"

# make sure we are in our home directory
date_string="$(date)"
echo -n "** $date_string - AW#2 step - os: change to home directory"
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
echo -n "** $date_string - AW#2 step - splunk_core: start the splunk platform as the splunk user"
splunkStatus="$(sudo -H -u splunk bash -c "/opt/splunk/bin/splunk status" 2>&1 | grep "splunkd" | awk '{print $3}')"; sleep 1
if [ $splunkStatus = "running" ]; then
echo " .... splunk already running ... done"
else
	command_str="$(echo '/opt/splunk/bin/splunk start')"
    result="$(sudo -H -u splunk bash -c "$command_str" 2>&1 | grep "^Waiting for web server" | awk '{print $10}')"; sleep 5
	if [ $result = "Done" ]; then
	echo " .... done"
	else
	echo " .... failed"
	fi
fi

# start minikube as the splunk user
date_string="$(date)"
echo -n "** $date_string - AW#2 step - minikube: start minikube as the splunk user"
minikubeStatus="$(sudo -H -u splunk bash -c "minikube status" 2>&1 | grep -e "^host" -e "^kubelet" -e "^apiserver" -e "^kubeconfig" | awk '{print $2}' | tr -d '\n')"; sleep 1
if [ $minikubeStatus = "RunningRunningRunningConfigured" ]; then
echo " .... minikube already running ... done"
else
	result="$(sudo -H -u splunk bash -c "minikube start --no-vtx-check --driver=docker --subnet=192.168.49.0/24 --extra-config=apiserver.audit-policy-file=/etc/ssl/certs/audit-policy.yaml --extra-config=apiserver.audit-log-path=-" 2>&1 | grep "Done" | awk '{print $2}')"; sleep 1
	if [ $result = "Done!" ]; then
	echo " .... done"
	else
	echo " .... failed"
	fi
fi





# checking Splunk Observability Cloud environment variables
date_string="$(date)"
echo -n "** $date_string - AW#2 step - observability: checking Splunk Observability Cloud environment variables"
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
echo -n "** $date_string - AW#2 step - otel: update the values.yaml file to configure otel collector to send data to Splunk Observability Cloud"
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
echo -n "** $date_string - AW#2 step - otel: update the values.yaml file to configure AlwaysOn Profiling"
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
echo -n "** $date_string - AW#2 step - otel: copy the otel config directory to the splunk user"
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
echo -n "** $date_string - AW#2 step - otel: perform a helm dependency update"
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); cd ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector; helm dependency update" 2>&1 | grep "Deleting" | awk '{print $1}')"; sleep 10
if [ $result = "Deleting" ]; then
echo " .... done"
else
echo " .... failed"
fi

# upgrade the otel collector using helm
date_string="$(date)"
echo -n "** $date_string - AW#2 step - otel: upgrade the otel collector using helm"
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); cd ~/k8s_workshop/k8s_otel/splunk-otel-collector-chart/helm-charts/splunk-otel-collector; helm upgrade $WS_USER-k8s-ws -f values.yaml ." 2>&1 | grep "STATUS:" | awk '{print $2}')"; sleep 5
if [ $result = "deployed" ]; then
echo " .... done"
else
echo " .... failed"
fi







# delete current petclinic app in kubernetes as the splunk user
date_string="$(date)"
echo -n "** $date_string - AW#2 step - petclinic: delete current petclinic app in kubernetes as the splunk user"
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl delete -f ~/k8s_workshop/petclinic/k8s_deploy/$WS_USER-petclinic-k8s-manifest.yml" 2>&1 | awk '{print $3}' | tr -d '\n')"; sleep 1
if [ $result = "deleteddeleted" ]; then
echo " .... done"
else
echo " .... failed"
fi

# create dockerfile in petclinic target directory
date_string="$(date)"
echo -n "** $date_string - AW#2 step - petclinic: create dockerfile in petclinic target directory"
sudo tee ~/k8s_workshop/petclinic/spring-petclinic/target/Dockerfile <<EOF > /dev/null
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
echo -n "** $date_string - AW#2 step - petclinic: copy the k8s_workshop and petclinic directory to the splunk user"
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
echo -n "** $date_string - AW#2 step - petclinic: delete the old container from the minikube docker registry"
container_id="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); docker images" 2>&1 | grep "petclinic-otel" | awk '{print $3}')"; sleep 1
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); docker rmi -f $container_id" 2>&1 | grep "Untagged:" | awk '{print $1}')"; sleep 1
if [ $result = "Untagged:" ]; then
echo " .... done"
else
echo " .... failed"
fi

# build the petclinic docker image into the minikube docker registry
date_string="$(date)"
echo -n "** $date_string - AW#2 step - petclinic: build the petclinic docker image into the minikube docker registry"
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); cd ~/k8s_workshop/petclinic/spring-petclinic/target; docker build --tag $WS_USER/petclinic-otel:v1 ." 2>&1 | grep "Successfully built" | awk '{print $2}')"; sleep 1
if [ $result = "built" ]; then
echo " .... done"
else
echo " .... failed"
fi

# deploy the petclinic app in kubernetes as the splunk user
date_string="$(date)"
echo -n "** $date_string - AW#2 step - petclinic: deploy the petclinic app in kubernetes as the splunk user"
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl apply -f ~/k8s_workshop/petclinic/k8s_deploy/$WS_USER-petclinic-k8s-manifest.yml" 2>&1 | awk '{print $2}' | tr -d '\n')"; sleep 1
if [ $result = "createdcreated" ] || [ $result = "createdunchanged" ] || [ $result = "unchangedcreated" ] || [ $result = "unchangedunchanged" ]; then
echo " .... done"
else
echo " .... failed"
fi








# RUM: make a copy of the original layout.html file from the petclinic app
date_string="$(date)"
echo -n "** $date_string - AW#2 step - petclinic: RUM: make a copy of the original layout.html file from the petclinic app"
cp -p ~/k8s_workshop/petclinic/spring-petclinic/src/main/resources/templates/fragments/layout.html ~/k8s_workshop/petclinic/spring-petclinic/src/main/resources/templates/fragments/layout.html.orig; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# RUM: update the layout.html files from the petclinic app to enable splunk observability rum capabilities
date_string="$(date)"
echo -n "** $date_string - AW#2 step - petclinic: RUM: update the layout.html files from the petclinic app to enable splunk observability rum capabilities"
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
echo -n "** $date_string - AW#2 step - petclinic: RUM: use MAVEN to build a new petclinic package"
cd ~/k8s_workshop/petclinic/spring-petclinic
result="$(./mvnw package 2>&1 | grep "BUILD SUCCESS" | awk '{print $3}')"; sleep 1
if [ $result = "SUCCESS" ]; then
echo " .... done"
else
echo " .... failed"
fi

# RUM: delete current petclinic app in kubernetes as the splunk user
date_string="$(date)"
echo -n "** $date_string - AW#2 step - petclinic: delete current petclinic app in kubernetes as the splunk user"
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl delete -f ~/k8s_workshop/petclinic/k8s_deploy/$WS_USER-petclinic-k8s-manifest.yml" 2>&1 | awk '{print $3}' | tr -d '\n')"; sleep 1
if [ $result = "deleteddeleted" ]; then
echo " .... done"
else
echo " .... failed"
fi

# RUM: copy the petclinic app directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - AW#2 step - petclinic: RUM: copy the petclinic app directory to the splunk user"
sudo cp -rf ~/k8s_workshop/petclinic /home/splunk/k8s_workshop; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi


# RUM: delete the old container from the minikube docker registry
date_string="$(date)"
echo -n "** $date_string - AW#2 step - petclinic: RUM: delete the old container from the minikube docker registry"
container_id="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); docker images" 2>&1 | grep "petclinic-otel" | awk '{print $3}')"; sleep 1
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); docker rmi -f $container_id" 2>&1 | grep "Untagged:" | awk '{print $1}')"; sleep 1
if [ $result = "Untagged:" ]; then
echo " .... done"
else
echo " .... failed"
fi


# RUM: build the petclinic docker image into the minikube docker registry
date_string="$(date)"
echo -n "** $date_string - AW#2 step - petclinic: RUM: build the petclinic docker image into the minikube docker registry"
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); cd ~/k8s_workshop/petclinic/spring-petclinic/target; docker build --tag $WS_USER/petclinic-otel:v1 ." 2>&1 | grep "Successfully built" | awk '{print $2}')"; sleep 1
if [ $result = "built" ]; then
echo " .... done"
else
echo " .... failed"
fi

# deploy the petclinic app in kubernetes as the splunk user
date_string="$(date)"
echo -n "** $date_string - AW#2 step - petclinic: deploy the petclinic app in kubernetes as the splunk user"
result="$(sudo -H -u splunk bash -c "eval \$(minikube -p minikube docker-env); kubectl apply -f ~/k8s_workshop/petclinic/k8s_deploy/$WS_USER-petclinic-k8s-manifest.yml" 2>&1 | awk '{print $2}' | tr -d '\n')"; sleep 1
if [ $result = "createdcreated" ] || [ $result = "createdunchanged" ] || [ $result = "unchangedcreated" ] || [ $result = "unchangedunchanged" ]; then
echo " .... done"
else
echo " .... failed"
fi

# # stop minikube as the splunk user
# date_string="$(date)"
# echo -n "** $date_string - AW#2 step - minikube: stop minikube as the splunk user"
# result="$(sudo -H -u splunk bash -c "minikube stop" 2>&1 | grep "node stopped" | awk '{print $4}')"; sleep 1
# if [ $result = "stopped." ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi

# # download jmeter libraries for browser tests - cmdrunner-2.3.jar
# date_string="$(date)"
# echo -n "** $date_string - AW#2 step - splunk_core: download jmeter libraries for browser tests - cmdrunner-2.3.jar"
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
# echo -n "** $date_string - AW#2 step - splunk_core: download jmeter libraries for browser tests - selenium-devtools-v113-4.9.1.jar"
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
# echo -n "** $date_string - AW#2 step - splunk_core: download jmeter libraries for browser tests - selenium-manager-4.8.3.jar"
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
# echo -n "** $date_string - AW#2 step - splunk_core: download jmeter libraries for browser tests - jmeter-plugins-manager-1.9.jar"
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
# echo -n "** $date_string - AW#2 step - splunk_core: build Plugins Manager"
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
# echo -n "** $date_string - AW#2 step - splunk_core: install selenium WebDriver via jmeter Plugins Manager"
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
# echo -n "** $date_string - AW#2 step - splunk_core: make the directory for all chrome related downloads"
# mkdir -p ~/k8s_workshop/jmeter/chrome; sleep 1
# if [ $? = 0 ]; then
# echo " .... done"
# else
# echo " .... failed"
# fi
# 
# # download chrome driver
# date_string="$(date)"
# echo -n "** $date_string - AW#2 step - splunk_core: download chrome driver"
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
# echo -n "** $date_string - AW#2 step - splunk_core: unzip chrome driver"
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
# echo -n "** $date_string - AW#2 step - splunk_core: move chromedriver to /usr/local/bin"
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
# echo -n "** $date_string - AW#2 step - splunk_core: RUM: move chromedriver to /usr/local/bin"
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
echo -n "** $date_string - AW#2 step - splunk_core: RUM: download jmeter browser test plan - developed by gerry dcosta"
cd ~/k8s_workshop/jmeter/apache-jmeter-5.5/; sleep 1
result="$(wget https://raw.githubusercontent.com/gdcosta/jmeter-browser-test/main/petclinic_browser_test.jmx 2>&1 | grep "^HTTP" | tail -1 | sed -e 's/^HTTP request sent, awaiting response... //g;' | awk '{print $1}')"; sleep 1
if [ $result = 200 ]; then
echo " .... done"
else
echo " .... failed"
fi

# RUM: update the petclinic_browser_test.jmx file
date_string="$(date)"
echo -n "** $date_string - AW#2 step - jmeter: RUM: update the petclinic_browser_test.jmx file"
cat ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_browser_test.jmx | sed -e "s/            <stringProp name=\"Argument.value\">\${__P(url,http:\/\/<UBUNTU_EXTERNAL_IP>)}<\/stringProp>/            <stringProp name=\"Argument.value\">\${__P(url,http:\/\/$PUBLIC_IP)}<\/stringProp>/g;" >  ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_browser_test.jmx_1; sleep 1
rm ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_browser_test.jmx; sleep 1
mv ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_browser_test.jmx_1 ~/k8s_workshop/jmeter/apache-jmeter-5.5/petclinic_browser_test.jmx; sleep 1
if [ $? = 0 ]; then
echo " .... done"
else
echo " .... failed"
fi

# RUM: copy the jmeter app directory to the splunk user
date_string="$(date)"
echo -n "** $date_string - AW#2 step - petclinic: RUM: copy the jmeter app directory to the splunk user"
sudo rm -rf /home/splunk/k8s_workshop/jmeter/apache-jmeter-5.5; sleep 1
sudo cp -rf ~/k8s_workshop/jmeter/apache-jmeter-5.5 /home/splunk/k8s_workshop/jmeter; sleep 1
if [ $? = 0 ]; then
sudo chown -R splunk:docker /home/splunk/k8s_workshop; sleep 1
echo " .... done"
else
echo " .... failed"
fi