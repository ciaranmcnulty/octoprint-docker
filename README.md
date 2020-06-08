This is my personal octoprint configuration, inspired by nunofgs/octoprint

I didn't like that nonofgs image runs supervisord to access the webcam, and wanted to split responsibilities into different containers

This setup integrates the following hardware
 * A Prusa mk2.5S printer
 * A Pi webcam
 * A TP-LINK HS100 smart plug

It won't be directly reusable with different hardware but the general approach can be
