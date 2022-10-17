BUILD_DIR=build
APPS=front-end quotes newsfeed
LIBS=common-utils
STATIC_BASE=front-end/public
STATIC_PATHS=css
STATIC_ARCHIVE=$(BUILD_DIR)/static.tgz
INSTALL_TARGETS=$(addsuffix .install, $(LIBS))
APP_JARS=$(addprefix $(BUILD_DIR)/, $(addsuffix .jar, $(APPS)))
GCP_PROJECT_ID=thoughtworks-newsfeedapp
GCP_ZONE=europe-west4-a
ENV=testing

all: $(BUILD_DIR) $(APP_JARS) $(STATIC_ARCHIVE)

libs: $(INSTALL_TARGETS)

static: $(STATIC_ARCHIVE)

%.install:
	cd $* && lein install

test: $(addsuffix .test, $(LIBS) $(APPS))

%.test:
	cd $* && lein midje

clean:
	rm -rf $(BUILD_DIR) $(addsuffix /target, $(APPS))

$(APP_JARS): | $(BUILD_DIR)
	cd $(notdir $(@:.jar=)) && lein uberjar && cp target/default+uberjar/*-standalone.jar ../$@

$(STATIC_ARCHIVE): | $(BUILD_DIR)
	tar -c -C $(STATIC_BASE) -z -f $(STATIC_ARCHIVE) $(STATIC_PATHS)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

runLocal: 
	docker-compose up -d

createTfBackendBucket:
	gsutil mb -p ${GCP_PROJECT_ID} gs://${GCP_PROJECT_ID}-terraform

terraformCreateWorkspace:
	cd terraform && \
	 terraform workspace new $(ENV)

terraformInit:
	cd terraform && \
	  terraform workspace select $(ENV) && \
	  terraform init

terraformPlan:
	cd terraform && \
	  terraform workspace select $(ENV) && \
	  terraform plan \
	  -var-file="./environments/common.tfvars" \
	  -var-file="./environments/$(ENV)/config.tfvars"

terraformApply:
	cd terraform && \
	  terraform workspace select $(ENV) && \
	  terraform apply \
	  -var-file="./environments/common.tfvars" \
	  -var-file="./environments/$(ENV)/config.tfvars"


SSH_STRING=jagdeep_training92@thoughtworks-newsfeedapp-vm-$(ENV)
GITHUB_SHA?=latest
LOCAL_TAG=newsfeedapp-static:$(GITHUB_SHA)
REMOTE_TAG=gcr.io/$(GCP_PROJECT_ID)/$(LOCAL_TAG)

CONTAINER_NAME=newsfeedapp-static

check-env:
ifndef ENV
	$(error Please set ENV=[testing|prod])
endif

# This cannot be indented or else make will include spaces in front of secret
define get-secret
$(shell gcloud secrets versions access latest --secret=$(1) --project=$(PROJECT_ID))
endef

ssh: check-env
	gcloud compute ssh $(SSH_STRING) \
		--project=$(GCP_PROJECT_ID) \
		--zone=$(GCP_ZONE)

ssh-cmd: check-env
	@gcloud compute ssh $(SSH_STRING) \
		--project=$(GCP_PROJECT_ID) \
		--zone=$(GCP_ZONE) \
		--command="$(CMD)"

dockerBuild:
	docker build --platform linux/amd64 -t $(LOCAL_TAG) .
	
dockerPush:
	docker tag $(LOCAL_TAG) $(REMOTE_TAG)
	docker push $(REMOTE_TAG)

dockerDeploy: check-env
	$(MAKE) ssh-cmd CMD='docker-credential-gcr configure-docker'
	@echo "pulling new container image..."
	$(MAKE) ssh-cmd CMD='docker pull $(REMOTE_TAG)'
	@echo "removing old container..."
	-$(MAKE) ssh-cmd CMD='docker container stop $(CONTAINER_NAME)'
	-$(MAKE) ssh-cmd CMD='docker container rm $(CONTAINER_NAME)'
	@echo "starting new container..."
	@$(MAKE) ssh-cmd CMD='\
		docker run -d --name=$(CONTAINER_NAME) \
			--restart=unless-stopped \
			-p 8000:8000 \
			-e APP_PORT=8000 \
			$(REMOTE_TAG) \
			'