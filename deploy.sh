#!/bin/bash
# If any commands fail (exit code other than 0) entire script exits
set -e

# Check for required environment variables and make sure they are setup
: ${PROJECT_TYPE?"PROJECT_TYPE Missing"} # theme|plugin
: ${WPE_INSTALL_PROD?"WPE_INSTALL_PROD Missing"}   # subdomain for wpengine Production install
: ${WPE_INSTALL_STAGE?"WPE_INSTALL_STAGE Missing"}   # subdomain for wpengine Staging install
: ${WPE_INSTALL_DEV?"WPE_INSTALL_DEV Missing"}   # subdomain for wpengine Development install
: ${REPO_NAME?"REPO_NAME Missing"}  # repo name (Typically the folder name of the project)


# In WP Engine's multi-environment setup, we'll target each instance based on branch with variables to designate them individually.
if [[ "$CI_BRANCH" == "master" && -n "$WPE_INSTALL_PROD" ]]
then
    target_wpe_install=${WPE_INSTALL_PROD}
    repo=production
fi

if [[ "$CI_BRANCH" == "staging" && -n "$WPE_INSTALL_STAGE" ]]
then
    target_wpe_install=${WPE_INSTALL_STAGE}
    repo=production
fi

if [[ "$CI_BRANCH" == "develop" && -n "$WPE_INSTALL_DEV" ]]
then
    target_wpe_install=${WPE_INSTALL_DEV}
    repo=production
fi

echo -e  "Install: ${WPE_INSTALL_PROD} or ${WPE_INSTALL_STAGED} or ${WPE_INSTALL_DEV}"
echo -e  "Repo: ${repo}"

# Begin from the ~/clone directory
# this directory is the default your git project is checked out into by Codeship.
cd ~/clone

# Get official list of files/folders that are not meant to be on production if $EXCLUDE_LIST is not set.
if [[ -z "${EXCLUDE_LIST}" ]]; then
    wget https://raw.githubusercontent.com/dev-hero/wpe-build-deploy/master/exclude-list.txt
else
    # @todo validate proper url?
    wget ${EXCLUDE_LIST}
fi

# Loop over list of files/folders and remove them from deployment
ITEMS=`cat exclude-list.txt`
for ITEM in $ITEMS; do
    if [[ "$ITEM" == *.* ]]
    then
        find . -depth -name "$ITEM" -type f -exec rm "{}" \;
    else
        find . -depth -name "$ITEM" -type d -exec rm -rf "{}" \;
    fi
done

# Remove exclude-list file
rm exclude-list.txt

# go back home
cd ~

# Clone the WPEngine files to the deployment directory
# if we are not force pushing our changes
if [[ "$CI_MESSAGE" != *#force* ]]
then
    force=''
    git clone git@git.wpengine.com:${repo}/${target_wpe_install}.git ./deployment
else
    force='-f'
fi

# If there was a problem cloning, exit
if [ "$?" != "0" ] ; then
    echo "Unable to clone ${repo}"
    kill -SIGINT $$
fi

cd ~ # go back home

# check to see if we have a deployment folder, if so change directory to it. If not make the directory an initialize a git repo
if [ ! -d ./deployment ]; then
    mkdir ./deployment
    cd ./deployment
    git init
else
    cd ./deployment
fi

# Move the gitignore file to the deployments folder
wget --output-document=.gitignore https://raw.githubusercontent.com/dev-hero/wpe-build-deploy/master/gitignore-template.txt

# Delete plugin/theme if it exists, and move cleaned version into deployment folder
rm -rf ./wp-content/${PROJECT_TYPE}s/${REPO_NAME}

# Check to see if the wp-content directory exists, if not create it
if [ ! -d ./wp-content ];
then
    mkdir ./wp-content
fi

# Check to see if the plugins directory exists, if not create it
if [ ! -d ./wp-content/plugins ];
then
    mkdir ./wp-content/plugins
fi

# Check to see if the themes directory exists, if not create it
if [ ! -d ./wp-content/themes ];
then
    mkdir ./wp-content/themes
fi

rsync -a ../clone/* ./wp-content/${PROJECT_TYPE}s/${REPO_NAME}

# Stage, commit, and push to wpengine repo

git remote add ${repo} git@git.wpengine.com:${repo}/${target_wpe_install}.git

git config --global user.email CI_COMMITTER_EMAIL
git config --global user.name CI_COMMITTER_NAME
git config core.ignorecase false
git add --all
git commit -am "Deployment to ${target_wpe_install} $repo by $CI_COMMITTER_NAME from $CI_NAME"

git push ${force} ${repo} master
