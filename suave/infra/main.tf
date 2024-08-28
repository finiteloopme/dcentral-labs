# resource "google_compute_instance" "eth-el-reth" {
#     machine_type = "c3-standard-176"
#     name         = "eth-el-reth"
#     zone = local.gcp_zone

#     boot_disk {
#         auto_delete = true
#         device_name = "eth-el-reth-boot-disk"
#         initialize_params {
#             image = "projects/ubuntu-os-cloud/global/images/ubuntu-2404-noble-amd64-v20240809"
#             size  = 100
#             type  = "hyperdisk-balanced"
#         }
#         mode = "READ_WRITE"
#     }

#     can_ip_forward      = false
#     deletion_protection = false
#     enable_display      = false

#     labels = {
#         wl-domain = "eth"
#         wl-type = "execution-layer"
#     }

#     network_interface {
#         access_config {
#             network_tier = "PREMIUM"
#         }
#         nic_type    = "GVNIC"
#         queue_count = 0
#         stack_type  = "IPV4_ONLY"
#         subnetwork  = data.google_compute_subnetwork.suave-default-subnet.id
#     }

#     scheduling {
#         automatic_restart   = true
#         on_host_maintenance = "TERMINATE"
#         preemptible         = false
#         provisioning_model  = "STANDARD"
#     }

#     service_account {
#         email  = google_service_account.el-service-account.email
#         scopes = local.scopes
#     }

#     tags = [ "web", "ssh" ]


#     shielded_instance_config {
#         enable_integrity_monitoring = true
#         enable_secure_boot          = false
#         enable_vtpm                 = true
#     }
#     lifecycle {
#       ignore_changes = [ attached_disk ]
#     }
# }

# resource "google_compute_attached_disk" "attach-disk-chaindb" {
#   disk     = google_compute_disk.disk-chaindb.id
#   instance = google_compute_instance.eth-el-reth.id
#   mode = "READ_WRITE"
# }

# resource "google_compute_disk" "disk-chaindb" {
#   name  = "disk-chaindb"
#   type  = "hyperdisk-balanced"
#   zone  = local.gcp_zone
#   labels = {
#     environment = "dev"
#   }
#   size = 2000
#   physical_block_size_bytes = 4096
# }


# resource "google_compute_instance" "eth-cl-lighthouse" {
#     machine_type = "c3-highmem-4"
#     name         = "eth-cl-lighthouse"
#     zone = local.gcp_zone

#     boot_disk {
#         auto_delete = true
#         device_name = "eth-cl-lighthouse-boot-disk"
#         initialize_params {
#             image = "projects/ubuntu-os-cloud/global/images/ubuntu-2404-noble-amd64-v20240809"
#             size  = 100
#             type  = "hyperdisk-balanced"
#         }
#         mode = "READ_WRITE"
#     }

#     can_ip_forward      = false
#     deletion_protection = false
#     enable_display      = false

#     labels = {
#         wl-domain = "eth"
#         wl-type = "consensus-layer"
#     }

#     network_interface {
#         access_config {
#             network_tier = "PREMIUM"
#         }
#         nic_type    = "GVNIC"
#         queue_count = 0
#         stack_type  = "IPV4_ONLY"
#         subnetwork  = data.google_compute_subnetwork.suave-default-subnet.id
#     }

#     scheduling {
#         automatic_restart   = true
#         on_host_maintenance = "TERMINATE"
#         preemptible         = false
#         provisioning_model  = "STANDARD"
#     }

#     service_account {
#         email  = google_service_account.cl-service-account.email
#         scopes = local.scopes
#     }

#     tags = [ "web", "ssh" ]


#     shielded_instance_config {
#         enable_integrity_monitoring = true
#         enable_secure_boot          = true
#         enable_vtpm                 = true
#     }
#     lifecycle {
#       ignore_changes = [ attached_disk ]
#     }
# }

# resource "google_compute_attached_disk" "attach-disk-cldb" {
#   disk     = google_compute_disk.disk-cldb.id
#   instance = google_compute_instance.eth-cl-lighthouse.id
#   mode = "READ_WRITE"
# }

# resource "google_compute_disk" "disk-cldb" {
#   name  = "disk-cldb"
#   type  = "hyperdisk-balanced"
#   zone  = local.gcp_zone
#   labels = {
#     environment = "dev"
#   }
#   size = 2000
#   physical_block_size_bytes = 4096
# }



resource "google_compute_instance" "eth-rbuilder" {
    provider = google-beta
    machine_type = "c3-standard-176"
    name         = "eth-rbuilder"
    zone = local.gcp_zone

    boot_disk {
        auto_delete = true
        device_name = "eth-rbuilder-boot-disk"
        initialize_params {
            # image = "projects/ubuntu-os-cloud/global/images/ubuntu-2404-noble-amd64-v20240809"
            image = "projects/tdx-guest-images/global/images/ubuntu-2404-noble-amd64-v20240726"
            size  = 50
            type  = "hyperdisk-balanced"
        }
        mode = "READ_WRITE"
    }

    can_ip_forward      = false
    deletion_protection = false
    enable_display      = false

    labels = {
        wl-domain = "eth"
        wl-type = "rbuilder"
        wl-env = "test"
    }

    network_interface {
        access_config {
            network_tier = "PREMIUM"
        }
        nic_type    = "GVNIC"
        queue_count = 0
        stack_type  = "IPV4_ONLY"
        subnetwork  = data.google_compute_subnetwork.suave-default-subnet.id
    }

    scheduling {
        automatic_restart   = true
        on_host_maintenance = "TERMINATE"
        preemptible         = false
        provisioning_model  = "STANDARD"
    }

    service_account {
        email  = google_service_account.rbuilder-service-account.email
        scopes = local.scopes
    }

    tags = [ "web", "ssh" ]

    metadata = {
        enable-osconfig = "TRUE"
        ssh-keys = <<-EOT
            ansible-rbuilder:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBzxUXAHdLQbOn/HjXhZ04QGWHWVr+UHMTIzhvbQ/ZpCXPbLRn2mDNYuAJ11EyKtc5SyxrTp4BR/WffDGFaYzr+sGfsULWz2v1JGwlL8vNeVzky5tJ7w2F+mcVLr0BkGDyQhX5xAQ5QGsoV6E7LFu6ZqdZ0hpia6NnTbPjk2V2GnSpL6m8sj1xcJDGVFAWWOw7F5UNxqSyhWjF2fzPe90vGlxUeZAQseD1Ve4PQ9Gn9bxsMhKZtZaK0JzAvTxBLGKkToYXQg7M8Ukn2wWuVYhFMlfYQm+lfGpeDlMP7/sNDRFB43uU9Pl2LzceflivThWC0vmSs4v/5fp8iztotwCR ansible-rbuilder
            artyom:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDVDN+/E7haKmZzwb7qtIA/VaApM83rZUjno9oXIP941fB9lqgIGAdOMh7MZvtp3rL5iow7ntgGgB1gsIS7jnV4L1Ud355SAsotDhyQ8PvLXENlt1pIi5UyKkZVS4YpTVZm/RfETkbp04PBE6bR77s/0MALTJFZnTEkNfNOVvOxVAQ5IrQdu0AUA1xF8XgLOwuKTNNYuLmHrXk9bVxuTvlnOqh0QC38ihxZwlNr6ObA7Dxx4l8DQvr+9cLi/8E2M9sccqQMhvOwsXjk9ko0I08cDvINYr63+Ucs8r+4+0WT2w1fz+VRLpsxDyJYdGJqF4/49CtuojJEEsmCfJBrSaSgFNdH1o4bAPMfycjgGE5gAmkXNAhB5tPcq8un73CTMbkBD82q30JGYBuDL8G8lZcAWV4seVzXJMsBu1F0T7Bi/ZpT2ldGYMKi4raDX/AX5d16jhm3N1vcUjhnrBs2t8hXH0j7JI2ZGe0sy7mAk0QyGA16AZyrL1lCMKHaRQjsSu0sE3lep8XOdKLcMHpsVsNTI6zpKZEmanjk68V4beo6hdqIbKBDtEqYDctJE8CRcJxKoxGgiR9vJ0Ai4fAWxRvs/kMoLokiigjX0Z/K4JvviPJ4sbzp4iBGtLtJjzwmkDQhIyppSfYr2mECNOgO64IgNNNYtQC2uJM5i1xINcCbw== artyom
            EOT
    }

    confidential_instance_config {
        enable_confidential_compute = true
        confidential_instance_type = "TDX"
    }

    shielded_instance_config {
        enable_integrity_monitoring = false
        enable_secure_boot          = false
        enable_vtpm                 = false
    }

    lifecycle {
      ignore_changes = [ attached_disk ]
    }

}

resource "google_compute_attached_disk" "attach-disk-ethstore" {
  disk     = google_compute_disk.disk-ethstore.id
  instance = google_compute_instance.eth-rbuilder.id
  mode = "READ_WRITE"
}

resource "google_compute_disk" "disk-ethstore" {
    name  = "disk-ethstore"
    type  = "hyperdisk-balanced"
    zone  = local.gcp_zone
    labels = {
        environment = "test"
    }
    provisioned_iops = 120000
    provisioned_throughput = 600

    size = 6000
    physical_block_size_bytes = 4096
}

resource "google_compute_instance" "eth-vpn-1" {
    provider = google-beta
    machine_type = "c3-standard-4"
    name         = "eth-vpn-1"
    zone = local.gcp_zone

    boot_disk {
        auto_delete = true
        device_name = "eth-vpn-1-boot-disk"
        initialize_params {
            # image = "projects/ubuntu-os-cloud/global/images/ubuntu-2404-noble-amd64-v20240809"
            image = "projects/tdx-guest-images/global/images/ubuntu-2404-noble-amd64-v20240726"
            size  = 50
            type  = "hyperdisk-balanced"
        }
        mode = "READ_WRITE"
    }

    can_ip_forward      = false
    deletion_protection = false
    enable_display      = false

    labels = {
        wl-domain = "eth"
        wl-type = "vpn"
        wl-env = "test"
    }

    network_interface {
        access_config {
            network_tier = "PREMIUM"
        }
        nic_type    = "GVNIC"
        queue_count = 0
        stack_type  = "IPV4_ONLY"
        subnetwork  = data.google_compute_subnetwork.suave-default-subnet.id
    }

    scheduling {
        automatic_restart   = true
        on_host_maintenance = "TERMINATE"
        preemptible         = false
        provisioning_model  = "STANDARD"
    }

    service_account {
        email  = google_service_account.rbuilder-service-account.email
        scopes = local.scopes
    }

    tags = [ "web", "ssh" ]

    metadata = {
        enable-osconfig = "TRUE"
        ssh-keys = <<-EOT
            ansible-rbuilder:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBzxUXAHdLQbOn/HjXhZ04QGWHWVr+UHMTIzhvbQ/ZpCXPbLRn2mDNYuAJ11EyKtc5SyxrTp4BR/WffDGFaYzr+sGfsULWz2v1JGwlL8vNeVzky5tJ7w2F+mcVLr0BkGDyQhX5xAQ5QGsoV6E7LFu6ZqdZ0hpia6NnTbPjk2V2GnSpL6m8sj1xcJDGVFAWWOw7F5UNxqSyhWjF2fzPe90vGlxUeZAQseD1Ve4PQ9Gn9bxsMhKZtZaK0JzAvTxBLGKkToYXQg7M8Ukn2wWuVYhFMlfYQm+lfGpeDlMP7/sNDRFB43uU9Pl2LzceflivThWC0vmSs4v/5fp8iztotwCR ansible-rbuilder
            artyom:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDVDN+/E7haKmZzwb7qtIA/VaApM83rZUjno9oXIP941fB9lqgIGAdOMh7MZvtp3rL5iow7ntgGgB1gsIS7jnV4L1Ud355SAsotDhyQ8PvLXENlt1pIi5UyKkZVS4YpTVZm/RfETkbp04PBE6bR77s/0MALTJFZnTEkNfNOVvOxVAQ5IrQdu0AUA1xF8XgLOwuKTNNYuLmHrXk9bVxuTvlnOqh0QC38ihxZwlNr6ObA7Dxx4l8DQvr+9cLi/8E2M9sccqQMhvOwsXjk9ko0I08cDvINYr63+Ucs8r+4+0WT2w1fz+VRLpsxDyJYdGJqF4/49CtuojJEEsmCfJBrSaSgFNdH1o4bAPMfycjgGE5gAmkXNAhB5tPcq8un73CTMbkBD82q30JGYBuDL8G8lZcAWV4seVzXJMsBu1F0T7Bi/ZpT2ldGYMKi4raDX/AX5d16jhm3N1vcUjhnrBs2t8hXH0j7JI2ZGe0sy7mAk0QyGA16AZyrL1lCMKHaRQjsSu0sE3lep8XOdKLcMHpsVsNTI6zpKZEmanjk68V4beo6hdqIbKBDtEqYDctJE8CRcJxKoxGgiR9vJ0Ai4fAWxRvs/kMoLokiigjX0Z/K4JvviPJ4sbzp4iBGtLtJjzwmkDQhIyppSfYr2mECNOgO64IgNNNYtQC2uJM5i1xINcCbw== artyom
            EOT
    }

    confidential_instance_config {
        enable_confidential_compute = true
        confidential_instance_type = "TDX"
    }

    shielded_instance_config {
        enable_integrity_monitoring = false
        enable_secure_boot          = false
        enable_vtpm                 = false
    }

}

resource "google_compute_instance" "eth-vpn-2" {
    provider = google-beta
    machine_type = "c3-standard-4"
    name         = "eth-vpn-2"
    zone = local.gcp_zone

    boot_disk {
        auto_delete = true
        device_name = "eth-vpn-2-boot-disk"
        initialize_params {
            # image = "projects/ubuntu-os-cloud/global/images/ubuntu-2404-noble-amd64-v20240809"
            image = "projects/tdx-guest-images/global/images/ubuntu-2404-noble-amd64-v20240726"
            size  = 50
            type  = "hyperdisk-balanced"
        }
        mode = "READ_WRITE"
    }

    can_ip_forward      = false
    deletion_protection = false
    enable_display      = false

    labels = {
        wl-domain = "eth"
        wl-type = "vpn"
        wl-env = "test"
    }

    network_interface {
        access_config {
            network_tier = "PREMIUM"
        }
        nic_type    = "GVNIC"
        queue_count = 0
        stack_type  = "IPV4_ONLY"
        subnetwork  = data.google_compute_subnetwork.suave-default-subnet.id
    }

    scheduling {
        automatic_restart   = true
        on_host_maintenance = "TERMINATE"
        preemptible         = false
        provisioning_model  = "STANDARD"
    }

    service_account {
        email  = google_service_account.rbuilder-service-account.email
        scopes = local.scopes
    }

    tags = [ "web", "ssh" ]

    metadata = {
        enable-osconfig = "TRUE"
        ssh-keys = <<-EOT
            ansible-rbuilder:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDBzxUXAHdLQbOn/HjXhZ04QGWHWVr+UHMTIzhvbQ/ZpCXPbLRn2mDNYuAJ11EyKtc5SyxrTp4BR/WffDGFaYzr+sGfsULWz2v1JGwlL8vNeVzky5tJ7w2F+mcVLr0BkGDyQhX5xAQ5QGsoV6E7LFu6ZqdZ0hpia6NnTbPjk2V2GnSpL6m8sj1xcJDGVFAWWOw7F5UNxqSyhWjF2fzPe90vGlxUeZAQseD1Ve4PQ9Gn9bxsMhKZtZaK0JzAvTxBLGKkToYXQg7M8Ukn2wWuVYhFMlfYQm+lfGpeDlMP7/sNDRFB43uU9Pl2LzceflivThWC0vmSs4v/5fp8iztotwCR ansible-rbuilder
            artyom:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDVDN+/E7haKmZzwb7qtIA/VaApM83rZUjno9oXIP941fB9lqgIGAdOMh7MZvtp3rL5iow7ntgGgB1gsIS7jnV4L1Ud355SAsotDhyQ8PvLXENlt1pIi5UyKkZVS4YpTVZm/RfETkbp04PBE6bR77s/0MALTJFZnTEkNfNOVvOxVAQ5IrQdu0AUA1xF8XgLOwuKTNNYuLmHrXk9bVxuTvlnOqh0QC38ihxZwlNr6ObA7Dxx4l8DQvr+9cLi/8E2M9sccqQMhvOwsXjk9ko0I08cDvINYr63+Ucs8r+4+0WT2w1fz+VRLpsxDyJYdGJqF4/49CtuojJEEsmCfJBrSaSgFNdH1o4bAPMfycjgGE5gAmkXNAhB5tPcq8un73CTMbkBD82q30JGYBuDL8G8lZcAWV4seVzXJMsBu1F0T7Bi/ZpT2ldGYMKi4raDX/AX5d16jhm3N1vcUjhnrBs2t8hXH0j7JI2ZGe0sy7mAk0QyGA16AZyrL1lCMKHaRQjsSu0sE3lep8XOdKLcMHpsVsNTI6zpKZEmanjk68V4beo6hdqIbKBDtEqYDctJE8CRcJxKoxGgiR9vJ0Ai4fAWxRvs/kMoLokiigjX0Z/K4JvviPJ4sbzp4iBGtLtJjzwmkDQhIyppSfYr2mECNOgO64IgNNNYtQC2uJM5i1xINcCbw== artyom
            EOT
    }

    confidential_instance_config {
        enable_confidential_compute = true
        confidential_instance_type = "TDX"
    }

    shielded_instance_config {
        enable_integrity_monitoring = false
        enable_secure_boot          = false
        enable_vtpm                 = false
    }

}
