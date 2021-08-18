# checks if branch has something pending
function parse_git_dirty() {
  git diff --quiet --ignore-submodules HEAD 2>/dev/null
  [ $? -eq 1 ] && echo ""
}

# gets the current git branch
function parse_git_branch() {
  git branch --no-color 2>/dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1$(parse_git_dirty)/"
}

# get last commit hash prepended with @ (i.e. @8a323d0)
function parse_git_hash() {
  git rev-parse --short HEAD 2>/dev/null | sed "s/\(.*\)/@\1/"
}

function replace() {
  echo "$1" | tr "$2" "$3"
}

GIT_BRANCH=$(parse_git_branch)
PROJECT_NAME="${PWD##*/}"
IMAGE_NAME=$(replace "${PROJECT_NAME}" "_" "-")
DOCKER_TAG=${IMAGE_NAME}
CI_ENVIRONMENT_NAME="local"
VERSION=${GIT_BRANCH}
function pingRegistry() {
  curl -Is https://"$1" | head -1
}

function minikubeIsRunning() {
  running=$(minikube status | grep "host")
  echo running
}

function parseFile() {
  eval "cat <<EOF
$(<"$1")
EOF
" >"$2"
}

function startProjectConfig() {
   mkdir ./kube-deploy
   echo "kube-deploy" >> .gitignore

   kustomization="resources:\n"
   parseFile ./minikube/deployment.yaml ./kube-deploy/deployment.yaml
   kustomization="${kustomization}\t- ./kube-deploy/deployment.yaml\n"
   echo "Does your project will use customization ? (y/N): "
   read -r -s customization
   if [[ "$customization" == "y" ]]; then
     echo "Does your project will use custom resources definition ? (y/N): "
     read -r -s crd
     if [[ "$crd" == "y" ]]; then
        parseFile ./minikube/crd.yaml ./kube-deploy/minikube-crd.yaml
        kustomization="${kustomization}\t- ./kube-deploy/minikube-crd.yaml\n"
     fi
     echo "Does your project will use service ? (y/N): "
     read -r -s service
     if [[ "$service" == "y" ]]; then
        parseFile ./minikube/service.yaml ./kube-deploy/minikube-service.yaml
        kustomization="${kustomization}\t- ./kube-deploy/minikube-service.yaml\n"
     fi
     echo "Does your project will use routes ? (y/N): "
     read -r -s routes
     if [[ "$routes" == "y" ]]; then
        parseFile ./minikube/routes.yaml ./kube-deploy/minikube-routes.yaml
         kustomization="${kustomization}\t- ./kube-deploy/minikube-routes.yaml\n"
     fi
   fi
   printf "%b" "$kustomization" > ./kustomization.yaml
   echo "Configuration is localized in ./kube-deploy"
}
function projectConfig() {
  if [[ -d "./kube-deploy" ]]; then
    echo "config directory exist";
    echo "Would you want to reset config ? (y/N)"
    read -r -s reset

    if [[ "$reset" == "y" ]]; then
       rm -rf ./kube-deploy
       startProjectConfig
    fi
  else
    startProjectConfig
  fi
}
function minikubeStart() {
  status=$(minikubeIsRunning)
  if ((status != "running")); then
    . ./minikube/start
    status=$(minikubeIsRunning)
    if ((status != "running")); then
      echo "Minikube is on error please check log bellow"
    else
      eval $(minikube docker-env)
      echo "Minikube is successfully started"
      projectConfig
    fi
  else
    echo "Minikube is already running"
    projectConfig
  fi
}

function setRegistryUrl() {
  echo "Please enter the your registry domain ex : (your.registry.com)"
  read -r -s REGISTRY_URL
  REGISTRY_EXIST=$(pingRegistry "$REGISTRY_URL")
  if [ -z "$REGISTRY_EXIST" ]; then
    echo "Registry $REGISTRY_URL doesn't exist"
    exit
  fi
  printf "\n\n#Minikube cli setup \nexport REGISTRY_URL=\"%s\"\n" "$REGISTRY_URL" >>~/.bash_profile

}

function deployKubectl() {
  kubectl kustomize kustomization.yaml > deploy.yaml
  kubectl apply -f deploy.yaml
  eval $(docker-machine env -u)
}

function publishDockerImage() {
  echo "$DOCKER_TAG"
  echo "$CI_ENVIRONMENT_NAME"
  echo "$VERSION"
  sudo docker build -t "$DOCKER_TAG:$VERSION" .
  sudo docker tag "$DOCKER_TAG:$VERSION" "$REGISTRY_URL/$DOCKER_TAG:$VERSION"
  sudo docker push "$REGISTRY_URL/$DOCKER_TAG:$VERSION"
  deployKubectl
}

function deleteDeployment() {
  eval $(minikube docker-env)
  kubectl delete deployment "$IMAGE_NAME"
  eval $(docker-machine env -u)
}

function logDeployment() {
  eval $(minikube docker-env)
  kubectl logs -f -l app="$IMAGE_NAME"
  eval $(docker-machine env -u)
}

function describeDeployment() {
  eval $(minikube docker-env)
  echo " kubectl describe pod $DOCKER_TAG"
  kubectl describe pod "$IMAGE_NAME"
  eval $(docker-machine env -u)
}

function help() {
  printf "Available command for ./minikube/cli : \n- registry (set your registry)\n- deploy (publish to registry and deploy your application on your local kubernetes)\n- delete (delete your current project deployment kubernetes)\n- log (log your current deployment)\n- describe (describe your current deployment)\n"
}
