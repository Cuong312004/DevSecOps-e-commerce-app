resource "azurerm_network_interface" "jenkins_nic" {
  name                = "${var.name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "jenkins-ipconfig"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins_public_ip.id
  }
}

resource "azurerm_public_ip" "jenkins_public_ip" {
  name                = "${var.name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "jenkins_nsg" {
  name                = "jenkins-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_jenkins_web"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow-sonerqube_web"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "jenkins_nic_nsg" {
  network_interface_id      = azurerm_network_interface.jenkins_nic.id
  network_security_group_id = azurerm_network_security_group.jenkins_nsg.id
}


resource "azurerm_linux_virtual_machine" "jenkins_vm" {
  name                  = "${var.name}-vm"
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.jenkins_nic.id]
  size                  = "Standard_B2s"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  disable_password_authentication = false

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }


  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.public_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      # Cập nhật system và cài package cần thiết trong 1 lần
      "sudo apt-get update -y && sudo apt-get install -y software-properties-common apt-transport-https ca-certificates gnupg curl unzip openjdk-17-jdk docker.io",
      
      # Bật universe repo
      "sudo add-apt-repository universe -y",
      
      # Cấu hình Docker
      "sudo systemctl enable docker && sudo systemctl start docker",
      
      # Thêm Jenkins repo và cài Jenkins
      "curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null",
      "echo 'deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
      "sudo apt-get update -y && sudo apt-get install -y jenkins",
      
      # Cấu hình user jenkins cho docker
      "sudo usermod -aG docker jenkins",
      
      # Khởi động Jenkins
      "sudo systemctl enable jenkins && sudo systemctl start jenkins",
      
      # Cài đặt SonarQube song song
      "sudo useradd -r -s /bin/false sonarqube",
      
      # Tải SonarQube với tốc độ cao hơn
      "cd /opt && sudo wget -q --show-progress https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.1.69595.zip",
      "sudo unzip -q sonarqube-9.9.1.69595.zip && sudo mv sonarqube-9.9.1.69595 sonarqube",
      "sudo chown -R sonarqube:sonarqube /opt/sonarqube && sudo rm sonarqube-9.9.1.69595.zip",
      
      # Cấu hình system limits
      "echo 'vm.max_map_count=524288' | sudo tee -a /etc/sysctl.conf",
      "echo 'fs.file-max=131072' | sudo tee -a /etc/sysctl.conf",
      "sudo sysctl -p",
      
      # Cấu hình ulimit
      "echo 'sonarqube   -   nofile   131072' | sudo tee -a /etc/security/limits.conf",
      "echo 'sonarqube   -   nproc    8192' | sudo tee -a /etc/security/limits.conf",
      
      # Tạo systemd service cho SonarQube
      "cat > /tmp/sonarqube.service << 'EOF'",
      "[Unit]",
      "Description=SonarQube service",
      "After=syslog.target network.target",
      "[Service]",
      "Type=forking",
      "ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start",
      "ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop",
      "User=sonarqube",
      "Group=sonarqube",
      "Restart=always",
      "LimitNOFILE=131072",
      "LimitNPROC=8192",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      "sudo mv /tmp/sonarqube.service /etc/systemd/system/sonarqube.service",
      
      # Khởi động SonarQube
      "sudo systemctl daemon-reload && sudo systemctl enable sonarqube && sudo systemctl start sonarqube"
    ]

    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = file("../../../ssh_key/jenkins_ssh.pem")
      host        = azurerm_public_ip.jenkins_public_ip.ip_address
    }
  }
}
