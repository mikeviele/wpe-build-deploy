# Continuous Deployment via WP engine and Codeship

This shell script is intended to leverage WP engines Git push functionality in conjunction with Codeships deployment architecture to facilitate build and deployment of theme and/or plugin code to any of your three WordPress environments.

This code assumes you know how to use git and also how to push commits to a repository and manage PR's and merges.

This repository was originally forked from (https://github.com/linchpin/wpengine-codeship-continuous-deployment), but that fork was detached to avoid disruption in the even the original repo was removed from Github and due to the fact that we have made several major changes to the build and deploy scripting since our original fork. We like to give credit where credit is due and we worked with Linchpin (https://linchpin.com) on modifications to the original repo back in March of 2019 before porting it over for our own use.

# Current Build / Deploy Release as of 2022

The latest version of this script will not only deploy your code, the latest version will also *build* your code as long as the script finds a `gulpfile`, `gruntfile`, `yarn` etc. 

In order to build your project simply create a task in your task runner named `build:production`.

*WP Engines legacy snapshot environment has been removed from this repo pending their announcement of end-of-life for snapshot instances starting in March of 2022. Support is intended for current multi-environment sites (Production, Staging, and Development)*

### The instructions and the deployment script assumes the following

* You are using Codeship as your CI/CD solution so these instructions are specific to that CI/CD service.
* You understand how to setup [.git deployments on WP Engine](https://wpengine.com/git/) already.
* You are using the **master** branch of your repo for your **Production** instance
* You are using the **staging** branch of your repo for your **Staging** instance
* You are using the **develop** branch of your repo for your **Development** instance

### How do I get set up?

* [Repo Configuration Setup](https://github.com/dev-hero/wpe-build-deploy#repo-configuration-setup)
* [Codeship Configuration](https://github.com/dev-hero/wpe-build-deploy#codeship-configuration)
* [Environment Variables](https://github.com/dev-hero/wpe-build-deploy#environment-variables)
* [Deployment Instructions](https://github.com/dev-hero/wpe-build-deploy#deployment-instructions)
* [Useful notes](https://github.com/dev-hero/wpe-build-deploy#useful-notes)
* What this repo needs

### Repo Configuration Setup

When creating your repo, it's important to name the repo using proper folder structure. We typically replace any spaces " " with dashes "-".**Example:** If your plugin is named "My Amazing Plugin" you can name the repo "my-amazing-plugin". When the script runs it will use the `REPO_NAME` environment variable as the folder for your plugin or theme. So you may find it useful to match.

**Important Note:** All assets/files within your repo should be within the root folder. **DO NOT** include `wp-content`, `wp-content\plugins` etc. The deploy script will create all the appropriate folders as needed.

### Configuration

1. Log into **codeship.com**.
2. Connect your **bitbucket**, **github** or **gitlab** repo to Codeship. (You will need to authorize access to your repo)
3. Setup [Environment Variables](https://github.com/linchpin/wpe-build-deploy#environment-variables)
    * Environment variables are a great way to add flexibility to the script without having variables hard coded within this script.
    * You should never have any credentials stored within this or any other repo.
4. Create deployment pipeline for each branch you are going to add automated deployments to (Use **master**, **staging**, and **"develop"**). The pipelines you create are going to utilize the **deployment script below**
5. Do a test push to the repo. The first time you do this within Codeship it may be beneficial to watch all the steps that are displayed within their console.

### Environment Variables

All of the environment variables below are required

|Variable|Description|Required|
| ------------- | ------------- | ------------- |
|**REPO_NAME**|This variable should match the theme / plugin folder name|:heavy_exclamation_mark:|
|**PROJECT_TYPE**|(**"theme"** or **"plugin"**) This determines what base (WordPress core) folder your repo should be deployed to|:heavy_exclamation_mark:|


The variables below are also required and are utilized to work with WP Engine's current multi-environment setup. WP Engine utilizes three (3) individual installs under one "site". TheY are all essentially part of your same hosting environment, but are treated as Production, Staging, and Development environments when it comes to your workflow.

|Variable|Description|Required|
| ------------- | ------------- | ------------- |
|**WPE_INSTALL_PROD**|The environment name from WP Engine install "Production"||
|**WPE_INSTALL_STAGE**|The environment name from WP Engine install "Staging"||
|**WPE_INSTALL_DEV**|The environment name from WP Engine install "Development"||


This variable is optional to source a custom excludes list file.

|Variable|Description|Required|
| ------------- | ------------- | ------------- |
|**EXCLUDE_LIST**|Custom list of files/directories that will be used to exclude files from deploymnet. This shell script provides a default. This Environment variable is only needed if you are customizing for your own usage. This variable should be a FULL URL to a file. See exclude-list.txt for an example| Optional

### Commit Message Hash Tags
You can customize the actions taken by the deployment script by utilizing the following hashtags within your commit message

|Commit #hashtag|Description|
| ------------- | ------------- |
|**#force**|Some times you need to disregard what WP Engine has within their remote repo(s) and start fresh. [Read more](https://wpengine.com/support/resetting-your-git-push-to-deploy-repository/) about it on WP Engine.|

## Deployment Instructions

The below build script(s) will check out the devhero build scripts from github and then run the shell script accordingly based on the environment variables.

In order to deploy to your pipeline you can use the following command regardless of master, develop or a custom branch. We are utilizing `https` instead of `SSH` so we can `git clone` the deployment script without requiring authentication.

```
# load our build script from the dev hero repo
git clone --branch "master" --depth 50 https://github.com/dev-hero/wpe-build-deploy.git
chmod 555 ./wpe-build-deploy/build.sh
chmod 555 ./wpe-build-deploy/deploy.sh
chmod 555 ./wpe-build-deploy/build-deploy.sh
./wpe-build-deploy/build-deploy.sh
```

## Useful Notes

* WP Engine's .git push is more of a "middle man" between your repo and what is actually displayed to your visitors within the root web directory of your website. After the files are .git pushed to your production, staging, or develop remote branches they are then synced to the appropriate environment's web root. It's important to know this because there are scenarios where you may need to use the **#force** hashtag within your commit message in order to override what WP Engine is storing within it's repo and what is shown when logged into SFTP. You can read more about it on [WP Engine](https://wpengine.com/support/resetting-your-git-push-to-deploy-repository/)

* If an SFTP user in WP Engine has uploaded any files to staging or production those assets **WILL NOT** be added to the repo.
* Additionally there are times where files need to deleted that are not associated with the repo. In these scenarios we suggest deleting the files using SFTP and then utilizing the **#force** hash tag within the next deployment you make.
