This is my personal octoprint configuration, inspired by nunofgs/octoprint

Differences to nonofgs' single-image setup:
1. I didn't like that nonofgs image runs supervisord to allow octoprint + the webcam to run, and wanted to split responsibilities into different containers
2. I wanted the config and starting plugins to be built into the image, so it's reproducible via a checkout

This setup integrates the following hardware
* A Prusa mk2.5S printer
* A Pi webcam
* A TP-LINK HS100 smart plug

It won't be directly reusable with different hardware but the general approach can be

## Adding a plugin

This repo contains several plugins, but there's no reason you can't customise them. The steps are:
1. Locate the github repo for the plugin you want, and find the URL of the ZIP in its latest release
2. Look in `setup.py` and find the `plugin_identifier`
3. Add something like this to `config/plugins.yaml`
   ```yaml
     <plugin_identifier>:
       x-plugin-url: "https://github.com/<organisation>/<repo>/archive/refs/tags/<version>.zip"
   ```
4. `make shell`, then check octoprint is running with the new plugin
5. Change any config you want via the UI
6. In the open shell `cat config.yaml` and note the extra configuration that's been added to your plugin from step 3. 
7. Copy any settings that look like they correspond with the settings you wanted to change into `plugins.yaml`
8. Repeat from step 4 until all the configuration is how you want it when the container starts
