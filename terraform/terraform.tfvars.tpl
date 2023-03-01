gcloud_credentials = "%GCLOUD_FILE%"
gcloud_project = "%GCLOUD_PROJECT%"

vm_machine_type = "f1-micro"
vm_name = "vpn-server"
vm_tags = ["vpn"]
vm_image = "debian-cloud/debian-11"
vm_manager_user_pub_key_file = "%PUB_KEY_FILE%"
vm_manager_user_private_key_file = "%PRIVATE_KEY_FILE%"

network_public_ip_name = "vpn-public-address"

letsenrypt_email = "%LETSENCRYPT_EMAIL%"

wg_url = "%WG_URL%"
wg_client_amount = %WG_CLIENT_AMOUNT%
