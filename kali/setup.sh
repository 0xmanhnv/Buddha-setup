#!/usr/bin/env bash


BANNER="ICAgICAgICAgICAgICAgICAgICAgICAgICAgXwogICAgICAgICAgICAgICAgICAgICAgICBfb29Pb29fCiAgICAgICAgICAgICAgICAgICAgICAgbzg4ODg4ODhvCiAgICAgICAgICAgICAgICAgICAgICAgODgiIC4gIjg4CiAgICAgICAgICAgICAgICAgICAgICAgKHwgLV8tIHwpCiAgICAgICAgICAg"
BANNER+="ICAgICAgICAgICAgT1wgID0gIC9PCiAgICAgICAgICAgICAgICAgICAgX19fXy9gLS0tJ1xfX19fCiAgICAgICAgICAgICAgICAgIC4nICBcXHwgICAgIHwvLyAgYC4KICAgICAgICAgICAgICAgICAvICBcXHx8fCAgOiAgfHx8Ly8gIFwKICAgICAgICAgICAgICAgIC8gIF98fHx8fCAtOi0gfHx8fHxf"
BANNER+="ICBcCiAgICAgICAgICAgICAgICB8ICAgfCBcXFwgIC0gIC8nfCB8ICAgfAogICAgICAgICAgICAgICAgfCBcX3wgIGBcYC0tLScvLyAgfF8vIHwKICAgICAgICAgICAgICAgIFwgIC4tXF9fIGAtLiAtJ19fLy0uICAvCiAgICAgICAgICAgICAgX19fYC4gLicgIC8tLS4tLVwgIGAuIC4nX19fCiAgICAg"
BANNER+="ICAgICAgLiIiICc8ICBgLl9fX1xfPHw+Xy9fX18uJyBfPiBcIiIuCiAgICAgICAgICB8IHwgOiAgYC0gXGAuIDtgLiBfLzsgLicvIC8gIC4nIDsgfAogICAgICAgICAgXCAgXCBgLS4gICBcX1xfYC4gXy4nXy9fLyAgLScgXy4nIC8KPT09PT09PT09PT1gLS5gX19fYC0uX19cIFxfX18gIC9fXy4tJ18u"
BANNER+="J18uLSc9PT09PT09PT09PT09PT09CiAgICAgICAgICAgICAgICAgICAgICAgIGA9LS09LScgICAgICAgICAgICAgICAgICAgIEJ1ZGRoYSAgIAo="

# TERM COLORS
bred='\033[1;31m'
bblue='\033[1;34m'
bgreen='\033[1;32m'
byellow='\033[1;33m'
red='\033[0;31m'
blue='\033[0;34m'
green='\033[0;32m'
yellow='\033[0;33m'
reset='\033[0m'

# Variables
profile_shell=.profile
tools_folder="$HOME/Tools"


function banner() {
	printf "$yellow"
	echo $BANNER | base64 -d
	printf "${reset}\n"
}

function test_connectivity() {
	if nc -zw1 google.com 443 2>/dev/null; then
		echo -e "Connection: ${bgreen}OK${reset}"
	else
		echo -e "${bred}[!] Please check your internet connection and then try again...${reset}"
		exit 1
	fi
}

# Declaring Go tools and their installation commands
declare -A gotools
gotools["gf"]="go install -v github.com/tomnomnom/gf@latest"
gotools["amass"]="go install -v github.com/owasp-amass/amass/v3/...@master"
gotools["nuclei"]="go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
gotools["anew"]="go install -v github.com/tomnomnom/anew@latest"
gotools["subfinder"]="go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
gotools["gau"]="go install -v github.com/lc/gau/v2/cmd/gau@latest"
gotools["gobuster"]="go install github.com/OJ/gobuster/v3@latest"

# Declaring repositories and their paths
declare -A repos
repos["Gf-Patterns"]="1ndianl33t/Gf-Patterns"

###############################################################################################################
############################################## SETUP TOOLS ####################################################
###############################################################################################################

install_apt() {
	eval $SUDO apt update -y $DEBUG_STD
	eval $SUDO DEBIAN_FRONTEND="noninteractive" apt-get install -y build-essential mingw-w64 binutils-mingw-w64 g++-mingw-w64
	eval $SUDO DEBIAN_FRONTEND="noninteractive" apt-get install -y openjdk-11-jdk openjdk-11-jre
	# eval $SUDO DEBIAN_FRONTEND="noninteractive" apt install chromium-browser -y $DEBUG_STD
	eval $SUDO DEBIAN_FRONTEND="noninteractive" apt install chromium -y $DEBUG_STD
	eval $SUDO DEBIAN_FRONTEND="noninteractive" apt install python3 python3-pip python3-virtualenv build-essential gcc cmake ruby whois git curl libpcap-dev wget zip python3-dev pv dnsutils libssl-dev libffi-dev libxml2-dev libxslt1-dev zlib1g-dev nmap jq apt-transport-https lynx medusa xvfb libxml2-utils procps bsdmainutils libdata-hexdump-perl -y $DEBUG_STD
	curl https://sh.rustup.rs -sSf | sh -s -- -y >/dev/null 2>&1
	eval source "${HOME}/.cargo/env $DEBUG_STD"
	eval cargo install ripgen $DEBUG_STD
	eval source "${HOME}/.cargo/env $DEBUG_STD"
}

function install_vscode() {
	printf "${bblue} Running: Installing VSCODE ${reset}\n\n"
	if command -v code > /dev/null 2>&1; then
	    printf "${yellow} VSCODE installed ! ${reset}\n"
	else
		# https://vscode.download.prss.microsoft.com/dbazure/download/stable/8b3775030ed1a69b13e4f4c628c612102e30a681/code_1.85.2-1705561292_amd64.deb
		eval wget "https://vscode.download.prss.microsoft.com/dbazure/download/stable/8b3775030ed1a69b13e4f4c628c612102e30a681/code_1.85.2-1705561292_amd64.deb" -O /tmp/vscode.deb $DEBUG_STD
		eval $SUDO dpkg -i /tmp/vscode.deb
	fi
}

function install_sliver() {
	# Install Sliver C2

	if command -v sliver > /dev/null 2>&1; then
		printf "${yellow} Sliver installed ! ${reset}\n"
	else
		printf "${bblue} Running: Installing Sliver tools ${reset}\n\n"
		eval $SUDO curl https://sliver.sh/install | sudo bash
	fi
}


function install_tools() {
###############################################################################################################
	printf "${bblue} Running: Installing Golang tools (${#gotools[@]})${reset}\n\n"
	go env -w GO111MODULE=auto
	go_step=0
	for gotool in "${!gotools[@]}"; do
		go_step=$((go_step + 1))
		if [[ $upgrade_tools == "false" ]]; then
			res=$(command -v "$gotool") && {
				echo -e "[${yellow}SKIPPING${reset}] $gotool already installed in...${blue}${res}${reset}"
				continue
			}
		fi
		eval ${gotools[$gotool]} $DEBUG_STD
		exit_status=$?
		if [[ $exit_status -eq 0 ]]; then
			printf "${yellow} $gotool installed (${go_step}/${#gotools[@]})${reset}\n"
		else
			printf "${red} Unable to install $gotool, try manually (${go_step}/${#gotools[@]})${reset}\n"
			double_check=true
		fi
	done
###############################################################################################################
	printf "${bblue} Running: Installing neo4j neo4j_4.4.29_all.deb tools (${#gotools[@]})${reset}\n\n"
	if [ -f "/usr/bin/neo4j" ]; then
		printf "${yellow} Neo4j installed ! ${reset}\n"
	else
		eval wget -O- https://debian.neo4j.com/neotechnology.gpg.key | gpg --dearmor > neo4j.gpg
		eval $SUDO mv neo4j.gpg /etc/apt/trusted.gpg.d/
		eval $SUDO chown root:root /etc/apt/trusted.gpg.d/neo4j.gpg
		eval $SUDO chmod ugo+r /etc/apt/trusted.gpg.d/neo4j.gpg
		eval $SUDO chmod go-w /etc/apt/trusted.gpg.d/neo4j.gpg
		echo 'deb https://debian.neo4j.com stable 4.4' | sudo tee /etc/apt/sources.list.d/neo4j.list
		eval $SUDO apt update -y $DEBUG_STD
		eval $SUDO apt-get install neo4j
	fi
###############################################################################################################
	printf "${bblue} Running: Installing BloodHound neo4j_4.4.29_all.deb tools (${#gotools[@]})${reset}\n\n"
	if [ -d "$tools_folder/BloodHound" ]; then
		printf "${yellow} BloodHound installed ! ${reset}\n"
	else
		eval $SUDO rm -rf "$tools_folder/BloodHound"
		eval wget -N -c https://github.com/BloodHoundAD/BloodHound/releases/download/v4.3.1/BloodHound-linux-x64.zip -O /tmp/BloodHound-linux-x64.zip
		eval unzip /tmp/BloodHound-linux-x64.zip -d /tmp
		eval $SUDO mv /tmp/BloodHound-linux-x64 "$tools_folder/BloodHound"
		eval rm -f /tmp/BloodHound-linux-x64.zip $DEBUG_STD
	fi

	
}

###############################################################################################################
############################################## MAIN ###########################################################
###############################################################################################################

banner

if [ -d "$tools_folder" ]; then
	printf "\n${bgreen} Tools folder is exists ${reset}\n\n"
else
	printf "\n${bgreen} Create Tools Folder ${reset}\n\n"
	mkdir -p $tools_folder
fi

printf "\n${bgreen} Buddha installer/updater script ${reset}\n\n"
printf "${yellow} This may take time. So, go grab a coffee! ${reset}\n\n"

if [[ $(id -u | grep -o '^0$') == "0" ]]; then
	SUDO=""
else
	if sudo -n false 2>/dev/null; then
		printf "${bred} Is strongly recommended to add your user to sudoers${reset}\n"
		printf "${bred} This will avoid prompts for sudo password in the middle of the installation${reset}\n"
		printf "${bred} And more important, in the middle of the scan (needed for nmap SYN scan)${reset}\n\n"
		printf "${bred} echo \"${USERNAME}  ALL=(ALL:ALL) NOPASSWD: ALL\" > /etc/sudoers.d/reconFTW${reset}\n\n"
	fi
	SUDO="sudo"
fi

printf "${bblue} Running: Installing system packages ${reset}\n\n"
if [[ -f /etc/debian_version ]]; then
    install_apt
fi

############################################## SETUP GOLANG ####################################################
# Installing latest Golang version
version=$(curl -L -s https://golang.org/VERSION?m=text | head -1)
[[ $version == g* ]] || version="go1.21.6"

printf "${bblue} Running: Installing/Updating Golang ${reset}\n\n"

if [[ $(eval type go $DEBUG_ERROR | grep -o 'go is') == "go is" ]] && [[ $version == $(go version | cut -d " " -f3) ]]; then
	printf "${bgreen} Golang is already installed and updated ${reset}\n\n"
else
	eval $SUDO rm -rf /usr/local/go $DEBUG_STD
	# https://go.dev/dl/go1.21.6.linux-amd64.tar.gz
	# eval wget "https://dl.google.com/go/${version}.linux-amd64.tar.gz" -O /tmp/${version}.linux-amd64.tar.gz $DEBUG_STD
	eval wget "https://go.dev/dl/${version}.linux-amd64.tar.gz" -O /tmp/${version}.linux-amd64.tar.gz $DEBUG_STD
	eval $SUDO tar -C /usr/local -xzf /tmp/"${version}.linux-amd64.tar.gz" $DEBUG_STD

	eval $SUDO ln -sf /usr/local/go/bin/go /usr/local/bin/
	#rm -rf $version*
	# export GOROOT=/usr/local/go
	# export GOPATH=${HOME}/go
	# export PATH=$GOPATH/bin:$GOROOT/bin:${HOME}/.local/bin:$PATH
fi

# Export golang vars
if [[ $(cat ~/"${profile_shell}" | grep -o 'export GOROOT') == "export GOROOT" ]] || [[ $(cat ~/"${profile_shell}" | grep -o 'export GOPATH') == "export GOPATH" ]] || [[ $(cat ~/"${profile_shell}" | grep -o 'export PATH.*GOROOT') == 'export PATH=$GOPATH/bin:$GOROOT' ]]; then
	printf "${yellow} Golang vars ! ${reset}\n"
else
printf "${bblue} Running: Golang vars ${reset}\n\n"
cat <<EOF >>~/"${profile_shell}"
# Golang vars
export GOROOT=/usr/local/go
export GOPATH=\$HOME/go
export PATH=\$GOPATH/bin:\$GOROOT/bin:\$HOME/go/bin:\$HOME/.local/bin:\$PATH
EOF
fi
source "$HOME/$profile_shell"

printf "${bblue} Running: Installing requirements ${reset}\n\n"
mkdir -p ~/.gf
mkdir -p ~/.config/notify/
mkdir -p ~/.config/amass/
mkdir -p ~/.config/nuclei/

if command -v pip3 > /dev/null 2>&1; then
	printf "${yellow} Pip3 installed ! ${reset}\n"
else
	eval wget -N -c https://bootstrap.pypa.io/get-pip.py $DEBUG_STD && eval python3 get-pip.py $DEBUG_STD
	eval rm -f get-pip.py $DEBUG_STD
fi

# Installing tools
install_tools
install_vscode
install_sliver


printf "${bgreen} Finished!${reset}\n\n"
printf "\n\n${bgreen}#######################################################################${reset}\n"