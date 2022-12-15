terraform {
  cloud {
    organization = "terraform-ansiblePr"

    workspaces {
      name = "tfansible"
    }
  }
}