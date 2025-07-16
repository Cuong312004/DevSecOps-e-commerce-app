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
      # Các bước đã có
      "sudo apt-get update -y",
      "sudo apt-get install -y software-properties-common apt-transport-https ca-certificates gnupg curl",
      "sudo add-apt-repository universe -y",
      "sudo apt-get update -y",
      "sudo apt-get install -y openjdk-17-jdk gnupg",

      # Cài Jenkins
      "curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null",
      "echo 'deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
      "sudo apt-get update -y",
      "sudo apt-get install -y jenkins",

      # Cài Docker
      "sudo apt update",
      "sudo apt install -y docker.io",
      "sudo systemctl enable docker",
      "sudo systemctl start docker",
      "sudo usermod -aG docker jenkins",
      "sudo systemctl restart jenkins",

      # Cài SonarQube qua Docker (port 9000)
      "sudo docker pull sonarqube:lts",
      "sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:lts",

      # Bật SonarQube khởi động cùng máy
      "sudo bash -c 'cat > /etc/systemd/system/sonarqube-docker.service <<EOF\n[Unit]\nDescription=SonarQube container\nAfter=docker.service\nRequires=docker.service\n\n[Service]\nRestart=always\nExecStart=/usr/bin/docker start -a sonarqube\nExecStop=/usr/bin/docker stop -t 2 sonarqube\n\n[Install]\nWantedBy=default.target\nEOF'",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable sonarqube-docker",
      "sudo systemctl start sonarqube-docker"
    ]

    connection {
      type        = "ssh"
      user        = var.admin_username
      private_key = file("../../../ssh_key/jenkins_ssh.pem")
      host        = azurerm_public_ip.jenkins_public_ip.ip_address
    }
  }

}
