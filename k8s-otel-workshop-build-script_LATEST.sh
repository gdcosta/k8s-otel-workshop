#!/bin/bash

#
# Kubernetes Workshop Build Script - Linux Ubuntu
#
#
# author:  Gerry D'Costa
# title:   Staff Solutions Engineer, Splunk
#
# version: 3.0.0


date_string="$(date)"
echo "** $date_string - buildScript - start - build script" >> ~/k8s-otel-workshop.log; sleep 5
if [ $COMPLETE_WORKSHOP_BUILD_ALL = "yes" ]; then
	~/k8s-otel-workshop/k8s-otel-workshop-01-FW1-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
	~/k8s-otel-workshop/k8s-otel-workshop-02-FW2-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
	~/k8s-otel-workshop/k8s-otel-workshop-03-AW1-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
	~/k8s-otel-workshop/k8s-otel-workshop-04-AW2-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
	date_string="$(date)"
	echo "** $date_string - buildScript - stop - build script" >> ~/k8s-otel-workshop.log; sleep 5
	exit 0
else
	if [ $COMPLETE_WORKSHOP_BUILD_ADVANCED_2 = "yes" ]; then
		~/k8s-otel-workshop/k8s-otel-workshop-01-FW1-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
		~/k8s-otel-workshop/k8s-otel-workshop-02-FW2-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
		~/k8s-otel-workshop/k8s-otel-workshop-04-AW2-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
		date_string="$(date)"
		echo "** $date_string - buildScript - stop - build script" >> ~/k8s-otel-workshop.log; sleep 5
		exit 0
		if [ $COMPLETE_WORKSHOP_BUILD_ADVANCED_1 = "yes" ]; then
			~/k8s-otel-workshop/k8s-otel-workshop-01-FW1-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
			~/k8s-otel-workshop/k8s-otel-workshop-02-FW2-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
			~/k8s-otel-workshop/k8s-otel-workshop-03-AW1-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
			date_string="$(date)"
			echo "** $date_string - buildScript - stop - build script" >> ~/k8s-otel-workshop.log; sleep 5
			exit 0
		else
			if [ $SETUP_FOR_ADVANCED_1_OR_2_WORKSHOP = "yes" ]; then
				~/k8s-otel-workshop/k8s-otel-workshop-01-FW1-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
				~/k8s-otel-workshop/k8s-otel-workshop-02-FW2-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
				date_string="$(date)"
				echo "** $date_string - buildScript - stop - build script" >> ~/k8s-otel-workshop.log; sleep 5
				exit 0
			else
				if [ $SETUP_FOR_FOUNDATIONAL_2_WORKSHOP = "yes" ]; then
					~/k8s-otel-workshop/k8s-otel-workshop-01-FW1-tasks_LATEST.sh >> ~/k8s-otel-workshop.log; sleep 5
					date_string="$(date)"
					echo "** $date_string - buildScript - stop - build script" >> ~/k8s-otel-workshop.log; sleep 5
					exit 0
				else
					date_string="$(date)"
					echo "** $date_string - buildScript - stop - build script" >> ~/k8s-otel-workshop.log; sleep 5
					exit 0
				fi
			fi
		fi
	fi
fi
