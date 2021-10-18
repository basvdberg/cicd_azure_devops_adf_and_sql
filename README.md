This project contains the code to setup some resources in azure using bicep, namely:

* Azure sql server 
* Azure sql databases
* Key vault
* Azure data factory

It's used in the <a href="https://www.c2h.nl/betl-getting-started-azure/">getting started guide of betl</a>. 

I used Visual studio code to edit and run this script, but you can also run it command line and use your own preferered editor.

Steps
1. open iac.bicep
2. change the parameter values. They are currently set for demo purposes ( getting started guide). 
3. open deploy.azcli to copy/paste the commands that you can run using powershell:
4. run the following commands in powershell: 

- az login
- cd iac_betl
- az deployment group create -f ./iac.bicep -g rg-betl --verbose --mode Complete

5. go to portal.azure.com to view the results
