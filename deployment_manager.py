import yaml
import subprocess
import os
from xpander_setup.initializer.manager import XpanderInitializer


class DeploymentManager:
    def __init__(self, config_path="project_plan.yaml"):
        with open(config_path, 'r') as file:
            self.config = yaml.safe_load(file)
        self.successful_deploys = []

    def run_terraform(self, directory, action="apply"):
        target_dir = os.path.join("resource_deployments", directory)
        if not os.path.exists(target_dir):
            print(f"Error: Directory {target_dir} not found.")
            return False
        print(f"--- Running {action.upper()} on {directory} ---")
        try:
            subprocess.run(["terraform", "init"], cwd=target_dir, check=True)
            cmd = ["terraform", action, "-auto-approve"]
            subprocess.run(cmd, cwd=target_dir, check=True)
            return True
        except subprocess.CalledProcessError:
            print(f"Terraform {action} failed for {directory}")
            return False

    def deploy_all_infrastructure(self):
        resources = self.config.get('infrastructure_resources', [])
        for resource in resources:
            if not resource.get('enabled'):
                continue
            res_id = resource['resource_id']
            res_type = resource['type']
            dependency = resource.get('depends_on')
            if dependency and dependency not in self.successful_deploys:
                print(f"Skipping {res_id}: Depends on {dependency} which was not deployed.")
                continue
            success = self.run_terraform(res_id, action="apply")
            if success:
                self.successful_deploys.append(res_id)
                if res_type == "aks":
                    self._setup_kubeconfig(res_id)

    def _setup_kubeconfig(self, dir_name):
        kubeconfig_path = os.path.abspath(os.path.join("resource_deployments", dir_name, "kubeconfig"))
        if os.path.exists(kubeconfig_path):
            os.environ["KUBECONFIG"] = kubeconfig_path
            print(f"KUBECONFIG exported: {kubeconfig_path}")

    def run_setup(self):
        """
        Method to trigger the application layer setup
        """
        app_config = self.config.get('xpander_config', {})
        if not app_config.get('enabled'):
            print("Xpander setup is disabled in project plan.")
            return
        dependency = app_config.get('depends_on')
        # Only run if infrastructure dependency (like AKS) is in successful_deploys
        if not dependency or dependency in self.successful_deploys:
            print("\n--- Starting Application Setup Phase ---")
            initializer = XpanderInitializer(app_config)
            initializer.deploy_application()
        else:
            print(f"\nAborting App Setup: Prerequisite {dependency} failed or was skipped.")


if __name__ == "__main__":
    manager = DeploymentManager()
    manager.deploy_all_infrastructure()
    manager.run_setup()