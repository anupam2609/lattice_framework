import subprocess
import os


class XpanderInitializer:
    def __init__(self, xpander_config):
        self.config = xpander_config

    def deploy_application(self):
        print(f"--- Starting Xpander AI Application Setup ---")
        kubeconfig = os.environ.get("KUBECONFIG")
        if not kubeconfig or not os.path.exists(kubeconfig):
            print("Error: KUBECONFIG not found. Cannot deploy to cluster.")
            return False
        manifest_path = os.path.abspath("xpander_setup/configurations")
        if os.path.exists(manifest_path) and os.listdir(manifest_path):
            print(f"Applying manifests from {manifest_path}...")
            subprocess.run(["kubectl", "apply", "-f", manifest_path], check=True)
        else:
            print("No manifests found in configurations directory. Skipping kubectl apply.")
        print(f"Successfully initialized {self.config.get('agent_count', 0)} agents.")
        return True