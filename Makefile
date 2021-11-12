# Deploys a kind cluster, the config is passed in to override default cluster
# Added in this project explicitly to faciliate macOS port mapping issue while using nodeports
# Other OS would work without extra host Mapping except Macos
# https://github.com/kubernetes-sigs/kind/issues/808#issuecomment-525046566
deploy-cluster:
	kind create cluster --name local-dev --config k8s-cluster-config.yaml

delete-cluster:
	kind delete cluster --name local-dev

# deletes all the services and k8s cluster
delete-all:
	helm delete $(shell helm list -aq)
	kind delete cluster --name local-dev 

build-image:
	docker build . -t sample-service

# Load image to local kind registry
upload-image:
	kind load --name local-dev docker-image sample-service:latest

# loads the image and installs the service with overrides
deploy:
	make upload-image
	@helm install sample-service ./helm/sample-service --set service.type=NodePort --set service.nodePort=31234

undeploy:
	helm delete sample-service

node_port=$(shell kubectl get --namespace default -o jsonpath="{.spec.ports[0].nodePort}" services sample-service)
node_ip=$(shell kubectl get nodes --namespace default -o jsonpath="{.items[0].status.addresses[0].address}")

# returns the node url to access from external world	
node-url:
	@echo "http://${node_ip}:${node_port}" 
	@ echo "[[ NOTE: If using macOS, use http://localhost:8080 , made possible by k8s-cluster-config.yaml extraPortMappings ]]"

status:
	@kubectl get pods



