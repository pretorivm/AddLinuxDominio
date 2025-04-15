#---------------------------------------------------------------------------------------
# Colocar Linux no dominio
#---------------------------------------------------------------------------------------
# Desenvolvido e personalizado por Raimundo Junior
#
# sudo git  clone https://github.com/pretorivm/AddLinuxDominio.git
# sudo chmod +x AddLinuxDominio.sh
# sudo ./AddLinuxDominio.sh
#---------------------------------------------------------------------------------------

#!/bin/bash

# Defina as variáveis com seus valores específicos
DOMINIO="AADDSCONTOSO.COM"
NOME_HOST="ubuntu"
NOME_DNS="$NOME_HOST.$DOMINIO"
USUARIO_DOMINIO="contosoadmin@$DOMINIO"
SERVIDOR_NTP="aaddscontoso.com"

# Atualize o sistema e instale os pacotes necessários
sudo apt-get update && sudo apt-get install -y \
  krb5-user samba sssd sssd-tools libnss-sss libpam-sss ntp ntpdate realmd adcli

# Configure o arquivo /etc/hosts
echo "127.0.0.1 $NOME_DNS $NOME_HOST" | sudo tee -a /etc/hosts

# Configure o arquivo /etc/ntp.conf
echo "server $SERVIDOR_NTP" | sudo tee -a /etc/ntp.conf

# Reinicie o serviço NTP
sudo systemctl restart ntp

# Descubra o domínio
sudo realm discover $DOMINIO

# Inicialize o Kerberos
echo "Digite a senha do usuário $USUARIO_DOMINIO:"
sudo kinit -V $USUARIO_DOMINIO

# Una a máquina ao domínio
sudo realm join --verbose $DOMINIO -U "$USUARIO_DOMINIO" --install=/

# Atualize a configuração do SSSD
sudo sed -i 's/^use_fully_qualified_names = True/#use_fully_qualified_names = True/' /etc/sssd/sssd.conf
sudo systemctl restart sssd

# Configure o SSH para permitir autenticação por senha
sudo sed -i 's/^#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Configure a criação automática do diretório home para usuários de domínio
echo "session required pam_mkhomedir.so skel=/etc/skel umask=0077" | sudo tee -a /etc/pam.d/common-session

# Conceda privilégios sudo ao grupo 'AAD DC Administrators'
echo "%AAD\\ DC\\ Administrators ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers

echo "Máquina unida ao domínio com sucesso!"
