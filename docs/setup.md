# Setup

Apologies I shall only cover **Mac** - One day I may include Linux and Windows.

Examples will run Kubernetes locally and on AWS. The free tier on AWS provides 750 hours per month of t2.micro.

Install [Homebrew](https://brew.sh) for easy package management on Mac:

```bash
ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
```

Install essentials:

```bash
brew update
brew install awscli
brew install jq
brew install kubernetes-cli
brew install kubectl
brew install kops
brew cask install virtualbox
brew cask install docker
brew cask install minikube
brew cask install vagrant
brew cask install vagrant-manager
brew install httpie
```