### If for development using VSCode and Windows downlowad ZIP
https://developer.hashicorp.com/packer/install

### Open and copy packer.exe to C:\Packer and add folder to system variables PATH. Try from VSCode (restart needed) packer --version

### To iniciate packer
packer init .

### Before run check code 
packer validate -var-file="credentials.pkrvars.hcl" .

packer build -var-file="credentials.pkrvars.hcl" .