# Minikube Setup MACOS
---------

# Prerequisite

### MacOS

``sysctl -a | grep -E --color 'machdep.cpu.features|VMX'``

Check if VMX is listed, VT-x have to be supported OS.

* Install kubectl
  https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/#install-kubectl-on-macos
* Install virtualBox
  https://download.virtualbox.org/virtualbox/6.1.26/VirtualBox-6.1.26-145957-OSX.dmg
* Install Minikube

  ```
  curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64 && chmod +x minikube
  sudo mv minikube /usr/local/bin
  minikube start --driver=virtualbox
  ```

# How to use 

Clone this following directory at the root of your project 

The name of your git directory will be the name of your pod and his hostname

* Add minikube folder to your **gitignore** file
* Set your registry  and restart your terminal
  `./minikube/cli registry`
  
* Update the **deployment.yaml** template inside the **minikube** folder (don't touch variable !!)
* Run this following command to build, publish and deploy your app `./minikube/cli deploy`

Also you have all this following command from the cli

```
Available command for ./minikube/cli : 
- registry (set your registry)
- deploy (publish to registry and deploy your application on your local kubernetes)
- delete (delete your current project deployment kubernetes)
- log (log your current deployment)
- describe (describe your current deployment)
```

### TIPS

if you want to use a short command just add type this in your term

``alias minicli=./minikube/cli``

Usage example : `minicli deploy`
