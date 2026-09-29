# Terraform Tutorial with Docker

`Terraform` is an open-source tool developed by HashiCorp that allows you to define, provision, and manage cloud and on-premise infrastructure safely using a declarative configuration language called `HCL` (HashiCorp Configuration Language)

This tutorial uses `Terraform` to build infrastructure with `Docker`.

Prerequisite:

- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

---

## The Basic

### 1. Terraform Installation

Make sure you have the [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/docker-get-started/install-cli) installed on your system.

### 2. Create Terraform Configuration

Create a Terraform project directory.

```bash
mkdir terraform-docker
cd terraform-docker
```

Create a Terraform configuration file named `main.tf` with the following configuration

```terraform
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  # For Windows & macOS, the provider automatically locates the local Docker Desktop daemon.
  # If you hit connection issues on Linux/macOS, uncomment the line below:
  # host = "unix:///var/run/docker.sock"
  # host = "npipe:////.//pipe//docker_engine"
}

# Pulls the image
resource "docker_image" "web" {
  name         = "nginx:alpine"
  keep_locally = true
}

# Creates the container
resource "docker_container" "web" {
  image = docker_image.web.image_id
  name  = "tutorial-nginx-container"

  ports {
    internal = 80
    external = 8081
  }
}
```

### 3. Initialize and Apply

Initialze the working directory. This downloads the nessary `Docker` plugin provider.

```bash
terraform init
```

The `Docker` plugin provider will be placed in the `.terraform\providers\...\3.0.2`

Run the apply command to deploy a container, review the actions `Terraform` intends to take. Type `yes` to confirm.

```bash
terraform apply
```

### 4. Verify the Deployment

Open your browser and navigate to [http://localhost:8081](http://localhost:8081) to see the `Nginx` welcome page.

Open your Docker Desktop Dashboard. You will find `tutorial-nginx-container` running.

Check the `terraform.tfstate` file. This file is the single source of truth for infrastructure managed by Terraform. It is a `JSON` file created automatically upon running your successful deployment.

- Resource Mapping: binds the logical resource blocks defined in your `.tf` files ot actual physical resource IDs
- Metadata Tracking: tracks resource depndencies, creation order, and configurations that are not visible in the base code.
- Performance cache

We can also use the `terraform show` command to display the same information.

### 5. Cleaning Up

To tear down the infrastructure and remove the container, run:

```bash
terraform destroy
```

---

## Using Variables

Instead of hardcoded values in the `main.tf`, you can use **Terraform input variables** defined in a separate file (traditionally named `variables.tf` or `terraform.tfvars`)

### 6. Create the Variable Definition File

Create a file named `variables.tf` in the same directory. In this file, we declared three variables along with their **default** values.

```terraform
variable "image_name" {
  type        = string
  description = "The Docker image name and tag to pull"
  default     = "nginx:alpine"
}

variable "container_name" {
  type        = string
  description = "The custom name for the local container"
  default     = "we-server"
}

variable "external_port" {
  type        = number
  description = "The local host port to map to the container"
  default     = 8088
}
```

### 7. Reference Variables in `main.tf`

Update your `main.tf` file to reference to those variables using the `var.<VARIABLE_NAME>` syntax.

```terraform
terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.2"
    }
  }
}

provider "docker" {
  # For Windows & macOS, the provider automatically locates the local Docker Desktop daemon.
  # If you hit connection issues on Linux/macOS, uncomment the line below:
  # host = "unix:///var/run/docker.sock"
  # host = "npipe:////.//pipe//docker_engine"
}

# Pulls the image
resource "docker_image" "web" {
  name         = var.image_name
  keep_locally = true
}

# Creates the container
resource "docker_container" "web" {
  image = docker_image.web.image_id
  name  = var.container_name

  ports {
    internal = 80
    external = var.external_port
  }
}
```

### 8. Supply the Custom Values

To assign custom values to these variables, create a file named `terraform.tfvars`. Terraform automatically loads any file ending exactly with this name.

```terraform
image_name     = "nginx:alpine"
container_name = "dome-nginx-server"
external_port  = 9000
```

### 9. Run the Configuration

Because Terraform automatically links these files together, your execution routing remains exactly the same:

```bash
terraform plan
terraform apply
```

---

## Passing Sensitive Secrets

To pass sensitive secrets like `API keys` or `database passwords` into your Docker containers without hardcoding them, you should use **sensitive input variables** paired with environment variables or external shell variables.

This prevents your secrets from being accidentally printed to the console log stream during execution.

### 10. Declare a Sensitive Variable

Open your `variables.tf` file and define your secret variable. Adding `sensitive = true` instructs Terraform to obscure the value in your terminal outputs.

```terraform
variable "api_key" {
  type        = string
  description = "The secret API key for the application"
  sensitive   = true  # Blocks terminal logging
}
```

### 11. Inject the Secret into the Container

Update `main.tf` file. Use the `env` argument inside the `docker_container` resource to inject the variable as an environment variable inside the container.

```terraform
resource "docker_container" "app" {
  image = docker_image.nginx.image_id
  name  = var.container_name

  # Pass environment variables as a list of "KEY=VALUE" strings
  env = [
    "APP_ENV=production",
    "API_SECRET_KEY=${var.api_key}"
  ]

  ports {
    internal = 80
    external = var.external_port
  }
}

```

### 12. Supply the Secret Safely

Do not commit secrets to your regular `terraform.tfvars` file if you track it in Git. Instead, choose one of these two safe injection methods:

#### Use an Environment Variable (Recommended)

Terraform automatically reads system environment variables prefixed with `TF_VAR_`. This is the safest approach for local machines and CI/CD pipelines.

Set it in your terminal before running your configuration:

```bash
# On Linux/macOS
export TF_VAR_api_key="super-secret-token-123"

# On Windows (PowerShell)
$env:TF_VAR_api_key="super-secret-token-123"
```

#### Use a Private Secret File

Create a dedicated file named `secret.tfvars` and add it to your `.gitignore` file so it is never pushed to a repository:

```terraform
api_key = "super-secret-token-123"
```

When running your plan or apply, manually pass this file flag:

```bash
terraform apply -var-file="secret.tfvars"
```
